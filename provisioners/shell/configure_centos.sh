#!/usr/bin/env bash
set -e

function main {
  set_hostname
  setup_swap
}

function set_hostname {
  hostnamectl set-hostname "${HOSTNAME:?Please specify a hostname}"
}

function setup_swap {
  if [[ "${SWAP:?Please specify SWAP as being on or off}" == 'on' ]]; then
    dd if=/dev/zero of=/swapfile bs=1M count="${SWAP_SIZE:?Please specify a SWAP_SIZE}" status=progress
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap defaults 0 0' >> /etc/fstab
  fi
}

main "$@"
