#!/usr/bin/env bash

set -e

function main {
  if [[ "$#" -ne 1 ]]; then
    echo 'Usage: ./build.sh TEMPLATE_DIRECTORY_PATH'
    return 1
  fi
  cd "$1"
  packer validate -var-file=variables.json template.json
  packer build -force -var-file=variables.json template.json
}

function echo_err {
  >&2 echo "$@"
}

main "$@"