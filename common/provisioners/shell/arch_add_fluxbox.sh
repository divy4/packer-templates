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
  sed --in-place 's/^exec.*/exec startfluxbox/g' /etc/X11/xinit/xinitrc
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
