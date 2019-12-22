#!/usr/bin/env bash

set -e

function main {
  local groups
  groups=()
  if [[ "$IS_SUDO_USER" == 'true' ]]; then
    install_sudo
    groups+=('sudo')
  fi

  echo_title 'Adding user'
  if [[ "${#groups}" -eq 0 ]]; then
    useradd --create-home "$USERNAME"
  else
    useradd --create-home --groups "${groups[@]}" "$USERNAME"
  fi

  emulate_human_input << EOF | passwd "$USERNAME"
  $PASSWORD # enter password
  $PASSWORD # confirm password
EOF

  echo_title 'Done'
}

function install_sudo {
  if ! command -v sudo; then
    echo_title 'Installing sudo'
    pacman --noconfirm --sync sudo
    groupadd sudo
    echo -e '## Allow the sudo group to use sudo\n%sudo ALL=(ALL) ALL' > /etc/sudoers.d/group_sudo
  fi
}

# utils

function add_manualy_loaded_modules {
  echo_title "Manually loading modules: $@"
  replace /etc/mkinitcpio.conf '^MODULES=\((.*)\)' "MODULES=(\1 $@)"
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
