#!/bin/bash

set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  echo "Don't run this as root, sudo is asked when needed"
  exit 1
fi

cd "$(dirname "$0")"

# Ask the sudo password once, then keep it alive until the script ends
sudo -v
while true; do
  sudo -n true
  sleep 60
done 2>/dev/null &
trap 'kill $!' EXIT

run() {
  echo
  echo "==> Running $1..."
  bash "scripts/$1.sh"
}

run 02-yay
run 03-packages
run 04-dotfiles

echo
echo "Setup complete"
