#!/usr/bin/env bash
set -euo pipefail

function set_hostname {
  echo "Setting hostname to ${HOSTNAME:?Please specify a hostname}"
  hostnamectl set-hostname "$HOSTNAME"
  if grep --fixed-strings --quiet '127.0.1.1' /etc/hosts; then
    sed --in-place "s/^127\.0\.1\.1.*/127.0.1.1 ${HOSTNAME//.*/} $HOSTNAME/g" /etc/hosts
  else
    echo "127.0.1.1 ${HOSTNAME//.*/} $HOSTNAME" >> /etc/hosts
  fi
  cat /etc/hosts
}

set_hostname "$@"
