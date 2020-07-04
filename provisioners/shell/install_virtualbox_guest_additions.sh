#!/usr/bin/env bash
set -euo pipefail

function main {
  echo "Installing guest additions..."
  case "$(get_os)" in
  arch)
    install_arch;;
  centos)
    install_centos;;
  *)
    echo "Error: Unrecognized OS '$(get_os)'"
    return 1
    ;;
  esac
  echo "Done!"
}

function install_arch {
  pacman --noconfirm --sync virtualbox-guest-utils xf86-video-vmware
  systemctl enable --now vboxservice
}

function install_centos {
  yum install --assumeyes epel-release
  yum install --assumeyes bzip2 dkms elfutils-libelf-devel gcc kernel-devel kernel-headers make perl
  mkdir /mnt/guest_additions/
  mount --types iso9660 --options loop "$GUEST_ADDITIONS_PATH" /mnt/guest_additions/
  /mnt/guest_additions/VBoxLinuxAdditions.run --nox11
  umount /mnt/guest_additions/
  rm --recursive /mnt/guest_additions/
}

function get_os {
  source /etc/os-release
  echo "$ID"
}

main "$@"
