#!/bin/bash

set -euo pipefail

# System-level tweaks (files under /etc). Each one is idempotent.

# Brightness keys: the ACPI video driver changes the backlight itself and
# also passes the keys on, so with Hyprland's brightnessctl binds every
# press is applied twice and the steps fight each other. Let only the
# binds handle them.
echo "Disabling kernel brightness key handling..."
echo 'options video brightness_switch_enabled=0' | sudo tee /etc/modprobe.d/brightness.conf >/dev/null
param=/sys/module/video/parameters/brightness_switch_enabled
if [[ -e "$param" ]]; then
  # Apply now too, the modprobe option only takes effect on next boot
  echo N | sudo tee "$param" >/dev/null
fi

# Services the shell relies on: wifi (NetworkManager) and bluetooth.
echo "Enabling NetworkManager and bluetooth..."
sudo systemctl enable NetworkManager.service bluetooth.service

# Login screen: greetd shows the Quickshell greeter (greeter.qml) in cage,
# then starts Hyprland. The greeter's copies of the config and theme live
# in /etc/greetd, owned by you so greeter-sync / theme-switch can refresh
# them without sudo. greetd takes tty1 from the console login from the next boot.
echo "Setting up the greetd login screen..."
sed "s/@USER@/$USER/" "$(dirname "$0")/../system/greetd/config.toml" | sudo tee /etc/greetd/config.toml >/dev/null
sudo install -d -o "$USER" -g "$(id -gn)" -m 755 /etc/greetd/quickshell /etc/greetd/theme
"$HOME/.local/bin/greeter-sync"
sudo systemctl enable greetd.service
