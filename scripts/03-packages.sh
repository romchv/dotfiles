#!/bin/bash

set -euo pipefail

# Print the vendor of every GPU (nvidia, intel, amd), read from sysfs
# so it works without pciutils. Hybrid laptops print more than one.
detect_gpus() {
  local dev
  for dev in /sys/bus/pci/devices/*; do
    # PCI class 0x03xxxx = display controller
    [[ "$(<"$dev/class")" == 0x03* ]] || continue

    case "$(<"$dev/vendor")" in
      0x10de) echo nvidia ;;
      0x8086) echo intel ;;
      0x1002) echo amd ;;
    esac
  done | sort -u
}

echo "Downloading pacman packages..."
sudo pacman -S --needed - < packages/pacman.txt

gpus=$(detect_gpus)

if [[ -z "$gpus" ]]; then
  echo "No known GPU detected, skipping drivers"
fi

for gpu in $gpus; do
  echo "Downloading $gpu GPU drivers..."
  sudo pacman -S --needed - < "packages/gpu-$gpu.txt"
done

echo "Downloading AUR packages..."
yay -S --needed --noconfirm --answerclean None --answerdiff None - < packages/aur.txt

# cpu_vendor=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}'})
#
# case "$cpu_vendor" in
#   GenuineIntel)
#     echo "Intel CPU detected"
#     sudo pacman -S --needed intel-ucode
#     ;;
#
#   AuthenticAMD)
#     echo "AMD CPU detected"
#     sudo pacman -S --needed amd-ucode
#     ;;
#
#   *)
#     echo "Unknown CPU vendor": $cpu_vendor
#     exit 1
#     ;;
#   esac
