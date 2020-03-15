#!/usr/bin/env bash
set -e

function main {
  local var
  for var in PLAYBOOK SSH_PASSWORD SSH_USER; do
    if [[ -z "${!var}" ]]; then
      echo "Error: $var is not set"
      return 1
    fi
  done
  pacman --noconfirm --sync ansible sshpass
  cd ~/ansible
  export ANSIBLE_HOST_KEY_CHECKING=False
  echo "$SSH_PASSWORD" | \
    ansible-playbook \
      --ask-pass \
      --extra-vars "ftp_proxy=$ftp_proxy" \
      --extra-vars "http_proxy=$http_proxy" \
      --extra-vars "https_proxy=$https_proxy" \
      --inventory localhost \
      --user "$SSH_USER" \
      "$PLAYBOOK"
}

main "$@"
