#!/usr/bin/env bash

set -euo pipefail

function main {
  local config_functions interactive config_function
  config_functions=("$@")
  interactive=false
  if [[ -z "${config_functions[*]}" ]]; then
    mapfile -t config_functions < <(get_config_functions)
    interactive=true
  fi
  for config_function in "${config_functions[@]}"; do
    if [[ "$interactive" == 'false' ]] \
        || confirm_config "$config_function"; then
      "config_$config_function"
    fi
  done
}

function config_bash {
  if is_root; then
    echo_err 'Root bash config not supported!'
    return 1
  else
    install --mode=644 bashrc ~/.bashrc
    install --mode=755 bootstrap.sh ~/.bootstrap.sh
  fi
}

function config_code {
  if is_root; then
    echo_err 'Root code config not supported!'
    return 1
  else
    install --mode=644 -D code/settings.json ~/.config/Code\ -\ OSS/User/settings.json
    cat code/extensions | xargs --max-lines=1 code --install-extension
  fi
}

function config_conemu {
  if is_root; then
    echo_err 'Root conemu config not supported!'
    return 1
  else
    install --mode=644 ConEmu.xml "$APPDATA/ConEmu.xml"
  fi
}

function config_fluxbox {
  local apps app exp
  if is_root; then
    echo_err 'Root fluxbox config not supported!'
    return 1
  else
    cp --recursive fluxbox/fluxbox/* ~/.fluxbox/
    install --mode=644 fluxbox/xinitrc ~/.xinitrc
    install --mode=644 fluxbox/Xdefaults ~/.Xdefaults
    install --mode=644 fluxbox/Xresources ~/.Xresources
    mapfile -t apps < <(\
      grep '# autoexec' ~/.fluxbox/menu \
      | sed --regexp-extended --expression='s/.*\((\w+)\).*/\1/g' \
    )
    for app in "${apps[@]}"; do
      if command -v "$app" > /dev/null; then
        exp="s/#\sautoexec\s*(.*\($app\))/\1/g"
        sed --in-place --regexp-extended --expression="$exp" ~/.fluxbox/menu
      fi
    done
  fi
}

function config_git {
  if is_root; then
    echo_err 'Root git config not supported!'
    return 1
  else
    install --mode=644 gitconfig ~/.gitconfig
    if ! command -v gpg2; then
      sed --in-place 's/gpg2/gpg/g' ~/.gitconfig
    fi
  fi
}

function config_nano {
  if is_root; then
    install --mode=644 nanorc /etc/nanorc
    install --mode=644 -D nanorc /etc/nano/nanorc
  else
    install --mode=644 nanorc ~/.nanorc
  fi
}

function config_scripts {
  if is_root; then
    install --mode=755 --owner=root --group=root scripts/* /usr/local/bin/
  else
    echo_err 'Non-root scripts config not supported!'
    return 1
  fi
}

function config_ssh {
  if is_root; then
    echo_err 'Root ssh config not supported!'
    return 1
  else
    install --mode=600 -D sshconfig ~/.ssh/config
  fi
}

function config_vim {
  if is_root; then
    install --mode=644 --owner=root --group=root vimrc /etc/vimrc
    install --mode=644 --owner=root --group=root -D vimrc /etc/vim/vimrc
  else
    install --mode=644 vimrc ~/.vimrc
  fi
}

function get_config_functions {
  declare -F \
    | grep --only-matching --perl-regexp '(?<=\s)config_\w*$' \
    | sed 's/config_//g' \
    | sort --ignore-case
}

function choose_target {
  local type targets target
  type="$1"
  targets=("${@:2}")
  for target in "${targets[@]}"; do
    if [[ "$type" == 'file' ]] && [[ -f "$target" ]] || \
        [[ "$type" == 'directory' ]] && [[ -d "$target" ]]; then
      echo "$target"
      return 0
    fi
  done
  echo "${targets[0]}"
}

function confirm_config {
  confirm "Configure $1"
}

function confirm {
  local message answer input
  message="$1"
  if [ "$message" != "" ]; then
    message="$message "
  fi
  answer=-1
  while [[ "$answer" -eq -1 ]]; do
    echo_tty -n "$message(y/n) "
    read -r input
    if is_yes "$input"; then
      answer=0
    elif is_no "$input"; then
      answer=1
    fi
  done
  return "$answer"
}

function is_yes {
  [[ "${1,,}" =~ ^y(es)?$ ]]
}

function is_no {
  [[ "${1,,}" =~ ^no?$ ]]
}

function is_root {
  [[ "$UID" -eq 0 ]]
}

function echo_tty {
  echo "$@" > /dev/tty
}

function echo_err {
  >&2 echo "$@"
}

# cd to directory containing this script
cd "$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

main "$@"
