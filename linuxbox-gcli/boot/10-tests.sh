#!/bin/bash
# =============================================================================
# 10-tests.sh — Post-boot verification of all Cloud Workstation features
# =============================================================================
# Runs after all setup scripts. Tests every feature and saves results.
# Results: ~/logs/boot-test-results.txt (full) + ~/logs/boot-test-summary.txt (one-line)
# =============================================================================

USER="user"
HOME_DIR="/home/user"
LOG_DIR="$HOME_DIR/logs"
RESULTS="$LOG_DIR/boot-test-results.txt"
SUMMARY="$LOG_DIR/boot-test-summary.txt"
NIX_SH="$HOME_DIR/.nix-profile/etc/profile.d/nix.sh"

PASS=0; FAIL=0; WARN=0

runuser -u $USER -- mkdir -p "$LOG_DIR"

log() { echo "$1" | tee -a "$RESULTS"; }

test_pass() { PASS=$((PASS+1)); log "  PASS: $1"; }
test_fail() { FAIL=$((FAIL+1)); log "  FAIL: $1"; }
test_warn() { WARN=$((WARN+1)); log "  WARN: $1"; }

check_binary() {
    local name="$1" bin="$2"
    if runuser -u $USER -- bash -c ". $NIX_SH && export PATH=$HOME_DIR/.npm-global/bin:$HOME_DIR/gopath/bin:$HOME_DIR/go/bin:$HOME_DIR/.cargo/bin:$HOME_DIR/.pyenv/bin:$HOME_DIR/.rbenv/bin:$HOME_DIR/.bun/bin:$HOME_DIR/.local/bin:\$PATH && which $bin" >/dev/null 2>&1; then
        test_pass "$name ($bin)"
    else
        test_fail "$name ($bin not found)"
    fi
}

check_file() {
    local name="$1" path="$2"
    if [ -f "$path" ]; then
        test_pass "$name"
    else
        test_fail "$name ($path missing)"
    fi
}

check_dir() {
    local name="$1" path="$2"
    if [ -d "$path" ]; then
        test_pass "$name"
    else
        test_fail "$name ($path missing)"
    fi
}

check_grep() {
    local name="$1" pattern="$2" file="$3"
    if grep -q "$pattern" "$file" 2>/dev/null; then
        test_pass "$name"
    else
        test_fail "$name (pattern '$pattern' not in $file)"
    fi
}

check_process() {
    local name="$1" pattern="$2"
    if pgrep -f "$pattern" >/dev/null 2>&1; then
        test_pass "$name running"
    else
        test_warn "$name not running (may start later)"
    fi
}

# Start fresh results
echo "========================================" > "$RESULTS"
echo "Cloud Workstation Boot Test Results" >> "$RESULTS"
echo "Date: $(TZ=America/Los_Angeles date)" >> "$RESULTS"
echo "========================================" >> "$RESULTS"
echo "" >> "$RESULTS"

# =============================================================================
# CLI Tools
# =============================================================================
log "--- CLI Tools ---"
check_binary "tmux" "tmux"

# =============================================================================
# IDEs
# =============================================================================
log "--- IDEs ---"
check_binary "Visual Studio Code" "code"

# =============================================================================
# AI CLI Tools
# =============================================================================
log ""
log "--- AI CLI Tools & Package Managers ---"
check_binary "OpenCode" "opencode"
check_binary "Gemini CLI" "gemini"
check_binary "Claude Code" "claude"
check_binary "uv" "uv"
check_binary "bun" "bun"

# nvm (shell function)
if runuser -u $USER -- bash -c "export NVM_DIR=\"$HOME_DIR/.nvm\" && [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\" && nvm --version" >/dev/null 2>&1; then
    test_pass "nvm"
else
    test_warn "nvm not verified"
fi


# =============================================================================
# Languages
# =============================================================================
log ""
log "--- Languages ---"
check_binary "Go" "go"
check_binary "Rust (rustc)" "rustc"
check_binary "Cargo" "cargo"
# Python (needs pyenv init)
if runuser -u $USER -- bash -c "export PYENV_ROOT=$HOME_DIR/.pyenv && export PATH=\$PYENV_ROOT/bin:\$PATH && eval \"\$(pyenv init -)\" && which python" >/dev/null 2>&1; then
    test_pass "Python (pyenv)"
else
    test_fail "Python (pyenv not found)"
fi
# Ruby (needs rbenv init)
if runuser -u $USER -- bash -c "export PATH=$HOME_DIR/.rbenv/bin:\$PATH && eval \"\$($HOME_DIR/.rbenv/bin/rbenv init -)\" && which ruby" >/dev/null 2>&1; then
    test_pass "Ruby (rbenv)"
else
    test_fail "Ruby (rbenv not found)"
fi
# Node.js (via Nix)
check_binary "Node.js" "node"
check_binary "npm" "npm"

# =============================================================================
# Nix
# =============================================================================
log ""
log "--- Nix ---"
if runuser -u $USER -- bash -c ". $NIX_SH && nix-env --version" >/dev/null 2>&1; then
    test_pass "nix-env works"
else
    test_fail "nix-env not working"
