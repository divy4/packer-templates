#!/usr/bin/env bash
set -euo pipefail

CACHE_SERVER_START_TYPE='headless'
CACHE_SERVER='cache.bld.danivy.com'
RAMDISK_FILESYSTEM='ntfs'
RAMDISK_LETTER='W'
RAMDISK_SIZE='24G'
TEMPLATE_DIR='templates'
COPY_EXCEPTIONS='templates/arch/base.json|templates/debian/11.json'
COPY_TARGET='/c/vms/templates/'

function main {
  create_ramdisk
  start_cache_server
  build_templates
  copy_templates
  stop_cache_server
  destroy_ramdisk
  echo_title 'Done'
}

# Ramdisk

function create_ramdisk {
  echo_title 'Creating ramdisk'
  if imdisk -l -m "$RAMDISK_LETTER:" &> /dev/null; then
    echo 'Skipping, ramdisk already exists.'
  else
    run_command_as_admin imdisk -a -s "$RAMDISK_SIZE" -m "$RAMDISK_LETTER:" \
      -p "/fs:$RAMDISK_FILESYSTEM /q /y"
  fi
}

function destroy_ramdisk {
  echo_title 'Destroying ramdisk'
  imdisk -D -m "$RAMDISK_LETTER:"
}

# Cache Server

function start_cache_server {
  echo_title 'Starting cache server'
  local current_state
  current_state="$(VBoxManage showvminfo "$CACHE_SERVER" \
    | awk '$1 == "State:" {print $2}')"
  if [[ "$current_state" == 'running' ]]; then
    echo "Skipping, $CACHE_SERVER is already running."
  else
    VBoxManage startvm "$CACHE_SERVER" --type "$CACHE_SERVER_START_TYPE"
  fi
}

function stop_cache_server {
  echo_title 'Stopping cache server'
  VBoxManage controlvm "$CACHE_SERVER" acpipowerbutton
}

# Building

function build_templates {
  local templates template
  echo_title 'Generating build order'
  mapfile -t templates < <(get_templates)

  declare -A children
  declare -A parents
  declare -a roots
  generate_forest get_template_parent "${templates[@]}"
  mapfile -t templates < <(traverse_forest "${roots[@]}")
  echo 'Build plan:'
  printf '%s\n' "${templates[@]}"

  echo_title 'Building templates'
  ./build.sh "${templates[@]}"
}

function copy_templates {
  local templates template source sources
  echo_title 'Copying templates to output directory'
  mapfile -t templates < <(get_templates \
    | LC_ALL=en_US.utf8 grep --invert-match --perl-regexp "^($COPY_EXCEPTIONS)$" \
  )
  # LC_ALL=... needed to tell grep what locale to support
  # https://www.viresist.org/git-tutorials/grep-p-unterstutzt-nur-unibyte-und-utf-8-locales-in-jenkins/
  for template in "${templates[@]}"; do
    source="$(get_template_output_dir "$template")"
    if [[ -d "$source" ]]; then
      sources+=("$source")
    fi
  done
  cp --recursive --verbose "${sources[@]}" "$COPY_TARGET"
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

# Helpers

function get_templates {
  find "$TEMPLATE_DIR" -type f -name '*.pkrvars.hcl' | sort
}

function get_template_parent {
  local name
  if grep '^parent_template\s' "$1" --quiet; then
    name="$(grep '^parent_template\s' "$1" | sed 's/.*=\s*"\(.*\)"/\1/g')"
    echo "$TEMPLATE_DIR/${name/-/\/}.pkrvars.hcl"
  fi
}

function get_template_output_dir {
  local short_name
  short_name="$(echo "$1" | sed 's/templates\///g;s/\.json$//g;s/\//-/g')"
  echo "/${RAMDISK_LETTER,,}/packer_vms/$short_name" | sed 's/\/\//\//g'
}

function run_command_as_admin {
  # TODO: Throw error if exit code is nonzero
  powershell Start-Process -Wait -Verb RunAs \
    "$1" -ArgumentList "$(build_powershell_argument_list "${@:2}")"
}

function build_powershell_argument_list {
  printf "@('\"%s\"'" "$1"
  printf ",'\"%s\"'" "${@:2}"
  printf ')'
}

function echo_title {
  local args_string buffer_string
  args_string="##### $* #####"
  buffer_string="${args_string//?/#}"
  echo "$buffer_string"
  echo "$args_string"
  echo "$buffer_string"
}

if ! time main "$@"; then
  echo 'Error occured during template build. See details above.'
fi

echo 'Press enter to continue...'
read -r
