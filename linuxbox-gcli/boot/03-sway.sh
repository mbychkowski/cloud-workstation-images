#!/bin/bash
# =============================================================================
# 03-sway.sh — Sway desktop + wayvnc systemd services
# =============================================================================
# Creates sway-desktop and wayvnc services on the ephemeral root disk.
# Disables TigerVNC to free port 5901 for wayvnc.
# noVNC stays enabled (proxies port 80 -> localhost:5901).
# =============================================================================

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [03-sway] $1"; }

# --- Create sway-desktop.service ---
cat > /etc/systemd/system/sway-desktop.service << 'EOF'
[Unit]
Description=Sway desktop (headless for wayvnc)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=user
PAMName=login
Environment=WLR_BACKENDS=headless
Environment=WLR_LIBINPUT_NO_DEVICES=1
Environment=XDG_RUNTIME_DIR=/run/user/1000
Environment=XDG_SESSION_TYPE=wayland
Environment=LD_LIBRARY_PATH=/var/lib/nvidia/lib64
Environment=WLR_NO_HARDWARE_CURSORS=1
Environment=WLR_RENDERER=gles2
Environment=GBM_BACKEND=nvidia-drm
Environment=__GLX_VENDOR_LIBRARY_NAME=nvidia
Environment=TZ=America/Los_Angeles
ExecStartPre=/bin/mkdir -p /run/user/1000
ExecStartPre=/bin/chown 1000:1000 /run/user/1000
ExecStartPre=/bin/chmod 700 /run/user/1000
ExecStart=/bin/bash -l -c 'source /home/user/.nix-profile/etc/profile.d/nix.sh && exec /home/user/.nix-profile/bin/sway --unsupported-gpu'
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
log "Created sway-desktop.service"

# --- Create wayvnc.service ---
cat > /etc/systemd/system/wayvnc.service << 'EOF'
[Unit]
Description=wayvnc VNC server for Sway
After=sway-desktop.service
Requires=sway-desktop.service

[Service]
Type=simple
User=user
Environment=XDG_RUNTIME_DIR=/run/user/1000
Environment=WAYLAND_DISPLAY=wayland-1
ExecStartPre=/bin/sleep 3
ExecStart=/home/user/.nix-profile/bin/wayvnc --output=HEADLESS-1 0.0.0.0 5901
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
log "Created wayvnc.service"

# --- Enable services ---
ln -sf /etc/systemd/system/sway-desktop.service /etc/systemd/system/multi-user.target.wants/
ln -sf /etc/systemd/system/wayvnc.service /etc/systemd/system/multi-user.target.wants/
log "Enabled sway-desktop and wayvnc services"

# --- Create ws-autolaunch.service (launches apps on workspaces after Sway) ---
cat > /etc/systemd/system/ws-autolaunch.service << 'EOF'
[Unit]
Description=Auto-launch apps on Sway workspaces
After=wayvnc.service
Requires=sway-desktop.service

[Service]
Type=oneshot
ExecStart=/bin/bash /home/user/boot/08-workspaces.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
ln -sf /etc/systemd/system/ws-autolaunch.service /etc/systemd/system/multi-user.target.wants/
log "Created ws-autolaunch.service (runs 08-workspaces.sh after Sway)"

# --- Disable and mask TigerVNC ---
rm -f /etc/systemd/system/multi-user.target.wants/tigervnc.service
# Must rm first — ln -sf fails on overlay fs with regular files
rm -f /etc/systemd/system/tigervnc.service
ln -s /dev/null /etc/systemd/system/tigervnc.service
pkill -f Xtigervnc 2>/dev/null || true
log "Disabled and masked TigerVNC (port 5901 now served by wayvnc)"
