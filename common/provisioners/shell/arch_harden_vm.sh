#!/usr/bin/env bash

set -e

function main {
  echo_title 'Disabling SSH'
  sed --in-place 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
  systemctl disable sshd
  echo_title 'Enabling Firewall'
  pacman --noconfirm --sync ufw
  ufw default deny
  ufw enable
  echo_title 'Done'
}

# utils

function add_configs {
  local user configs
  user="$1"
  configs=("${@:2}")
  echo_title "Loading configs for ${configs[*]}"
  if ! command -v git; then
    sudo pacman --noconfirm --sync git
  fi
  git clone --branch master --depth 1 https://github.com/divy4/config-files.git
  cd config-files
  sudo -u "$user" ./install.sh "${configs[@]}"
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
