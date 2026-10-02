#! /bin/bash

set -euo pipefail

echo "Updating system..."
sudo pacman -Syu --noconfirm

echo "Installing base dependencies for yay..."
sudo pacman -S --needed --noconfirm git base-devel

if command -v yay >/dev/null; then
  echo "yay already installed"
  exit 0
fi

echo "Cloning yay..."
rm -rf /tmp/yay
git clone https://aur.archlinux.org/yay.git /tmp/yay
cd /tmp/yay

echo "Building and installing yay..."
makepkg -si --noconfirm

echo "Cleaning up..."
cd ..
rm -rf /tmp/yay

echo "yay installed successfully"
