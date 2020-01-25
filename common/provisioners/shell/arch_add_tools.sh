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

base_root_configs=(\
  nano \
  vim \
)

base_non_root_configs=(\
  bash \
  git \
  ssh \
)

# vim - For when nano is too simple
non_gui_tools=(\
  vim \
)

non_gui_root_configs=(\
)

non_gui_non_root_configs=(\
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

gui_root_configs=(\
)

gui_non_root_configs=(\
)

function main {
  local packages services root_configs non_root_configs
  if x_support; then
    packages=("${base_packages[@]}" "${gui_tools[@]}")
    root_configs=("${base_root_configs[@]}" "${gui_root_configs[@]}")
    non_root_configs=("${base_non_root_configs[@]}" "${gui_non_root_configs[@]}")
  else
    packages=("${base_packages[@]}" "${non_gui_tools[@]}")
    root_configs=("${base_root_configs[@]}" "${non_gui_root_configs[@]}")
    non_root_configs=("${base_non_root_configs[@]}" "${non_gui_non_root_configs[@]}")
  fi
  services=("${base_services[@]}")
  echo_title 'Installing tools'
  pacman --noconfirm --sync "${packages[@]}"
  echo_title 'Starting and enabling services'
  for service in "${services[@]}"; do
    systemctl start "$service"
    systemctl enable "$service"
  done
  add_configs root "${root_configs[@]}"
  add_configs "$NON_ROOT_USERNAME" "${non_root_configs[@]}"
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
