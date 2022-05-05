#!/usr/bin/env bash
set -euo pipefail

if ! git remote | grep --quiet config-files; then
  git remote add config-files git@github.com:divy4/config-files.git
fi

git subtree pull --prefix=roles/development/files/config-files/ config-files main --squash
