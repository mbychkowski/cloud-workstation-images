FROM us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss:latest

# --------------
# PKG: Terraform
# --------------
RUN wget -O- https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null && \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null

# --------------
# PKG: GitHub CLI
# --------------
RUN wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
    sudo tee /usr/share/keyrings/githubcli-archive-keyring.gpg > /dev/null && \
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
    https://cli.github.com/packages stable main" | \
    sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

# --------------
# Update: System Packages, Dependencies
# --------------
RUN apt-get update && \
    apt-get upgrade -y && \
    apt install -y \
    build-essential \
    ca-certificates \
    gh \
    git-lfs \
    gnupg \
    lsb-release \
    python3-venv \
    software-properties-common \
    terraform \
    jq \
    ripgrep \
    fd-find \
    htop \
    tree \
    zsh

# --------------
# shell: zsh & Plugins
# --------------
RUN git clone https://github.com/zsh-users/zsh-autosuggestions /opt/zsh/zsh-autosuggestions && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting /opt/zsh/zsh-syntax-highlighting && \
    echo 'source /opt/zsh/zsh-autosuggestions/zsh-autosuggestions.zsh' >> /etc/zsh/zshrc && \
    echo 'source /opt/zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' >> /etc/zsh/zshrc && \
    echo 'export NVM_DIR="/opt/nvm"' >> /etc/zsh/zshrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> /etc/zsh/zshrc && \
    echo 'eval "$(starship init zsh)"' >> /etc/zsh/zshrc

# --------------
# Customize: Make things pretty
# --------------
RUN curl -sS https://starship.rs/install.sh | sh -s -- -y

# --------------
# NPM: Packages
# --------------
RUN npm install -g \
    next \
    vite \
    react-scripts@latest \
    @google/gemini-cli \
    @anthropic-ai/claude-code \
    playwright

# --------------
# Playwright Headless Browsers & OS Dependencies
# --------------
ENV PLAYWRIGHT_BROWSERS_PATH=/opt/playwright
RUN npx playwright install --with-deps chromium

# --------------
# Toolchains (Python, Node/NVM, Rust, Go, GCP)
# --------------
ENV RUSTUP_HOME=/opt/rust \
    CARGO_HOME=/opt/rust/cargo \
    BUN_INSTALL=/opt/bun \
    UV_INSTALL_DIR=/opt/uv \
    NVM_DIR=/opt/nvm

ENV PATH="/usr/local/go/bin:${CARGO_HOME}/bin:${BUN_INSTALL}/bin:${UV_INSTALL_DIR}/bin:${PATH}"

RUN mkdir -p $NVM_DIR && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash && \
    . $NVM_DIR/nvm.sh && nvm install 22 && nvm alias default 22 && nvm use default && \
    ln -sf $(which node) /usr/local/bin/node && \
    ln -sf $(which npm) /usr/local/bin/npm && \
    ln -sf $(which npx) /usr/local/bin/npx && \
    GO_VERSION=$(curl -fsSL "https://go.dev/VERSION?m=text" | grep -o '^go[0-9]*\.[0-9]*\.[0-9]*' | head -1) && \
    curl -fsSLO "https://dl.google.com/go/${GO_VERSION}.linux-amd64.tar.gz" && \
    tar -C /usr/local -xzf "${GO_VERSION}.linux-amd64.tar.gz" && \
    rm "${GO_VERSION}.linux-amd64.tar.gz" && \
    curl -LsSf https://astral.sh/uv/install.sh | sh && \
    curl -fsSL https://bun.sh/install | bash && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path && \
    curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64 && \
    install skaffold /usr/local/bin/ && \
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
    chmod 700 get_helm.sh && \
    ./get_helm.sh && \
    rm skaffold kubectl get_helm.sh

# --------------
# EXTENSIONS
# --------------
RUN EXTENSIONS=" \
    dracula-theme/theme-dracula \
    vscode-icons-team/vscode-icons \
    hashicorp/terraform \
    golang/go \
    ms-python/python \
    dbaeumer/vscode-eslint \
    RooVeterinaryInc/roo-cline \
    ms-playwright/playwright \
    googlecloudtools/cloudcode \
    ms-azuretools/vscode-docker \
    rust-lang/rust-analyzer \
    eamodio/gitlens \
    usernamehw/errorlens \
    esbenp/prettier-vscode \
    " && \
    for ext in $EXTENSIONS; do \
        ext_name=$(echo $ext | cut -d'/' -f2) && \
        wget -qO ${ext_name}.vsix $(curl -s https://open-vsx.org/api/$ext | jq -r '.files.download') && \
        unzip -q ${ext_name}.vsix "extension/*" && \
        mv extension /opt/code-oss/extensions/${ext_name} && \
        rm ${ext_name}.vsix; \
    done

# --------------
# APT: Cleanup
# --------------
RUN apt clean all

# --------------
# VSCODE: Settings & Extenstions
# --------------
RUN mkdir /tmp/.codeoss-configs
COPY ./configs/* /tmp/.codeoss-configs/
COPY ./scripts/configure_workstation_settings.sh /etc/workstation-startup.d/300_configure-ws-settings.sh
RUN chmod +x /etc/workstation-startup.d/300_configure-ws-settings.sh
