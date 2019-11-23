#!/usr/bin/env bash

set -e

function main {
  if [[ "$#" -ne 1 ]]; then
    echo 'Usage: ./build.sh TEMPLATE_DIRECTORY_PATH'
    return 1
  fi
  cd "$1"
  local args
  args=(-var "vm_base_directory=$(get_vm_base_directory)" -var-file=variables.json template.json)
  packer validate "${args[@]}"
  packer build -force "${args[@]}"
}

function get_vm_base_directory {
  if [[ -d "$PACKER_VM_DIR" ]]; then
    echo "$PACKER_VM_DIR"
  else
    echo_err "Invalid PACKER_VM_DIR: '$PACKER_VM_DIR' is not a directory"
    return 1
  fi
}

function echo_err {
  >&2 echo "$@"
}

main "$@"