#!/usr/bin/env bash

set -e

# base-devel - Base development tools
# docker - All the containers
# git - All the changes
# man - rtfm
# nano - For when vim is difficult
# nmap - Network scanning tool
base_packages=(\
  base-devel \
  docker \
  git \
  man \
  nano \
  nmap \
)

base_services=(\
  docker \
)

# vim - For when nano is too simple
non_gui_tools=(\
  vim \
)

# chromium - www
# code - Code editor
# gvim - vim with mouse support
# ttf-dejavu - Needed by chromium
gui_tools=(\
  chromium \
  code \
  gvim \
  ttf-dejavu \
)

function main {
  local packages services
  if x_support; then
    packages=("${base_packages[@]}" "${gui_tools[@]}")
  else
    packages=("${base_packages[@]}" "${non_gui_tools[@]}")
  fi
  services=("${base_services[@]}")
  echo_title 'Installing tools'
  pacman --noconfirm --sync "${packages[@]}"
  echo_title 'Starting and enabling services'
  for service in "${services[@]}"; do
    systemctl start "$service"
    systemctl enable "$service"
  done
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
