#!/usr/bin/env bash
set -e

function main {
  local swap size
  swap="${SWAP:?Please specify SWAP as being on or off}"
  if [[ "$swap" == "off" ]]; then
    if [[ -f /swapfile ]]; then
      remove_swap
    else
      echo "No swap to remove, skipping..."
    fi
  else
    size="${SWAP_SIZE:?Please specify SWAP size in MB}"
    if [[ -f /swapfile ]]; then
      swapoff /swapfile
      resize_swap "$size"
      swapon /swapfile
    else
      create_swap "$size"
    fi
  fi
}

function create_swap {
  local size
  echo 'Creating swap...'
  size="$1"
  touch /swapfile
  chmod 600 /swapfile
  resize_swap "$size"
  swapon /swapfile
  echo '/swapfile none swap defaults 0 0' >> /etc/fstab
}

function resize_swap {
  local expected_size current_size
  expected_size="$1"
  current_size="$(du --apparent-size --block-size=M /swapfile | awk '{print $1}')"
  echo "Resizing swap from $current_size to ${expected_size}M..."
  if [[ "$current_size" != "${expected_size}M" ]]; then
    dd if=/dev/zero of=/swapfile bs=1M count="$size" status=progress
    mkswap /swapfile
  fi
}

function remove_swap {
  echo 'Removing swap...'
  swapoff /swapfile
  sed --in-place 's/^\/swapfile.*//g' /etc/fstab
  rm /swapfile
}

main "$@"
