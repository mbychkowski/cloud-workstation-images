#!/bin/bash
# =============================================================================
# 000_bootstrap.sh — Bridge to persistent disk bootstrap
# =============================================================================
# Cloud Workstations mount the persistent disk over /home/user after the
# container starts, wiping out anything placed there during the Docker build.
# This script copies the baked-in configurations from /opt/workstation-skel/
# to the persistent disk on the very first boot of the workstation.
# =============================================================================

USER="user"
HOME_DIR="/home/user"
SKEL_DIR="/opt/workstation-skel"
SETUP="$HOME_DIR/boot/setup.sh"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [000_bootstrap] $1"; }

log "Checking persistent disk for bootstrap scripts..."

# 1. Seed the persistent disk on first boot
if [ ! -d "$HOME_DIR/boot" ] && [ -d "$SKEL_DIR" ]; then
    log "First boot detected (missing $HOME_DIR/boot). Copying skeleton files..."
    cp -r "$SKEL_DIR"/. "$HOME_DIR/"
    chown -R "$USER:$USER" "$HOME_DIR"
    log "Finished seeding persistent disk from $SKEL_DIR"
fi

# 2. Execute the persistent bootstrap script
if [ -f "$SETUP" ]; then
    log "Running persistent disk bootstrap: $SETUP"
    chmod +x "$SETUP"
    # Execute setup as root (sub-scripts use runuser where needed)
    bash "$SETUP" 2>&1
else
    log "WARNING: $SETUP not found — persistent disk bootstrap failed"
fi
