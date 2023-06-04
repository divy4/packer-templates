#!/usr/bin/env bash
set -euo pipefail

COPY_EXCEPTIONS='templates/arch/base.json|templates/debian/11.json'

# shellcheck disable=1091
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

function main {
  trap quit EXIT
  start_cache_server
  build_variants
  copy_variants
  stop_cache_server
}

function quit {
  exit_code=$?
  if [[ "$exit_code" -eq 0 ]]; then
    echo_title 'Done'
  else
    echo 'Error occured during template build. See details above.'
  fi
  echo 'Press enter to continue...'
  read -r
  exit "$exit_code"
}

# Cache Server

function start_cache_server {
  local current_state
  echo_title 'Starting cache server'
  if [[ -z "$CACHE_SERVER" ]]; then
    echo "Skipping, no cache server to start."
  else
    current_state="$(VBoxManage showvminfo "$CACHE_SERVER" \
      | awk '$1 == "State:" {print $2}')"
    if [[ "$current_state" == 'running' ]]; then
      echo "Skipping, $CACHE_SERVER is already running."
    else
      VBoxManage startvm "$CACHE_SERVER" --type headless
    fi
  fi
}

function stop_cache_server {
  echo_title 'Stopping cache server'
  if [[ -z "$CACHE_SERVER" ]]; then
    echo "Skipping, no cache server to stop."
  else
    VBoxManage controlvm "$CACHE_SERVER" acpipowerbutton
  fi
}

# Building

function build_variants {
  local variants
  echo_title 'Generating build order'
  mapfile -t variants < <(get_variants)

  # shellcheck disable=2034
  declare -A children
  # shellcheck disable=2034
  declare -A parents
  declare -a roots
  generate_forest get_variant_parent "${variants[@]}"
  mapfile -t variants < <(traverse_forest "${roots[@]}")
  echo 'Build plan:'
  printf '%s\n' "${variants[@]}"

  echo_title 'Building templates'
  ./build.sh "${variants[@]}"
}

function copy_variants {
  local variants variant source sources
  echo_title 'Copying templates to output directory'
  # LC_ALL=... needed to tell grep what locale to support
  # https://www.viresist.org/git-tutorials/grep-p-unterstutzt-nur-unibyte-und-utf-8-locales-in-jenkins/
  mapfile -t variants < <(get_variants \
    | LC_ALL=en_US.utf8 grep --invert-match --perl-regexp "($COPY_EXCEPTIONS)$" \
  )
  for variant in "${variants[@]}"; do
    source="$(get_variant_temp_dir "$variant")"
    if [[ -d "$source" ]]; then
      sources+=("$source")
    fi
  done
  cp --recursive --verbose "${sources[@]}" "$VM_PERMANENT_DIR"
}

time main "$@"
