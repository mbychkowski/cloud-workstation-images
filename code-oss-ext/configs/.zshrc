export PATH="$PATH:/opt/workstation/bin"

export ZSH=/opt/workstation/oh-my-zsh
export ZSH_THEME="powerlevel10k/powerlevel10k"
export POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=True

plugins=(
    git
    zsh-autosuggestions
    kubectl
)

alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'

alias tf='terraform'
alias code='code-oss-cloud-workstations'

if [ -f ~/.ssh ]; then
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/*
fi

source "$ZSH/oh-my-zsh.sh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
