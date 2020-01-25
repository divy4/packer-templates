#!/usr/bin/env bash

set -e

# feh - An image viewer, needed for setting the background
# virtualbox-guest-modules-arch - Modules needed for guest additions when using the default linux kernel
# virtualbox-guest-utils - Guest additions
# xf86-video-vmware - The video driver
packages=(\
  feh \
  virtualbox-guest-modules-arch \
  virtualbox-guest-utils \
  xf86-video-vmware \
)

function main {
  echo_title 'Installing VirtualBox Guest Additions'
  pacman --noconfirm --sync "${packages[@]}"
  systemctl start vboxservice
  systemctl enable vboxservice
  echo_title 'Done'
}

# utils

function add_config_files_modules {
  local user
  user="$1"
  echo_title "Loading configs from $@"
  if ! command -v git; then
    sudo pacman --noconfirm --sync git
  fi
  git clone --branch master --depth 1 https://github.com/divy4/config-files.git
  cd config-files
  sudo -u "$user" ./install.sh "${@:2}"
  cd ..
  rm -rf config-files/
}

function add_manualy_loaded_modules {
  echo_title "Manually loading modules: $*"
  replace /etc/mkinitcpio.conf '^MODULES=\((.*)\)' "MODULES=(\1 $*)"
}

function emulate_human_input {
  sed --expression='s/\s*\([\+0-9a-zA-Z]*\).*/\1/'
}

function replace {
  sed --in-place --regexp-extended --expression="s/$2/$3/g" "$1"
}

function x_support {
  case "$X_SUPPORT" in
  true)
    return 0
    ;;
  false)
    return 1
    ;;
  *)
    echo "Invalid value for X_SUPPORT: $X_SUPPORT"
    exit 1
    ;;
  esac
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
