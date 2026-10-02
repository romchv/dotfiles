#!/bin/bash

set -euo pipefail

cd "$(dirname "$0")/../stow"

backup_dir="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

# Move away existing files that would conflict with stow
backup_conflicts() {
  local pkg=$1 file target
  while IFS= read -r file; do
    file=${file#"$pkg/"}
    target="$HOME/$file"

    # Already a symlink into the dotfiles: stow handles it
    if [[ -L "$target" && "$(readlink -f "$target")" == "$PWD/$pkg/$file" ]]; then
      continue
    fi

    if [[ -e "$target" || -L "$target" ]]; then
      echo "Backing up ~/$file"
      mkdir -p "$backup_dir/$(dirname "$file")"
      mv "$target" "$backup_dir/$file"
    fi
  done < <(find "$pkg" \( -type f -o -type l \))
}

echo "Linking dotfiles..."
for pkg in */; do
  pkg=${pkg%/}
  backup_conflicts "$pkg"
  # --no-folding: link files one by one, so apps writing logs/caches
  # in their config folder don't write them into the repo
  stow --restow --no-folding -t "$HOME" "$pkg"
  echo "  $pkg"
done

if [[ -d "$backup_dir" ]]; then
  echo "Old files were moved to $backup_dir"
fi

# First install: render a theme, so apps (and Quickshell, and the greeter
# set up by 05-system.sh) have their colors.
if [[ ! -f ${XDG_STATE_HOME:-$HOME/.local/state}/theme/current/name ]]; then
  echo "Applying the default theme..."
  "$HOME/.local/bin/theme-switch" black-sand
fi
