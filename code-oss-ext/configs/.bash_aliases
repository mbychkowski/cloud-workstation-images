# Any additional aliases that you would like to add to .bashrc

if [ -f ~/.ssh ]; then
  eval "$(ssh-agent -s)"
  ssh-add ~/.ssh/*
fi

eval "$(starship init bash)"
