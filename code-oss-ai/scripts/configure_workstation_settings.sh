#!/bin/bash

echo "Setup user settings"

export HOME_DIR=/home/user
# Use the correct internal path for VS Code OSS Settings
export CODEOSS_SETTINGS_DIR="$HOME_DIR/.codeoss-cloudworkstations/data/Machine"
export USER_CONFIG_DIR="$HOME_DIR/.config"

if [ -f "/tmp/.codeoss-configs/starship.toml" ]; then
  mkdir -p "$USER_CONFIG_DIR"
  if [ -f "$USER_CONFIG_DIR/starship.toml" ]; then
    cp /tmp/.codeoss-configs/starship.toml "$USER_CONFIG_DIR/starship.toml.default"
    echo "Existing Starship config found. Default saved to starship.toml.default"
  else
    mv /tmp/.codeoss-configs/starship.toml "$USER_CONFIG_DIR/starship.toml"
    echo "Installed default Starship configuration."
  fi
  chown -R user:user "$USER_CONFIG_DIR"
  chmod -R 755 "$USER_CONFIG_DIR"
fi

if [ -f "/tmp/.codeoss-configs/settings.json" ]; then
  mkdir -p "$CODEOSS_SETTINGS_DIR"
  if [ -f "$CODEOSS_SETTINGS_DIR/settings.json" ]; then
    cp /tmp/.codeoss-configs/settings.json "$CODEOSS_SETTINGS_DIR/settings.json.default"
    echo "Existing VS Code settings found. Default saved to settings.json.default"
  else
    mv /tmp/.codeoss-configs/settings.json "$CODEOSS_SETTINGS_DIR/settings.json"
    echo "Installed default VS Code preferences."
  fi
  chown -R user:user "$HOME_DIR/.codeoss-cloudworkstations"
  chmod -R 755 "$HOME_DIR/.codeoss-cloudworkstations"
fi

if [ -f "/tmp/.codeoss-configs/.zshrc" ]; then
  if [ -f "$HOME_DIR/.zshrc" ]; then
    cp /tmp/.codeoss-configs/.zshrc "$HOME_DIR/.zshrc.default"
    chown user:user "$HOME_DIR/.zshrc.default"
    chmod 644 "$HOME_DIR/.zshrc.default"
    echo "Existing .zshrc config found. Default saved to .zshrc.default"
  else
    mv /tmp/.codeoss-configs/.zshrc "$HOME_DIR/.zshrc"
    chown user:user "$HOME_DIR/.zshrc"
    chmod 644 "$HOME_DIR/.zshrc"
    echo "Installed default .zshrc shell configuration."
  fi
fi

rm -rf /tmp/.codeoss-configs

