FROM us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss:latest

# --------------
# # Versions
# --------------
ENV NODE_VER=20.x

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
    
# --------------
# Update: System Packages, Dependencies
# --------------
RUN apt-get update && \
    apt-get upgrade -y && \
    apt install -y \
    apt-transport-https \
    build-essential \
    ca-certificates \
    gh \
    git-lfs \
    gnupg \
    lsb-release \
    python3-venv \
    software-properties-common \
    terraform

# --------------
# Customize: Make things pretty
# --------------
RUN curl -sS https://starship.rs/install.sh | sh -s -- -y

COPY ./scripts/download_and_install_fonts.sh /tmp/
RUN chmod +x /tmp/download_and_install_fonts.sh
RUN /tmp/download_and_install_fonts.sh

# --------------
# NPM: Packages
# --------------
RUN npm install -g \
    next \
    react-scripts@latest

# --------------
# EXTENSIONS
# --------------
# Themes extension(s)
RUN wget -O theme-dracula.vsix $(curl -q https://open-vsx.org/api/dracula-theme/theme-dracula | jq -r '.files.download') && \
    unzip theme-dracula.vsix "extension/*" && \
    mv extension /opt/code-oss/extensions/theme-dracula
# VSCode icons
RUN wget -O vscode-icons.vsix $(curl -q https://open-vsx.org/api/vscode-icons-team/vscode-icons | jq -r '.files.download') \
    && unzip vscode-icons.vsix "extension/*" \
    && mv extension /opt/code-oss/extensions/vscode-icons
# Terraform extension
RUN wget -O terraform.vsix $(curl -q https://open-vsx.org/api/hashicorp/terraform/linux-x64 | jq -r '.files.download') && \
    unzip terraform.vsix "extension/*" && \
    mv extension /opt/code-oss/extensions/terraform
# Go extension
RUN wget -O go.vsix $(curl -q https://open-vsx.org/api/golang/go | jq -r '.files.download') && \
    unzip go.vsix "extension/*" && \
    mv extension /opt/code-oss/extensions/go
# Python extension
RUN wget -O python.vsix $(curl -q https://open-vsx.org/api/ms-python/python/2024.12.3 | jq -r '.files.download') && \
    unzip python.vsix "extension/*" && \
    mv extension /opt/code-oss/extensions/python
# VSCode ESLint extension
RUN wget -O vscode-eslint.vsix $(curl -q https://open-vsx.org/api/dbaeumer/vscode-eslint | jq -r '.files.download') && \
    unzip vscode-eslint.vsix "extension/*" && \
    mv extension /opt/code-oss/extensions/vscode-eslint

# --------------
# APT: Cleanup
# --------------
RUN apt clean all

# --------------
# VSCODE: Settings & Extenstions
# --------------
RUN mkdir /tmp/.codeoss-configs
COPY ./configs /tmp/.codeoss-configs/
COPY ./scripts/300_configure-ws-settings.sh /etc/workstation-startup.d
RUN chmod 755 /etc/workstation-startup.d/300_configure-ws-settings.sh
