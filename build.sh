#!/usr/bin/env bash
set -euo pipefail

function main {
  local var_file
  if  [[ "$#" -eq 0 ]]; then
    echo 'Usage: ./build.sh TEMPLATE_VAR_FILE ...'
    return 1
  fi
  # 2 separate loops because finding out about a typo an hour later isn't great
  for var_file in "$@"; do
    validate_setup "$var_file"
  done
  for var_file in "$@"; do
    build_template "$var_file"
  done
}

function validate_setup {
  if [[ ! -f "$1" ]] || [[ "$1" != *.pkrvars.hcl ]]; then
    echo "Error: '$1' is not a variable file."
    return 1
  fi
}

function build_template {
  local var_file  args
  var_file="$(realpath "$1")"
  args=(\
    "-var-file=$var_file" \
    -var \
    "vm_base_directory=$(get_vm_base_directory)" \
    -var \
    "name=$(get_name "$var_file")"
    "$(get_template "$var_file")" \
  )
  echo_title "Building $var_file"
  packer validate "${args[@]}"
  packer build -force "${args[@]}"
}

function get_template {
  echo "$(dirname "$(realpath "$1")")/template.pkr.hcl"
}

function get_name {
  local var_file template role
  var_file="$1"
  template="$(basename "$(dirname "$var_file")")"
  role="$(basename "$var_file" | sed 's/\.pkrvars.hcl$//g')"
  echo "$template-$role"
}

function get_vm_base_directory {
  echo "${PACKER_VM_DIR:-"$(get_vbox_vm_directory)"}"
}

function get_vbox_vm_directory {
  VBoxManage list systemproperties \
    | grep '^Default machine folder:' \
    | sed 's/^Default machine folder:\s*//g'
}

function echo_title {
  local args_string buffer_string
  args_string="##### $* #####"
  buffer_string="${args_string//?/#}"
  echo "$buffer_string"
  echo "$args_string"
  echo "$buffer_string"
}

function echo_err {
  >&2 echo "$@"
}

time main "$@"
