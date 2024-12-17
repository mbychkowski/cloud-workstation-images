#!/usr/bin/env bash

echo "Setup user settings"

export PATH=$PATH:/usr
export HOME=/home/user
export CODEOSS_PATH="$HOME/.codeoss-cloudworkstations"
export CODEOSS_CONFIG_PATH="$HOME/.config/"
export SETTINGS_PATH="$CODEOSS_PATH/data/Machine/"

if [ -f /tmp/.codeoss-configs/starship.toml ]; then
  mv /tmp/.codeoss-configs/starship.toml $CODEOSS_CONFIG_PATH
fi

if [ "$(ls -A /tmp/.codeoss-configs | grep .*.json)" ]; then
  mkdir -p $SETTINGS_PATH

  mv /tmp/.codeoss-configs/*.json $SETTINGS_PATH

  chown -R user:user $CODEOSS_PATH
  chmod -R 755 $CODEOSS_PATH
fi

if [ -f /tmp/.codeoss-configs/.bashrc ]; then
  mv /tmp/.codeoss-configs/.* $HOME

  chown user:user "$HOME/.bashrc"
  chmod 644 "$HOME/.bashrc"
fi

echo "fc-cache -fv"
fc-cache -fv
