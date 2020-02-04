#!/usr/bin/env bash

set -e

# alsa-utils - Audio drivers and controls
# lal - Clock
# ttf-ubuntu-font-family - Fonts, needed for fluxbox to start successfully
# xorg-apps - A bunch of X utilities
# xorg-server - The X server, makes the world go round
# xorg-xinit - xinit, starts X server
# xterm - A terminal
packages=(\
  alsa-utils \
  lal \
  ttf-ubuntu-font-family \
  xorg-apps \
  xorg-server \
  xorg-xinit \
  xterm \
)

# vboxguest - General guest additions
# vboxvideo - Video
# vboxsf - Shared folders
modules=(\
  vboxguest \
  vboxsf \
  vboxvideo \
)

function main {
  echo_title 'Installing X'
  pacman --noconfirm --sync "${packages[@]}"
  add_manualy_loaded_modules "${modules[@]}"
  echo_title 'Configuring basic setup'
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
