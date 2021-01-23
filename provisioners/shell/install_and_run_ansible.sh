#!/usr/bin/env bash
set -euo pipefail

function main {
  install_ansible
  run_ansible
  rm -rf /tmp/ansible
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
      pacman --noconfirm --sync ansible rsync sshpass
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
  local playbooks
  cd /tmp/ansible
  export ANSIBLE_HOST_KEY_CHECKING=False
  playbooks=("$PLAYBOOK.yml")
  if ! [[ -f /usr/local/sbin/packer-trigger ]]; then
    playbooks+=(packer_trigger_setup.yml)
  fi
  #shellcheck disable=SC2154
  ansible-playbook \
    --extra-vars "ansible_become_password=$SSH_PASSWORD" \
    --extra-vars "ansible_password=$SSH_PASSWORD" \
    --extra-vars "ftp_proxy=$ftp_proxy" \
    --extra-vars "http_proxy=$http_proxy" \
    --extra-vars "https_proxy=$https_proxy" \
    --inventory localhost \
    --user "$SSH_USERNAME" \
    "${playbooks[@]}"
}

main "$@"
