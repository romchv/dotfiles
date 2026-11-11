#
# ~/.bashrc
#

export PATH="$HOME/.local/bin:$PATH"

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

PS1='[\u@\h \W]\$ '

# Alias
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias eff='$EDITOR "$(ff)"'
alias ff='fzf --preview '\''bat --style-numbers --color=always {}'\'''
alias h='herdr'
alias t='tmux'
alias ls='eza -lh --group-directories-first --icons=auto'
alias lsa='ls -a'
alias lt='eza --tree --level=2 --long --icons --git'
alias lta='lt -a'

# Yazi
function y() {
	local tmp cwd; tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd" || builtin true
	command rm -f -- "$tmp"
}

# Nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Starship (terminal prompt)
eval "$(starship init bash)"


# Zoxide
eval "$(zoxide init bash --cmd cd)"
