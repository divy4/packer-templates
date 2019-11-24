#!/usr/bin/env bash

# Following https://wiki.archlinux.org/index.php/Installation_guide

set -e

sed_human_input='s/\s*\([\+0-9a-zA-Z]*\).*/\1/'

# base - Base packages
# efibootmgr - EFI mode support
# grub - Bootloader
# haveged - Random number generator, needed to generate session keys for ssh to start properly (see https://bbs.archlinux.org/viewtopic.php?id=241346)
# iputils - Networking tools
# linux - You know, probably want this one
# linux-firmware - Firmware is pretty nice too
# openssh - ssh server, needed to continue provisioning tools after initial run
packages=(\
  base \
  efibootmgr \
  grub \
  haveged \
  iputils \
  linux \
  linux-firmware \
  openssh \
)

function main {
  echo_title 'Update the system clock'
  timedatectl set-ntp true
  timedatectl status

  echo_title 'Partition the disks'
  sed -e "$sed_human_input" << EOF | fdisk /dev/sda
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
  n            # new partition (swap)
  3            # partition 3
               # start after previous (default)
  +${MEMORY}M  # Same size as memory
  t            # change parition type
  3            # select partition 3
  19           # type=swap
  n            # new partition (root)
  4            # partition 4
               # start after previous (default)
               # fill remaining space (default)
  w            # write to disk and exit
EOF
  fdisk -l | grep dev

  echo_title 'Format the partitions'
  mkfs.fat -F32 /dev/sda1
  mkfs.ext4 /dev/sda2
  mkswap /dev/sda3
  swapon /dev/sda3
  mkfs.ext4 /dev/sda4

  echo_title 'Mount the file systems'
  mount /dev/sda4 /mnt
  mkdir /mnt/efi
  mount /dev/sda1 /mnt/efi
  mkdir /mnt/boot
  mount /dev/sda2 /mnt/boot
  findmnt | grep sda

  echo_title 'Select the mirrors'
  sed ':a;N;$!ba;s/\nServer/Server/g' < /etc/pacman.d/mirrorlist \
    | grep '^##\sUnited\sStates' \
    | sed 's/Server\s=/\nServer =/g' \
    > /tmp/mirrorlist
  mv /tmp/mirrorlist /etc/pacman.d/mirrorlist
  cat /etc/pacman.d/mirrorlist

  echo_title 'Install essential packages'
  pacstrap /mnt "${packages[@]}"

  echo_title 'Fstab'
  genfstab -U /mnt >> /mnt/etc/fstab
  cat /mnt/etc/fstab

  echo_title 'Chroot'
  exec_chroot

  echo_title 'Unmount partitions'
  umount -R /mnt

  echo_title 'Done! Rebooting...'
  sleep 1 && shutdown now &
}

function exec_chroot {
  export -f chroot_command
  export -f replace
  export NETWORK_INTERFACE
  export ROOT_PASSWORD
  export sed_human_input
  export VM_NAME
  export ZONE_CITY
  export ZONE_REGION
  arch-chroot /mnt /bin/bash -c "chroot_command"
}

function chroot_command {
  set -e
  function echo_title {
    echo "##### $* #####"
  }
  
  echo_title 'Time zone'
  ln -sf "/usr/share/zoneinfo/$ZONE_REGION/$ZONE_CITY" /etc/localtime
  hwclock --systohc
  echo "Zone set to $ZONE_REGION/$ZONE_CITY"

  echo_title 'Localization'
  echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen
  locale-gen
  echo 'LANG=en_US.UTF-8' > /etc/locale.conf

  echo_title 'Network configuration'
  echo "$VM_NAME" > /etc/hostname
  cat << EOF > /etc/hosts
127.0.0.1 localhost
::1       localhost
127.0.1.1 $VM_NAME $VM_NAME
EOF
  echo "Host name is: $VM_NAME"

  echo_title 'Root password'
  sed -e "$sed_human_input" << EOF | passwd
  $ROOT_PASSWORD  # Enter password
  $ROOT_PASSWORD  # Confirm password
EOF

  echo_title 'Boot loader'
  sed -e 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0\nGRUB_HIDDEN_TIMEOUT=0/' \
    < /etc/default/grub \
    > /tmp/grub
  mv /tmp/grub /etc/default/grub
  grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB --removable
  grub-mkconfig -o /boot/grub/grub.cfg

  echo_title 'Networking'
  cat << EOF > /etc/systemd/network/20-wired.network
[Match]
Name=$NETWORK_INTERFACE

[Network]
DHCP=ipv4
EOF
  systemctl enable systemd-networkd
  systemctl enable systemd-resolved

  echo_title 'SSH'
  replace /etc/ssh/sshd_config '#\s*PermitRootLogin.*' 'PermitRootLogin yes'
  systemctl enable sshd
  systemctl enable haveged
}

function replace {
  sed --in-place --regexp-extended "s/$2/$3/g" "$1"
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
