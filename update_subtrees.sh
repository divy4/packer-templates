#!/usr/bin/env bash
set -euo pipefail

if ! git remote | grep --quiet ansible; then
  git remote add ansible git@github.com:divy4/ansible.git
fi

git subtree pull --prefix=provisioners/ansible/ ansible main --squash
