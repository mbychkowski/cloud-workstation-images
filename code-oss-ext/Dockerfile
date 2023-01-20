FROM us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss:latest

# --------------
# # Versions
# --------------
ENV NODE_VER=18.x

# --------------
# Update: System Packages, Dependencies
# --------------
RUN apt-get update && \
    apt-get upgrade -y && \
    apt install -y \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common

# --------------
# NPM: Packages
# --------------
RUN curl -sL https://deb.nodesource.com/setup_${NODE_VER} -o /tmp/nodesource_setup.sh && \
    bash /tmp/nodesource_setup.sh && \
    apt install -y nodejs

RUN yarn global add \
    webpack-cli \
    create-react-app \
    gatsby \
    next \
    gulp \
    @storybook/cli \
    @keystone-6/core

# --------------
# PKG: Github CLI
# --------------
RUN type -p curl >/dev/null || apt install curl -y && \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt update && \
    apt install gh -y

# --------------
# PKG: Terraform
# --------------
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - && \
    apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main" && \
    apt-get update && \
    apt install -y terraform

# --------------
# PKG: Helm
# --------------
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# --------------
# EXTENSIONS
# --------------
RUN wget https://open-vsx.org/api/dracula-theme/theme-dracula/2.24.2/file/dracula-theme.theme-dracula-2.24.2.vsix && \
    unzip dracula-theme.theme-dracula-2.24.2.vsix "extension/*" && \
    mv extension /opt/code-oss/extensions/theme-dracula
RUN wget https://open-vsx.org/api/sdras/night-owl/2.0.1/file/sdras.night-owl-2.0.1.vsix && \
    unzip sdras.night-owl-2.0.1.vsix "extension/*" && \
    mv extension /opt/code-oss/extensions/theme-night-owl
RUN wget https://open-vsx.org/api/redhat/vscode-yaml/1.11.0/file/redhat.vscode-yaml-1.11.0.vsix && \
    unzip redhat.vscode-yaml-1.11.0.vsix "extension/*" && \
    mv extension /opt/code-oss/extensions/yaml
RUN wget https://open-vsx.org/api/TabNine/tabnine-vscode/3.6.36/file/TabNine.tabnine-vscode-3.6.36.vsix && \
    unzip TabNine.tabnine-vscode-3.6.36.vsix "extension/*" && \
    mv extension /opt/code-oss/extensions/tabnine
RUN wget https://open-vsx.org/api/golang/Go/0.37.0/file/golang.go-0.37.0.vsix && \
    unzip golang.go-0.37.0.vsix "extension/*" && \
    mv extension /opt/code-oss/extensions/golang

# --------------
# APT: Cleanup
# --------------
RUN apt clean all

# --------------
# VSCODE: Settings & Extenstions
# --------------
RUN mkdir /tmp/.codeoss-configs
COPY ./configs /tmp/.codeoss-configs/
COPY ./scripts/300_configure-ws-settings.sh/etc/workstation-startup.d
RUN chmod 755 /etc/workstation-startup.d/300_configure-ws-settings.sh
