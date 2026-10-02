# History
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=1000

# Options
setopt PROMPT_SUBST
setopt dot_glob # include dotfiles
setopt extended_glob # match ~ # ^
setopt no_case_glob no_case_match # make cmp case insensitive
unsetopt prompt_sp # don't autoclean blankline

# Keybinds

# Completion
autoload -Uz compinit
compinit

# Prompt
source ~/.config/zsh/theme.zsh
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats "%K{${PROMPT_GIT_BG}}%F{${PROMPT_GIT_FG}} git:(%b)%f %k"
NEWLINE=$'\n'
PROMPT='${NEWLINE}%K{${PROMPT_BG}}%F{${PROMPT_FG}} %n %f%k%K{${PROMPT_PATH_BG}}%F{${PROMPT_PATH_FG}} %~ %f%k${vcs_info_msg_0_} ❯ '

# Alias
alias grp='grep --color=auto'
alias vim='nvim'
alias ls='eza -lh --group-directories-first --icons=auto'
alias lsa='ls -a'
alias lt='eza --tree --level=2 --long --icons --git'
alias lta='lt -a'
alias d='lazydocker'
# alias nvim12='NVIM_APPNAME=nvim_12 nvim'
alias nginx-server="TERM=xterm-256color ssh rom@192.168.122.59"
alias app-server="TERM=xterm-256color ssh rom@192.168.122.91"
alias app2-server="TERM=xterm-256color ssh rom@192.168.122.18"

# Path
export PATH="$HOME/.local/bin/:$PATH"
export PATH="$HOME/.config/theme-switcher/bin:$PATH"

# Nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Yazi
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# Autosuggestions
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# Syntax highlighting (must be last)
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