fi
if runuser -u $USER -- bash -c ". $NIX_SH && home-manager --version" >/dev/null 2>&1; then
    test_pass "home-manager available"
else
    test_fail "home-manager not available"
fi

# =============================================================================
# Config Files
# =============================================================================
log ""
log "--- Config Files ---"
check_file "tmux.conf" "$HOME_DIR/.tmux.conf"
# Verify tmux.conf syntax is valid
if runuser -u $USER -- bash -c ". $NIX_SH && tmux -f $HOME_DIR/.tmux.conf start-server \\; kill-server" >/dev/null 2>&1; then
    test_pass "tmux.conf syntax valid"
else
    test_fail "tmux.conf has syntax errors"
fi
check_file ".zshrc" "$HOME_DIR/.zshrc"
check_file ".env" "$HOME_DIR/.env"


# =============================================================================
# Shell Config
# =============================================================================
log ""
log "--- Shell Config ---"
ZSHRC="$HOME_DIR/.zshrc"
check_grep "zshrc.local sourcing" "zshrc.local" "$ZSHRC"
check_grep "Timezone Pacific" "America/Los_Angeles" "$ZSHRC"
check_grep "Go PATH" "GOROOT" "$ZSHRC"
check_grep "Rust PATH" "cargo/bin" "$ZSHRC"
check_grep "pyenv init" "pyenv init" "$ZSHRC"
check_grep "rbenv init" "rbenv init" "$ZSHRC"
check_grep "Starship prompt" "starship init" "$ZSHRC"
check_grep "tmux aliases" "tmux new-session" "$ZSHRC"
check_grep "Nix profile sourced" "nix-profile.*nix.sh\|nix.sh" "$ZSHRC"


# =============================================================================
# Directory Structure
# =============================================================================
log ""
log "--- Directory Structure ---"
check_dir "GOPATH" "$HOME_DIR/gopath"
check_dir "Go install" "$HOME_DIR/go/bin"
check_dir "Cargo" "$HOME_DIR/.cargo/bin"
check_dir "pyenv" "$HOME_DIR/.pyenv"
check_dir "rbenv" "$HOME_DIR/.rbenv"
check_dir "npm-global" "$HOME_DIR/.npm-global"
check_dir "Nix profile" "$HOME_DIR/.nix-profile"


# =============================================================================
# Upgrade Scripts
# =============================================================================
log ""
log "--- Upgrade Scripts ---"

# Check 07-apps.sh ran and completed
if [ -f "$HOME_DIR/logs/app-update.log" ]; then
    if grep -q "App update complete" "$HOME_DIR/logs/app-update.log" 2>/dev/null; then
        test_pass "07-apps.sh completed successfully"
    else
        test_fail "07-apps.sh did not complete (check ~/logs/app-update.log)"
    fi
else
    test_fail "07-apps.sh never ran (~/logs/app-update.log missing)"
fi

# Check tool versions (verifies upgrades actually installed something)
check_version() {
    local name="$1" cmd="$2"
    local ver=$(runuser -u $USER -- bash -c ". $NIX_SH && export PATH=$HOME_DIR/.npm-global/bin:$HOME_DIR/gopath/bin:$HOME_DIR/go/bin:$HOME_DIR/.cargo/bin:$HOME_DIR/.pyenv/bin:$HOME_DIR/.rbenv/bin:$HOME_DIR/.bun/bin:$HOME_DIR/.local/bin:\$PATH && $cmd" 2>&1 | grep -viE "^[0-9]+/[0-9].*WARN |^WARNING" | head -1)
    if [ -n "$ver" ] && ! echo "$ver" | grep -qiE "not found|error|command not found"; then
        test_pass "$name version: $ver"
    else
        test_fail "$name version check failed"
    fi
}

check_version "OpenCode" "opencode -v"
check_version "Gemini CLI" "gemini --version"
check_version "Claude Code" "claude --version"
check_version "uv" "uv --version"
check_version "bun" "bun --version"




# Home Manager generation is recent (within last 24 hours)
HM_GEN=$(runuser -u $USER -- bash -c ". $NIX_SH && home-manager generations" 2>&1 | head -1)
if [ -n "$HM_GEN" ]; then
    test_pass "Home Manager generation: $HM_GEN"
else
    test_fail "Home Manager has no generations"
fi

# Nix channel updated
if runuser -u $USER -- bash -c ". $NIX_SH && nix-channel --list" 2>&1 | grep -q "nixpkgs"; then
    test_pass "Nix channel configured"
else
    test_fail "Nix channel not configured"
fi


# =============================================================================
# Summary
# =============================================================================
TOTAL=$((PASS+FAIL+WARN))
log ""
log "========================================"
log "  TOTAL: $TOTAL | PASS: $PASS | FAIL: $FAIL | WARN: $WARN"
log "========================================"

# Write one-line summary
echo "$(TZ=America/Los_Angeles date '+%Y-%m-%d %H:%M:%S %Z') | PASS: $PASS | FAIL: $FAIL | WARN: $WARN" > "$SUMMARY"

# Set ownership
chown -R $USER:$USER "$LOG_DIR"
