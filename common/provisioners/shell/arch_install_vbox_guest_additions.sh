#!/usr/bin/env bash

set -e

function main {
  echo_title 'Installing VirtualBox Guest Additions'
  pacman --noconfirm --sync virtualbox-guest-modules-arch virtualbox-guest-utils xf86-video-vmware
  systemctl start vboxservice
  systemctl enable vboxservice
  echo_title 'Done'
}

# utils

function emulate_human_input {
  sed --expression='s/\s*\([\+0-9a-zA-Z]*\).*/\1/'
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