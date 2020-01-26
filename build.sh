#!/usr/bin/env bash

set -e

function main {
  local args
  if [[ "$#" -ne 1 ]]; then
    echo 'Usage: ./build.sh TEMPLATE_DIRECTORY'
    return 1
  fi
  cd "$1"
  args=(-var "vm_base_directory=$(get_vm_base_directory)" -var-file=variables.json template.json)
  packer validate "${args[@]}"
  packer build -force "${args[@]}"
}

function get_vm_base_directory {
  local dir
  dir="${PACKER_VM_DIR:-"$(get_vbox_vm_directory)"}"
  if [[ -d "$dir" ]]; then
    echo "$dir"
  else
    echo_err "Invalid vm directory: '$dir' is not a directory"
    return 1
  fi
}

function get_vbox_vm_directory {
  VBoxManage list systemproperties \
    | grep '^Default machine folder:' \
    | sed 's/^Default machine folder:\s*//g'
}

function echo_err {
  >&2 echo "$@"
}

main "$@"