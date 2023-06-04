#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=1091
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

function main {
  local variant
  if [[ "$#" -eq 0 ]]; then
    echo 'Usage: ./build.sh TEMPLATE_VARIANT_1 ...'
    return 1
  fi
  # 2 separate loops because finding out about a typo an hour later isn't great
  for variant in "$@"; do
    validate_setup "$variant"
  done
  for variant in "$@"; do
    build_template "$variant"
  done
}

function validate_setup {
  if [[ ! -f "$1" ]] || [[ "$1" != *.pkrvars.hcl ]]; then
    echo "Error: '$1' is not a variable file."
    return 1
  fi
}

function build_template {
  local variant args
  variant="$(realpath "$1")"
  args=(\
    "-var-file=$variant" \
    -var "proxy=$(get_proxy_url)" \
    -var "vm_base_directory=$VM_TEMP_DIR" \
    -var "name=$(get_vm_name "$variant")"
    "$(get_template "$variant")" \
  )
  echo_title "Building $variant"
  packer validate "${args[@]}"
  packer build -force "${args[@]}"
}

time main "$@"
