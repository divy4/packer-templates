#!/usr/bin/env bash

# Following https://wiki.archlinux.org/index.php/Installation_guide

set -e

# base - Base packages
# efibootmgr - EFI mode support
# grub - Bootloader
# haveged - Random number generator, needed to generate session keys for ssh to start properly (see https://bbs.archlinux.org/viewtopic.php?id=241346)
# linux - You know, probably want this one
# linux-firmware - Firmware is pretty nice too
# openssh - ssh server, needed to continue provisioning tools after initial run
# pulseaudio - Audio middleware that sits between applications and ALSA
# pulseaudio-alsa - ALSA plugin for pulseaudio
packages=(\
  base \
  efibootmgr \
  grub \
  haveged \
  linux \
  linux-firmware \
  openssh \
  pulseaudio \
  pulseaudio-alsa \
)

# Bootdrive-level operations

function main {
  enable_ntp
  partition_disks
  format_partitions
  mount_filesystems
  create_swapfile
  select_pacman_mirrors
  install_packages
  generate_fstab
  configure_dns
  exec_chroot
  exit_install_and_shutdown
}

function enable_ntp {
  echo_title 'Enable NTP'
  timedatectl set-ntp true
  timedatectl status
}

function partition_disks {
  echo_title 'Partition disks'
  emulate_human_input << EOF | fdisk /dev/sda
  g            # create GPT partition table
  n            # new partition (efi)
  1            # partition 1
               # start at beginning of disk (default)
  +512M        # 512MB size
  t            # change parition type
  1            # type=EFI System
  n            # new partition (boot)
  2            # partition 2
               # start after previous (default)
  +128M        # 128MB size
  n            # new partition (root)
  3            # partition 3
               # start after previous (default)
               # fill remaining space (default)
  w            # write to disk and exit
EOF
  fdisk -l | grep dev
}

function format_partitions {
  echo_title 'Format partitions'
  mkfs.fat -F32 /dev/sda1
  mkfs.ext4 /dev/sda2
  mkfs.ext4 /dev/sda3
}

function mount_filesystems {
  echo_title 'Mount the file systems'
  mount /dev/sda3 /mnt
  mkdir /mnt/efi
  mount /dev/sda1 /mnt/efi
  mkdir /mnt/boot
  mount /dev/sda2 /mnt/boot
  findmnt | grep sda
}

function create_swapfile {
  echo_title 'Create swapfile'
  dd if=/dev/zero of=/mnt/swapfile bs=1M count="$MEMORY" status=progress
  chmod 600 /mnt/swapfile
  mkswap /mnt/swapfile
  swapon /mnt/swapfile
}

function select_pacman_mirrors {
  echo_title 'Select pacman mirrors'
  cp /etc/pacman.d/mirrorlist /tmp/mirrorlist
  chmod a+x /usr/bin/rankmirrors
  rankmirrors --max-time 1 /tmp/mirrorlist > /etc/pacman.d/mirrorlist
  rm /tmp/mirrorlist
  cat /etc/pacman.d/mirrorlist
}

function install_packages {
  echo_title 'Install packages'
  pacstrap /mnt "${packages[@]}"
}

function generate_fstab {
  echo_title 'Generate fstab'
  genfstab -U /mnt >> /mnt/etc/fstab
  cat /mnt/etc/fstab
}

function configure_dns {
  echo_title 'Enabling systemd-resolved DNS'
  ln --force --symbolic /run/systemd/resolve/stub-resolv.conf /mnt/etc/resolv.conf
}

function exec_chroot {
  echo_title 'Entering chroot'
  export -f chroot_command
  export -f configure_boot_loader
  export -f echo_title
  export -f emulate_human_input
  export -f enable_networking
  export -f enable_ssh
  export -f replace
  export -f set_hostname
  export -f set_localization
  export -f set_root_password
  export -f set_time_zone
  export HOSTNAME
  export NETWORK_INTERFACE
  export ROOT_PASSWORD
  arch-chroot /mnt /bin/bash -c "chroot_command"
  echo_title 'Exiting chroot'
}

function exit_install_and_shutdown {
  echo_title 'Disable swap and unmount partitions'
  swapoff --all
  umount -R /mnt

  echo_title 'Done! Rebooting...'
  nohup bash -c 'sleep 2 && shutdown now' &
}

# Chroot-level operations

function chroot_command {
  set -e
  set_time_zone
  set_localization
  set_hostname
  set_root_password
  configure_boot_loader
  enable_networking
  enable_ssh
}

function set_time_zone {
  echo_title 'Time Zone'
  cat << EOF > /etc/systemd/system/time-zone-sync.service
[Unit]
Description=Time Zone Sync
Wants=network-online.target
After=network-online.target
StartLimitIntervalSec=0

[Service]
Type=oneshot
ExecStart=bash -c 'timedatectl set-timezone "$(curl --fail https://ipapi.co/timezone)"'
RemainAfterExit=yes
Restart=on-failure
RestartSec=60

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl start time-zone-sync.service
  systemctl enable time-zone-sync.service
  systemctl enable systemd-timesyncd
  hwclock --systohc # sync hardware clock
  timedatectl
}

function set_localization {
  echo_title 'Localization'
  echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen
  locale-gen
  echo 'LANG=en_US.UTF-8' > /etc/locale.conf
}

function set_hostname {
  echo_title 'Hostname'
  echo "$HOSTNAME" > /etc/hostname
  cat << EOF > /etc/hosts
127.0.0.1 localhost
::1       localhost
127.0.1.1 $HOSTNAME $HOSTNAME
EOF
  echo "Host name is: $HOSTNAME"
}

function set_root_password {
  echo_title 'Root password'
  emulate_human_input << EOF | passwd
  $ROOT_PASSWORD  # Enter password
  $ROOT_PASSWORD  # Confirm password
EOF
}

function configure_boot_loader {
  echo_title 'Boot loader'
  replace /etc/default/grub 'GRUB_TIMEOUT=5' 'GRUB_TIMEOUT=0\nGRUB_HIDDEN_TIMEOUT=0'
  grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB --removable
  grub-mkconfig -o /boot/grub/grub.cfg
}

function enable_networking {
  echo_title 'Networking'
  cat << EOF > /etc/systemd/network/20-wired.network
[Match]
Name=$NETWORK_INTERFACE

[Network]
DHCP=ipv4
EOF
  systemctl enable systemd-networkd
  systemctl enable systemd-resolved
}

function enable_ssh {
  echo_title 'SSH'
  replace /etc/ssh/sshd_config '#\s*PermitRootLogin.*' 'PermitRootLogin yes'
  systemctl enable sshd
  systemctl enable haveged
}

# Utilities

function emulate_human_input {
  sed --expression='s/\s*\([\+0-9a-zA-Z]*\).*/\1/'
}

function replace {
  sed --in-place --regexp-extended --expression="s/$2/$3/g" "$1"
}

function echo_title {
  local args_string buffer_string
  args_string="##### $* #####"
  buffer_string="${args_string//?/#}"
  echo "$buffer_string"
  echo "$args_string"
  echo "$buffer_string"
}

main "$@"
