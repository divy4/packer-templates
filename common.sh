#!/usr/bin/env bash

REPO_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

CACHE_SERVER='' #TODO 'cache.bld.danivy.com'
TEMPLATE_DIR="$REPO_DIR/templates"
VM_PERMANENT_DIR="$(\
  VBoxManage list systemproperties \
    | grep '^Default machine folder:' \
    | sed 's/^Default machine folder:\s*//g'
)"
VM_TEMP_DIR=/tmp/packer_vms

# Variants and templates

function get_variants {
  find "$REPO_DIR" -type f -name '*.pkrvars.hcl' | sort
}

function get_variant_parent {
  local name
  if grep '^parent_template\s' "$1" --quiet; then
    name="$(grep '^parent_template\s' "$1" | sed 's/.*=\s*"\(.*\)"/\1/g')"
    echo "$TEMPLATE_DIR/${name/-/\/}.pkrvars.hcl"
  fi
}

function get_template {
  echo "$(dirname "$(realpath "$1")")/template.pkr.hcl"
}

# VMs

function get_variant_temp_dir {
  local short_name
  short_name="$(echo "$1" | sed 's/templates\///g;s/\.json$//g;s/\//-/g')"
  echo "/tmp/packer_vms/$short_name" | sed 's/\/\//\//g'
}

function get_vm_name {
  local variant template role
  variant="$1"
  template="$(basename "$(dirname "$variant")")"
  role="$(basename "$variant" | sed 's/\.pkrvars.hcl$//g')"
  echo "$template-$role"
}

# Forests

function generate_forest {
  local parent_function nodes
  parent_function="$1"
  nodes=("${@:2}")

  # Make sure all children are set
  for node in "${nodes[@]}"; do
    children[$node]=''
  done

  # Get parent and children
  for node in "${nodes[@]}"; do
    parent="$("$parent_function" "$node")"
    parents[$node]="$parent"
    if [[ -n "$parent" ]]; then
      if [[ -z "${children[$parent]:-}" ]]; then
        children[$parent]="$node"
      else
        children[$parent]+=" $node"
      fi
    fi
  done

  # Find roots
  for node in "${nodes[@]}"; do
    if [[ -z "${parents[$node]}" ]]; then
      roots+=("$node")
    fi
  done
}

function traverse_forest {
  if [[ "$#" -eq 0 ]]; then
    return 0
  fi
  echo "$1"
  #shellcheck disable=SC2086
  traverse_forest ${children[$1]} "${@:2}"
}

# Misc

function get_proxy_url {
  if [[ -n "$CACHE_SERVER" ]]; then
    echo "http://$CACHE_SERVER:3128"
  fi
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
