#!/bin/bash
# setup-local.sh
# Replicates the code-oss-ai environment on a local Linux development machine.
# Run this script from the root of the cloud-workstation-images repository.

set -e

echo "=========================================================="
echo " Starting Local Environment Setup (code-oss-ai equivalent)"
echo "=========================================================="

# Ensure script is run from the correct directory (repo root or scripts folder)
if [ ! -d "code-oss-ai/configs" ]; then
    echo "Error: Run this script from the root of the cloud-workstation-images repository."
    echo "Example: ./code-oss-ai/scripts/setup-local.sh"
    exit 1
fi

REPO_ROOT="$(pwd)"

# ------------------------------------------------------------------------------
# 1. System Packages (APT)
# ------------------------------------------------------------------------------
echo ">> Installing APT packages..."
sudo apt-get update
sudo apt-get install -y \
    build-essential ca-certificates gh git-lfs gnupg lsb-release \
    python3-venv software-properties-common jq ripgrep fd-find \
    htop tree zsh neovim fzf bat tmux unzip curl wget

# ------------------------------------------------------------------------------
# 2. ZSH Configuration & Plugins
# ------------------------------------------------------------------------------
echo ">> Setting up ZSH..."

mkdir -p "$HOME/.zsh"

if [ ! -d "$HOME/.zsh/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.zsh/zsh-autosuggestions"
fi

if [ ! -d "$HOME/.zsh/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$HOME/.zsh/zsh-syntax-highlighting"
fi

# Copy and patch .zshrc
echo ">> Copying .zshrc..."
# First check if NVM is installed in XDG_CONFIG_HOME
NVM_PATH="$HOME/.nvm"
if [ -d "$HOME/.config/nvm" ]; then
    NVM_PATH="$HOME/.config/nvm"
fi

sed -e "s|/opt/zsh|$HOME/.zsh|g" \
    -e "s|/opt/nvm|$NVM_PATH|g" \
    "$REPO_ROOT/code-oss-ai/configs/.zshrc" > "$HOME/.zshrc"

# Append missing PATH entries for local toolchains to .zshrc
if ! grep -q "Local Toolchains PATHs" "$HOME/.zshrc"; then
cat << 'EOF' >> "$HOME/.zshrc"

# ------------------------------------------------------------------------------
# Local Toolchains PATHs
# ------------------------------------------------------------------------------
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="/usr/local/go/bin:$PATH"
EOF
fi

# ------------------------------------------------------------------------------
# 3. Starship Prompt
# ------------------------------------------------------------------------------
echo ">> Setting up Starship prompt..."
if ! command -v starship &> /dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

mkdir -p "$HOME/.config"
cp "$REPO_ROOT/code-oss-ai/configs/starship.toml" "$HOME/.config/starship.toml"

# ------------------------------------------------------------------------------
# 4. Toolchains (Node/NVM, Go, Rust, UV, Bun, Kubernetes tools)
# ------------------------------------------------------------------------------
echo ">> Installing Toolchains..."

# NVM & Node 22
export NVM_DIR="$HOME/.nvm"
if [ -d "$HOME/.config/nvm" ]; then
    export NVM_DIR="$HOME/.config/nvm"
elif [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
fi

# Load nvm for this script session
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install 22
nvm alias default 22
nvm use default

# Go
if [ ! -d "/usr/local/go" ]; then
    GO_VERSION=$(curl -fsSL "https://go.dev/VERSION?m=text" | grep -o '^go[0-9]*\.[0-9]*\.[0-9]*' | head -1)
    echo "Installing Go ${GO_VERSION}..."
    curl -fsSLO "https://dl.google.com/go/${GO_VERSION}.linux-amd64.tar.gz"
    sudo tar -C /usr/local -xzf "${GO_VERSION}.linux-amd64.tar.gz"
    rm "${GO_VERSION}.linux-amd64.tar.gz"
fi
export PATH="/usr/local/go/bin:$PATH"

# UV
if ! command -v uv &> /dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | env INSTALLER_NO_MODIFY_PATH=1 sh
fi
export PATH="$HOME/.local/bin:$PATH"

# Bun
if [ ! -d "$HOME/.bun" ]; then
    curl -fsSL https://bun.sh/install | bash
fi

# Rust
if ! command -v cargo &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
fi
export PATH="$HOME/.cargo/bin:$PATH"

# Terraform
if ! command -v terraform &> /dev/null; then
    TF_VERSION=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r -M '.current_version')
    curl -LO "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip"
    unzip "terraform_${TF_VERSION}_linux_amd64.zip"
    sudo install -o root -g root -m 0755 terraform /usr/local/bin/terraform
    rm terraform "terraform_${TF_VERSION}_linux_amd64.zip"
fi

# Skaffold
if ! command -v skaffold &> /dev/null; then
    curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64
    sudo install skaffold /usr/local/bin/
    rm skaffold
fi

# Kubectl
if ! command -v kubectl &> /dev/null; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
fi

# Helm
if ! command -v helm &> /dev/null; then
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
    rm get_helm.sh
fi

# ------------------------------------------------------------------------------
# 5. Global NPM Packages & Playwright
# ------------------------------------------------------------------------------
echo ">> Installing Global NPM Packages..."
npm install -g \
    next \
    vite \
    react-scripts@latest \
    @google/gemini-cli \
    @anthropic-ai/claude-code \
    playwright

echo ">> Installing Playwright browsers..."
# Install playwright dependencies locally via sudo npx
sudo env "PATH=$PATH" npx playwright install-deps chromium
npx playwright install chromium

# ------------------------------------------------------------------------------
# 6. VS Code Extensions & Settings
# ------------------------------------------------------------------------------
echo ">> Configuring VS Code..."

VSCODE_USER_DIR="$HOME/.config/Code/User"
mkdir -p "$VSCODE_USER_DIR"
cp "$REPO_ROOT/code-oss-ai/configs/settings.json" "$VSCODE_USER_DIR/settings.json"

if command -v code &> /dev/null; then
    echo ">> Installing VS Code Extensions..."
    EXTENSIONS=(
        "dracula-theme.theme-dracula"
        "vscode-icons-team.vscode-icons"
        "hashicorp.terraform"
        "golang.go"
        "ms-python.python"
        "dbaeumer.vscode-eslint"
        "RooVeterinaryInc.roo-cline"
        "ms-playwright.playwright"
        "googlecloudtools.cloudcode"
        "ms-azuretools.vscode-docker"
        "rust-lang.rust-analyzer"
        "eamodio.gitlens"
        "usernamehw.errorlens"
        "esbenp.prettier-vscode"
        "anthropic.claude-code"
    )

    for ext in "${EXTENSIONS[@]}"; do
        code --install-extension "$ext" --force
    done
else
    echo ">> Warning: 'code' command not found. Skipping VS Code extensions installation."
    echo "Please install VS Code to complete extension setup."
fi

# ------------------------------------------------------------------------------
# 7. Set Default Shell to ZSH
# ------------------------------------------------------------------------------
echo ">> Setting default shell to ZSH..."
if command -v zsh &> /dev/null; then
    CURRENT_SHELL=$(basename "$SHELL")
    if [ "$CURRENT_SHELL" != "zsh" ]; then
        echo "Changing default shell to $(which zsh)..."
        sudo chsh -s "$(which zsh)" "$USER" || sudo usermod -s "$(which zsh)" "$USER" || echo "Warning: Could not change default shell. Run 'chsh -s \$(which zsh)' manually."
    else
        echo "Default shell is already ZSH."
    fi

    # Fallback: ensure interactive bash shells switch to zsh automatically
    if ! grep -q "# Switch to ZSH" "$HOME/.bashrc"; then
        echo ">> Adding ZSH fallback to .bashrc..."
        cat << 'EOF' >> "$HOME/.bashrc"

# Switch to ZSH for interactive shells if it's not the current shell
if [ -t 1 ] && [ -n "$PS1" ] && [ "$SHELL" != "$(which zsh)" ]; then
    export SHELL="$(which zsh)"
    exec "$(which zsh)" -l
fi
EOF
    fi
fi

# Ensure VSCode settings are also applied if using Code - OSS
CODE_OSS_DIR="$HOME/.config/Code - OSS/User"
if [ -d "$HOME/.config/Code - OSS" ] || command -v code-oss &> /dev/null; then
    mkdir -p "$CODE_OSS_DIR"
    cp "$REPO_ROOT/code-oss-ai/configs/settings.json" "$CODE_OSS_DIR/settings.json"
fi

echo "=========================================================="
echo " Setup Complete!"
echo " Please fully close and reopen your terminal app (or restart your Linux container) to apply the ZSH shell change."
echo " Alternatively, type 'zsh' to start it temporarily."
echo "=========================================================="
