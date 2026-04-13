#!/bin/bash
# =============================================================================
# Master Bootstrap Script — Cloud Workstation
# =============================================================================
# Single entry point for all workstation setup logic.
# Called from /etc/workstation-startup.d/000_bootstrap.sh on boot.
# Sources all numbered sub-scripts from ~/boot/ in order.
# =============================================================================

set -euo pipefail

BOOT_DIR="/home/user/boot"
LOG_TAG="ws-bootstrap"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$LOG_TAG] $1"; }

log "Starting workstation bootstrap from $BOOT_DIR"

for script in "$BOOT_DIR"/[0-9][0-9]*.sh; do
    [ -f "$script" ] || continue
    script_name="$(basename "$script")"
    # Skip 08-workspaces.sh — it runs as a systemd service (ws-autolaunch) created by 03-sway.sh
    if [ "$script_name" = "08-workspaces.sh" ]; then
        log "Skipping $script_name (runs via systemd after Sway)"
        continue
    fi

    log "Running $script_name..."
    if bash "$script" 2>&1; then
        log "Completed $script_name"
    else
        log "WARNING: $script_name exited with code $?"
    fi
done

log "Bootstrap complete"
