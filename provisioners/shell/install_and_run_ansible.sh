#!/usr/bin/env bash
set -e

function main {
  check_vars
  install_ansible
  run_ansible
  rm -rf ~/ansible
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
}

function run_ansible {
  cd ~/ansible
  export ANSIBLE_HOST_KEY_CHECKING=False
  echo "$SSH_PASSWORD" | \
    ansible-playbook \
      --ask-pass \
      --extra-vars "ftp_proxy=$ftp_proxy" \
      --extra-vars "http_proxy=$http_proxy" \
      --extra-vars "https_proxy=$https_proxy" \
      --inventory localhost \
      --user "$SSH_USERNAME" \
      "$PLAYBOOK.yml"
}

main "$@"
