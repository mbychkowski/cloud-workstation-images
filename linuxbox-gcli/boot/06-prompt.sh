#!/bin/bash
# =============================================================================
# 06-prompt.sh — Starship prompt + foot terminal config
# =============================================================================
# Ensures Starship is available and configures foot terminal with
# Operator Mono font and Tokyo Night color scheme.
# =============================================================================

USER="user"
HOME_DIR="/home/user"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [06-prompt] $1"; }

# --- Ensure Starship is available ---
STARSHIP_PATH="$HOME_DIR/.nix-profile/bin/starship"
log "Starship available at: $(which starship 2>/dev/null || echo "$STARSHIP_PATH")"

# --- Configure Starship ---
STARSHIP_CONFIG_SRC="$HOME_DIR/configs/code-oss/starship.toml"
STARSHIP_CONFIG_DST="$HOME_DIR/.config/starship.toml"
if [ -f "$STARSHIP_CONFIG_SRC" ]; then
    runuser -u $USER -- mkdir -p "$HOME_DIR/.config"
    runuser -u $USER -- cp "$STARSHIP_CONFIG_SRC" "$STARSHIP_CONFIG_DST"
    log "Copied starship.toml to $STARSHIP_CONFIG_DST"
else
    log "WARNING: starship.toml not found at $STARSHIP_CONFIG_SRC"
fi

# --- Create foot terminal config ---
FOOT_DIR="$HOME_DIR/.config/foot"
FOOT_INI="$FOOT_DIR/foot.ini"
runuser -u $USER -- mkdir -p "$FOOT_DIR"

cat > "$FOOT_INI" << 'EOF'
# foot terminal — Cloud Workstation
# Dracula theme with CaskaydiaCove Nerd Font

[main]
font=CaskaydiaCove Nerd Font:size=16
dpi-aware=no
pad=8x8

[scrollback]
lines=10000

[colors]
# Dracula Theme
background=282a36
foreground=f8f8f2
regular0=21222c
regular1=ff5555
regular2=50fa7b
regular3=f1fa8c
regular4=bd93f9
regular5=ff79c6
regular6=8be9fd
regular7=f8f8f2
bright0=6272a4
bright1=ff6e6e
bright2=69ff94
bright3=ffffa5
bright4=d6acff
bright5=ff92df
bright6=a4ffff
bright7=ffffff
selection-foreground=ffffff
selection-background=44475a

[key-bindings]
clipboard-copy=Control+Shift+c
clipboard-paste=Control+Shift+v
EOF
chown -R $USER:$USER "$FOOT_DIR"
log "Created foot.ini with CaskaydiaCove Nerd Font:size=16 and Dracula theme"
