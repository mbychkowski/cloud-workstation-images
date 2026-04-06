#!/bin/bash

echo "Setup user settings"

export PATH=$PATH:/usr
export HOME_DIR=/home/user
export CODEOSS_CONFIG_PATH="$HOME_DIR/.codeoss-cloudworkstations"
export CODEOSS_USER_CONFIG_PATH="$HOME_DIR/.config"
export CODEOSS_SETTINGS_CONFIG_PATH="$CODEOSS_CONFIG_PATH/data/Machine"

if [ -f "/tmp/.codeoss-configs/starship.toml" ]; then
  mkdir -p $CODEOSS_USER_CONFIG_PATH

  mv /tmp/.codeoss-configs/starship.toml $CODEOSS_USER_CONFIG_PATH/
fi

if [ -f "/tmp/.codeoss-configs/settings.json" ]; then
  mkdir -p $CODEOSS_SETTINGS_CONFIG_PATH

  mv /tmp/.codeoss-configs/settings.json $CODEOSS_SETTINGS_CONFIG_PATH/
fi

if [ -f "/tmp/.codeoss-configs/.bash_aliases" ]; then
  mv /tmp/.codeoss-configs/.bash_aliases $HOME_DIR/

  chown user:user $HOME_DIR/.bash_aliases
  chmod 755 $HOME_DIR/.bash_aliases
fi

if [ -f "/tmp/.codeoss-configs/.profile" ]; then
  mv /tmp/.codeoss-configs/.profile $HOME_DIR/

  chown user:user $HOME_DIR/.profile
  chmod 755 $HOME_DIR/.profile
fi

rm -rf /tmp/.codeoss-configs

chown -R user:user $CODEOSS_USER_CONFIG_PATH
chmod -R 755 $CODEOSS_USER_CONFIG_PATH

chown -R user:user $CODEOSS_CONFIG_PATH
chmod -R 755 $CODEOSS_CONFIG_PATH
