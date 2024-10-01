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
    python3.10-venv \
    software-properties-common \
    terraform

# --------------
# NPM: Packages
# --------------
RUN npm install -g \
    next

# --------------
# EXTENSIONS
# --------------
# Themes extension(s)
RUN wget -O theme-dracula.vsix $(curl -q https://open-vsx.org/api/dracula-theme/theme-dracula | jq -r '.files.download') && \
    unzip theme-dracula.vsix "extension/*" && \
    mv extension /opt/code-oss/extensions/theme-dracula
RUN wget -O night-owl.vsix $(curl -q https://open-vsx.org/api/sdras/night-owl | jq -r '.files.download') && \
    unzip night-owl.vsix "extension/*" && \
    mv extension /opt/code-oss/extensions/night-owl
# VSCode icons
RUN wget -O material-icon-theme.vsix $(curl -q https://open-vsx.org/api/PKief/material-icon-theme | jq -r '.files.download') && \
    unzip material-icon-theme.vsix "extension/*" && \
    mv extension /opt/code-oss/extensions/material-icon-theme
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
RUN wget -O python.vsix $(curl -q https://open-vsx.org/api/ms-python/python | jq -r '.files.download') && \
    unzip python.vsix "extension/*" && \
    mv extension /opt/code-oss/extensions/python
# TailwindCSS extension
RUN wget -O vscode-tailwindcss.vsix $(curl -q https://open-vsx.org/api/bradlc/vscode-tailwindcss | jq -r '.files.download') && \
    unzip vscode-tailwindcss.vsix "extension/*" && \
    mv extension /opt/code-oss/extensions/vscode-tailwindcss
# VSCode ESLint extension
RUN wget -O vscode-eslint.vsix $(curl -q https://open-vsx.org/api/dbaeumer/vscode-eslint | jq -r '.files.download') && \
    unzip vscode-eslint.vsix "extension/*" && \
    mv extension /opt/code-oss/extensions/vscode-eslint
# GraphQL syntax highlighting
RUN wget -O vscode-graphql-syntax.vsix $(curl -q https://open-vsx.org/api/GraphQL/vscode-graphql-syntax | jq -r '.files.download') && \
    unzip vscode-graphql-syntax.vsix "extension/*" && \
    mv extension /opt/code-oss/extensions/vscode-graphql-syntax

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
