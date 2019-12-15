#!/usr/bin/env bash

set -e

packages=(\
  fluxbox \
  xcompmgr \
)

function main {
  echo_title 'Installing fluxbox'
  pacman --noconfirm --sync "${packages[@]}"
  echo_title 'done'
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