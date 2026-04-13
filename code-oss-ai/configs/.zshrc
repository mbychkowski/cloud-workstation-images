# ZSH Configuration
# ==============================================================================

# ------------------------------------------------------------------------------
# History Configuration
# ------------------------------------------------------------------------------
export HISTFILE=~/.zsh_history
export HISTSIZE=10000
export SAVEHIST=10000

# Append to history file immediately
setopt inc_append_history
# Do not overwrite history
setopt append_history
# Ignore duplicate commands in history
setopt hist_ignore_all_dups
# Remove superfluous blanks before recording entry
setopt hist_reduce_blanks
# Don't execute the line directly, just put it into the editing buffer
setopt hist_verify

# ------------------------------------------------------------------------------
# Auto-completion
# ------------------------------------------------------------------------------
autoload -Uz compinit
compinit

# Case-insensitive auto-completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# ------------------------------------------------------------------------------
# Environment Variables
# ------------------------------------------------------------------------------
export EDITOR='nvim'
export VISUAL='nvim'

# ------------------------------------------------------------------------------
# Aliases
# ------------------------------------------------------------------------------
# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# File Listing
alias ll='ls -laF'
alias la='ls -A'
alias l='ls -CF'

# Editor
alias vim='nvim'
alias vi='nvim'

# Modern CLI Replacements
if command -v batcat &> /dev/null; then
  alias cat='batcat'
elif command -v bat &> /dev/null; then
  alias cat='bat'
fi

if command -v fzf &> /dev/null; then
  # FZF configuration can be added here
  export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
fi

# ------------------------------------------------------------------------------
# Plugins & Toolchains
# ------------------------------------------------------------------------------
# ZSH Plugins
[ -f /opt/zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source /opt/zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -f /opt/zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source /opt/zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# NVM
export NVM_DIR="/opt/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Starship Prompt
if command -v starship &> /dev/null; then
  eval "$(starship init zsh)"
fi
