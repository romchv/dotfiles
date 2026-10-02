export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share/"
export XDG_CACHE_HOME="$HOME/.cache"


if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
  exec start-hyprland
fi

# if [ -z "$SSH_AUTH_SOCK" ]; then
#   eval "$(ssh-agent -s)"
#   ssh-add ~/.ssh/id_ed25519
# fi
