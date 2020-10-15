#!/usr/bin/env bash
set -euo pipefail

TEMPLATE_DIR='templates'

function main {
  # real stuff variables
  local templates template build_order
  # graph/traversal variables
  local parents visited start current visitation_path reverse_visitation_path i
  declare -A parents # associative array
  declare -A visited # associative array
  
  echo 'Locating templates...'
  mapfile -t templates < <(find "$TEMPLATE_DIR" -type f -not -name 'template.json' | sort)
  
  echo 'Locating template parents...'
  for template in "${templates[@]}"; do
    parents["$template"]="$(get_template_parent "$template")"
    visited["$template"]=false
  done
  
  echo 'Calculating build order...'
  build_order=()
  for start in "${templates[@]}"; do
    visitation_path=()
    current="$start"
    # work up from the node up the forest until a visited spot or a root is found
    while [[ "$current" != null ]] && [[ "${visited[$current]}" == false ]]; do
      visited["$current"]=true
      visitation_path+=("$current")
      current="${parents[$current]}"
    done
    # Add reverse of visition path to order
    if [[ "${#visitation_path[@]}" -ne 0 ]]; then
      mapfile -t reverse_visitation_path < <(printf "%s\n" "${visitation_path[@]}" | tac)
      build_order+=("${reverse_visitation_path[@]}")
    fi
  done

  echo 'Build order:'
  for (( i=0; i < "${#build_order[@]}"; i++ )); do
    echo "$i - ${build_order[$i]}"
  done
  
  for (( i=0; i < "${#build_order[@]}"; i++ )); do
    echo "Starting build $i - ${build_order[$i]}..."
    ./build.sh "${build_order[$i]}"
    echo "Finishing Build $i - ${build_order[$i]}"
  done
}

function get_template_parent {
  local name
  name="$(jq --raw-output .parent_template "$1")"
  if [[ "$name" == null ]]; then
    echo null
  else
    echo "$TEMPLATE_DIR/${name/-/\/}.json"
  fi
}

time main "$@"
