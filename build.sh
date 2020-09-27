#!/usr/bin/env bash

set -e

function main {
  validate_setup "$@"
  build_template "$@"
}

function validate_setup {
  if [[ "$#" -ne 1 ]] \
      || [[ ! -f "$1" ]] \
      || [[ "$1" != *.json ]] \
      || [[ "$(basename "$1")" == "template.json" ]]; then
    echo 'Usage: ./build.sh TEMPLATE_VARIANT_JSON'
    return 1
  fi
  if [[ ! -f 'provisioners/ansible/.git' ]]; then
    echo 'Error: provisioners/ansible/.git not found!'
    echo 'Please execute the following to install the ansible repo:'
    echo '"git submodule update --init --recursive"'
    return 2
  fi
}

function build_template {
  local args var_file name
  var_file="$(realpath "$1")"
  name="$(get_name "$var_file")"
  cd "$(dirname "$1")"
  args=(\
    "-var-file=$var_file" \
    -var \
    "vm_base_directory=$(get_vm_base_directory)" \
    -var \
    "name=$name"
    template.json \
  )
  packer validate "${args[@]}"
  packer build -force "${args[@]}"
}

function get_name {
  local var_file template role
  var_file="$1"
  template="$(basename "$(dirname "$var_file")")"
  role="$(basename "$var_file" | sed 's/\.json$//g')"
  echo "${template}_$role"
}

function get_vm_base_directory {
  echo "${PACKER_VM_DIR:-"$(get_vbox_vm_directory)"}"
}

function get_vbox_vm_directory {
  VBoxManage list systemproperties \
    | grep '^Default machine folder:' \
    | sed 's/^Default machine folder:\s*//g'
}

function echo_err {
  >&2 echo "$@"
}

time main "$@"
