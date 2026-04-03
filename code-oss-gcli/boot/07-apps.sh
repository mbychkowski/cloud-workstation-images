#!/bin/bash
# =============================================================================
# 07-apps.sh — Update apps to latest versions on boot
# =============================================================================
# Updates Gemini CLI (npm) and Nix apps (home-manager).
# Logs to ~/logs/app-update.log.
# =============================================================================

USER="user"
HOME_DIR="/home/user"
LOG_DIR="$HOME_DIR/logs"
LOG_FILE="$LOG_DIR/app-update.log"
NIX_SH="$HOME_DIR/.nix-profile/etc/profile.d/nix.sh"

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [07-apps] $1"
    echo "$msg"
    echo "$msg" >> "$LOG_FILE"
}

# Create log directory
runuser -u $USER -- mkdir -p "$LOG_DIR"

log "=== App update started ==="

# --- Update npm global packages (Gemini CLI) ---
log "Updating npm global packages..."
runuser -u $USER -- bash -c ". $NIX_SH && export NPM_CONFIG_PREFIX=$HOME_DIR/.npm-global && npm update -g @google/gemini-cli @anthropic-ai/claude-code" >> "$LOG_FILE" 2>&1
log "npm update complete"


# --- Update OpenCode (Go binary) ---
log "Updating OpenCode..."
runuser -u $USER -- bash -c "export GOROOT=$HOME_DIR/go && export GOPATH=$HOME_DIR/gopath && export PATH=\$GOROOT/bin:\$GOPATH/bin:\$PATH && go install github.com/opencode-ai/opencode@latest" >> "$LOG_FILE" 2>&1
log "OpenCode update complete"

# --- Update Nix channel + Home Manager (VSCode, IntelliJ, etc.) ---
log "Updating Nix channel and Home Manager..."
runuser -u $USER -- bash -c ". $NIX_SH && nix-channel --update && home-manager switch" >> "$LOG_FILE" 2>&1
log "Nix/Home Manager update complete"

# --- Configure VS Code (Settings & Extensions) ---
log "Configuring VS Code settings and extensions..."

# Copy settings.json to the correct User directory
VSCODE_USER_DIR="$HOME_DIR/.config/Code - OSS/User"
runuser -u $USER -- mkdir -p "$VSCODE_USER_DIR"
runuser -u $USER -- cp "$HOME_DIR/configs/code-oss/settings.json" "$VSCODE_USER_DIR/settings.json"

# Install Dracula Theme Extension
runuser -u $USER -- bash -c ". $NIX_SH && code --install-extension dracula-theme.theme-dracula --force" >> "$LOG_FILE" 2>&1
log "VS Code configuration complete"

log "=== App update complete ==="
