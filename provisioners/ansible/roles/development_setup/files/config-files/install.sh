#!/usr/bin/env bash

set -e

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
    copy file bashrc ~/.bashrc
    copy file bootstrap.sh ~/.bootstrap.sh
  fi
}

function config_chromium {
  if is_root; then
    echo_err 'Root chromium config not supported!'
    return 1
  else
    copy file chromium-flags.conf ~/.config/chromium-flags.conf
    if [[ -f ~/.config/chromium/Default/Preferences ]]; then
      cp ~/.config/chromium/Default/Preferences /tmp/Preferences
    else
      echo '{}' > /tmp/Preferences
      mkdir --parents ~/.config/chromium/Default/
    fi
    jq '.browser.custom_chrome_frame=false' /tmp/Preferences \
      | jq ".credentials_enable_service=false" \
      | jq ".download.default_directory=\"$HOME/downloads/\"" \
      | jq ".savefile.default_directory=\"$HOME/downloads/\"" \
      > ~/.config/chromium/Default/Preferences
  fi
}

function config_code {
  if is_root; then
    echo_err 'Root code config not supported!'
    return 1
  else
    copy file code/settings.json ~/.config/Code\ -\ OSS/User/settings.json
    cat code/extensions | xargs --max-lines=1 code --install-extension
  fi
}

function config_conemu {
  if is_root; then
    echo_err 'Root conemu config not supported!'
    return 1
  else
    copy file ConEmu.xml "$APPDATA/ConEmu.xml"
  fi
}

function config_fluxbox {
  local apps app exp
  if is_root; then
    echo_err 'Root fluxbox config not supported!'
    return 1
  else
    copy directory fluxbox/fluxbox ~/.fluxbox
    copy file fluxbox/xinitrc ~/.xinitrc
    copy file fluxbox/Xdefaults ~/.Xdefaults
    copy file fluxbox/Xresources ~/.Xresources
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
    copy file gitconfig ~/.gitconfig
    if ! command -v gpg2; then
      sed --in-place 's/gpg2/gpg/g' ~/.gitconfig
    fi
  fi
}

function config_nano {
  if is_root; then
    copy file nanorc /etc/nanorc /etc/nano/nanorc
  else
    copy file nanorc ~/.nanorc
  fi
}

function config_scripts {
  if is_root; then
    copy directory scripts /usr/local/bin
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
    copy file sshconfig ~/.ssh/config
  fi
}

function config_vim {
  if is_root; then
    copy file vimrc /etc/vimrc /etc/vim/vimrc
  else
    copy file vimrc ~/.vimrc
  fi
}

function get_config_functions {
  declare -F \
    | grep --only-matching --perl-regexp '(?<=\s)config_\w*$' \
    | sed 's/config_//g' \
    | sort --ignore-case
}

function copy {
  local type source targets target target_parent
  type="$1"
  source="$2"
  targets=("${@:3}")
  target="$(choose_target file "${targets[@]}")"
  target_parent="$(realpath --canonicalize-missing "$target/..")"
  if [[ ! -d "$target_parent" ]]; then
    mkdir --parents "$target_parent"
  fi
  case "$type" in
  file)
    cp "$source" "$target";;
  directory)
    cp --recursive "$source/." "$target";;
  *)
    echo_err "Invalid type: $type"
    return 1;;
  esac
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
