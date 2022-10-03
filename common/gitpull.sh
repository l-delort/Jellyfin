#!/usr/bin/env bash

set -o errexit

# The parent directory is supposed to be the root directory of github repository.
currdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
parentdir="$(dirname "$currdir")"
if [ ! -d "$parentdir" ]; then
  echo "ERROR : $parentdir not found."
  exit 1
fi
cd "$parentdir"

update_submodules=""
if [ "${1:-}" = "--submodule" ]; then
  update_submodules="--recurse-submodules"
fi

git reset --hard $update_submodules
git pull $update_submodules

chmod +x ./common/install.sh
./common/install.sh
