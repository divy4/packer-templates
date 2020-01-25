#!/usr/bin/env bash

set -e

# fluxbox - The good stuff
# xcompmgr - Needed for transparency. Not actually used here, but helpful for later.
packages=(\
  fluxbox \
  xcompmgr \
)

function main {
  echo_title 'Installing fluxbox'
  pacman --noconfirm --sync "${packages[@]}"
  replace /etc/X11/xinit/xinitrc '^exec.*' 'exec startfluxbox'
  add_configs "$NON_ROOT_USERNAME" fluxbox
  echo_title 'done'
}

# utils

function add_configs {
  local user configs
  user="$1"
  configs=("${@:2}")
  echo_title "Loading configs for ${configs[@]}"
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
