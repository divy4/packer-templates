#!/usr/bin/env bash
set -euo pipefail

function main {
  cd /tmp/ansible
  install_ansible
  run_ansible
  rm --recursive --force /tmp/ansible ~/.ansible/collections/ansible_collections/*
}

function get_os {
  #shellcheck disable=SC1091
  source /etc/os-release
  echo "$ID"
}

function install_ansible {
  if ! command -v ansible > /dev/null; then
    case "$(get_os)" in
    arch)
      pacman --noconfirm --sync ansible rsync sshpass python-packaging
      ;;
    centos)
      yum install --assumeyes ansible
      ;;
    *)
      echo "Error: Unrecognized OS"
      ;;
    esac
  fi
  ansible-galaxy collection install --requirements-file requirements.yml
}

function run_ansible {
  local playbooks
  export ANSIBLE_HOST_KEY_CHECKING=False
  playbooks=("$PLAYBOOK.yml")
  if ! [[ -f /usr/local/sbin/packer-trigger ]]; then
    playbooks+=(packer_trigger_setup.yml)
  fi
  #shellcheck disable=SC2154
  ansible-playbook \
    --connection=local \
    --extra-vars "ansible_become_password=$SSH_PASSWORD" \
    --extra-vars "ftp_proxy=$ftp_proxy" \
    --extra-vars "http_proxy=$http_proxy" \
    --extra-vars "https_proxy=$https_proxy" \
    --inventory localhost \
    "${playbooks[@]}"
}

main "$@"
