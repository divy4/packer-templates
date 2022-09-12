#!/usr/bin/env bash
set -euo pipefail

function main {
  local template
  if  [[ "$#" -eq 0 ]]; then
    echo 'Usage: ./build.sh TEMPLATE_VARIANT_JSON'
    return 1
  fi
  # 2 separate loops because finding out about a typo an hour later isn't great
  for template in "$@"; do
    validate_setup "$template"
  done
  for template in "$@"; do
    build_template "$template"
  done
}

function validate_setup {
  if [[ ! -f "$1" ]] \
      || [[ "$1" != *.json ]] \
      || [[ "$(basename "$1")" == "template.json" ]]; then
    echo "Error: '$1' is not a template variable file."
    return 1
  fi
}

function build_template {
  local old_directory args var_file name
  old_directory="$(pwd)"
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
  echo_title "Building $var_file"
  packer validate "${args[@]}"
  packer build -force "${args[@]}"
  cd "$old_directory"
}

function get_name {
  local var_file template role
  var_file="$1"
  template="$(basename "$(dirname "$var_file")")"
  role="$(basename "$var_file" | sed 's/\.json$//g')"
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
