#!/usr/bin/env bash

set -e

packages=(\
  fluxbox \
  xcompmgr \
  xorg-apps \
  xorg-server \
  xorg-xinit \
  xterm \
)

function main {
  echo_title 'Installing X'
  pacman --noconfirm --sync "${packages[@]}"
  tee /etc/X11/xinit/xinitrc << EOF
#!/bin/sh

userresources=\$HOME/.Xresources
usermodmap=\$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap

# merge in defaults and keymaps
if [ -f "\$sysresources" ]; then
    xrdb -merge \$sysresources
fi
if [ -f "\$sysmodmap" ]; then
    xmodmap \$sysmodmap
fi
if [ -f "\$userresources" ]; then
    xrdb -merge "\$userresources"
fi
if [ -f "\$usermodmap" ]; then
    xmodmap "\$usermodmap"
fi

# start some nice programs
if [ -d /etc/X11/xinit/xinitrc.d ] ; then
 for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
  [ -x "\$f" ] && . "\$f"
 done
 unset f
fi

exec xterm -geometry 100x40+0+0 -name login
EOF
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