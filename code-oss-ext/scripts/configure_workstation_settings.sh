#!/usr/bin/env bash

echo "Setup user settings"

export PATH=$PATH:/usr
export HOME=${HOME}
export CODEOSS_PATH="$HOME/.codeoss-cloudworkstations"
export SETTINGS_PATH="$CODEOSS_PATH/data/Machine/"

if [ -f "/tmp/.codeoss-configs/settings.json" ]; then
  mkdir -p $SETTINGS_PATH

  mv /tmp/.codeoss-configs/*.json $SETTINGS_PATH

fi

chmod -R 755 $CODEOSS_PATH
chown -R user:user $CODEOSS_PATH


if [[ -f "${HOME}/.zshrc" && -f "${HOME}/.p10k.zsh" ]]; then
    echo "ZSH already configured"
else
  curl -fsSL https://raw.githubusercontent.com/dracula/powerlevel10k/refs/heads/main/files/.p10k.zsh -0 $HOME/.p10k.zsh

  mv /tmp/.codeoss-configs/.zshrc $HOME

  chsh -s $(which zsh) user
fi

zsh -c "source  $ZSH/oh-my-zsh.sh"

chown -R user:user ${HOME}
chown -R user:user /opt/workstation
chmod -R 755 /opt/workstation
