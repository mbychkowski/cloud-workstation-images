#!/bin/bash

echo "Setup user settings"

export HOME_DIR=/home/user
# Use the correct internal path for VS Code OSS Settings
export CODEOSS_SETTINGS_DIR="$HOME_DIR/.codeoss-cloudworkstations/data/Machine"
export USER_CONFIG_DIR="$HOME_DIR/.config"

if [ -f "/tmp/.codeoss-configs/starship.toml" ]; then
  mkdir -p $USER_CONFIG_DIR
  mv /tmp/.codeoss-configs/starship.toml $USER_CONFIG_DIR/
  chown -R user:user $USER_CONFIG_DIR
  chmod -R 755 $USER_CONFIG_DIR
fi

if [ -f "/tmp/.codeoss-configs/settings.json" ]; then
  mkdir -p $CODEOSS_SETTINGS_DIR
  mv /tmp/.codeoss-configs/settings.json $CODEOSS_SETTINGS_DIR/
  chown -R user:user "$HOME_DIR/.codeoss-cloudworkstations"
  chmod -R 755 "$HOME_DIR/.codeoss-cloudworkstations"
fi

rm -rf /tmp/.codeoss-configs
