#!/usr/bin/env bash
set -e

function main {
  check_vars
  install_ansible
  run_ansible
  rm -rf /tmp/ansible
}

function check_vars {
  local var
  for var in PLAYBOOK SSH_PASSWORD SSH_USERNAME; do
    if [[ -z "${!var}" ]]; then
      echo "Error: $var is not set"
      return 1
    fi
  done
}

function get_os {
  source /etc/os-release
  echo "$ID"
}

function install_ansible {
  if ! command -v ansible > /dev/null; then
    case "$(get_os)" in
    arch)
      pacman --noconfirm --sync ansible sshpass
      ;;
    centos)
      yum install --assumeyes ansible
      ;;
    *)
      echo "Error: Unrecognized OS"
      ;;
    esac
  fi
}

function run_ansible {
  cd /tmp/ansible
  export ANSIBLE_HOST_KEY_CHECKING=False
  ansible-playbook \
    --extra-vars "ansible_become_password=$SSH_PASSWORD" \
    --extra-vars "ansible_password=$SSH_PASSWORD" \
    --extra-vars "ftp_proxy=$ftp_proxy" \
    --extra-vars "http_proxy=$http_proxy" \
    --extra-vars "https_proxy=$https_proxy" \
    --inventory localhost \
    --user "$SSH_USERNAME" \
    "$PLAYBOOK.yml"
}

main "$@"
