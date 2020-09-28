#!/usr/bin/env bash
set -e

function set_hostname {
  echo "Setting hostname to ${HOSTNAME:?Please specify a hostname}"
  hostnamectl set-hostname "$HOSTNAME"
}

set_hostname "$@"
