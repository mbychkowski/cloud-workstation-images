# syntax=docker/dockerfile:1
FROM us-central1-docker.pkg.dev/cloud-workstations-images/predefined/base as novnc-builder

ARG NOVNC_BRANCH=v1.5.0
ARG WEBSOCKIFY_BRANCH=v0.12.0

WORKDIR /out

RUN git clone --quiet --depth 1 --branch $NOVNC_BRANCH https://github.com/novnc/noVNC.git && \
  cd noVNC/utils && \
  git clone  --quiet --depth 1 --branch $WEBSOCKIFY_BRANCH https://github.com/novnc/websockify.git

#######################################################
# End NoVNC Builder Container
#######################################################

# Main container build
FROM us-central1-docker.pkg.dev/cloud-workstations-images/predefined/base

# Use ARG to avoid apt-get warnings
ARG DEBIAN_FRONTEND=noninteractive

# --------------
# # Versions
# --------------
ENV NODE_VER=22.x

# Install and configure systemd.
RUN apt-get update && apt-get install -y \
  systemd && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* &&\
  ln -s /dev/null /etc/systemd/system/apache2.service && \
  ln -s /dev/null /etc/systemd/system/getty@tty1.service && \
  ln -s /dev/null /etc/systemd/system/ldconfig.service && \
  /sbin/ldconfig -Xv && \
  ln -s /dev/null /etc/systemd/system/systemd-modules-load.service && \
  ln -s /dev/null /etc/systemd/system/ssh.socket && \
  ln -s /dev/null /etc/systemd/system/ssh.service && \
  echo "d /run/sshd 0755 root root" > /usr/lib/tmpfiles.d/sshd.conf && \
  echo -e "x /run/docker.socket - - - - -\nx /var/run/docker.socket - - - - -" > /usr/lib/tmpfiles.d/docker.conf

# Install GNOME
RUN apt-get update && apt-get install -y \
    gnome-software \
    gnome-software-common \
    gnome-software-plugin-snap \
    libappstream-glib8 \
    libgd3 \
    colord \
    gnome-control-center \
    gvfs-backends \
    hplip \
    libgphoto2-6 \
    libsane1 \
    sane-utils \
    ubuntu-desktop-minimal && \
  apt-get remove -y gnome-initial-setup && \
  apt-get remove -y --purge cloud-init && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* && \
  chmod -x /usr/lib/ubuntu-release-upgrader/check-new-release-gtk

# Install Antigravity
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | gpg --dearmor -o /etc/apt/keyrings/antigravity-repo-key.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" | tee /etc/apt/sources.list.d/antigravity.list > /dev/null && \
    apt-get update && \
    apt-get install -y antigravity

# Install Google Chrome
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | tee /etc/apt/sources.list.d/google-chrome.list > /dev/null && \
    apt-get update && \
    apt-get install -y google-chrome-stable

# Divert the original Chrome executable to a new location and create a wrapper script.
# This ensures the fix persists even when the Chrome package is updated.
RUN dpkg-divert --add --rename --divert /usr/bin/google-chrome-stable.real /usr/bin/google-chrome-stable && \
    echo '#!/bin/bash' > /usr/bin/google-chrome-stable && \
    echo 'exec /usr/bin/google-chrome-stable.real --no-sandbox --no-zygote --disable-gpu --disable-dev-shm-usage "$@"' >> /usr/bin/google-chrome-stable && \
    chmod +x /usr/bin/google-chrome-stable

# Install Nix package manager
RUN mkdir -m 0755 /nix && \
    useradd -m -s /bin/bash nixuser && \
    chown nixuser /nix && \
    runuser -u nixuser -- bash -c 'curl -L https://nixos.org/nix/install | sh -s -- --no-daemon'

# Install Home Manager & User Packages via Nix
RUN runuser -u nixuser -- bash -c '. /home/nixuser/.nix-profile/etc/profile.d/nix.sh && \
    nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager && \
    nix-channel --update && \
    nix-shell "<home-manager>" -A install && \
    mkdir -p ~/.config/home-manager && \
    echo "{ config, pkgs, ... }: {" > ~/.config/home-manager/home.nix && \
    echo "  home.username = \"nixuser\";" >> ~/.config/home-manager/home.nix && \
    echo "  home.homeDirectory = \"/home/nixuser\";" >> ~/.config/home-manager/home.nix && \
    echo "  home.stateVersion = \"24.11\";" >> ~/.config/home-manager/home.nix && \
    echo "  nixpkgs.config.allowUnfree = true;" >> ~/.config/home-manager/home.nix && \
    echo "  programs.home-manager.enable = true;" >> ~/.config/home-manager/home.nix && \
    echo "  home.packages = with pkgs; [" >> ~/.config/home-manager/home.nix && \
    echo "    neovim tmux tree ffmpeg git gh curl wget htop ripgrep fd jq unzip terraform starship" >> ~/.config/home-manager/home.nix && \
    echo "    chromium google-chrome jetbrains.idea-oss" >> ~/.config/home-manager/home.nix && \
    echo "    zed-editor" >> ~/.config/home-manager/home.nix && \
    echo "    sway swaybg waybar foot wofi thunar grim slurp wl-clipboard clipman mako swaylock swayidle wayvnc" >> ~/.config/home-manager/home.nix && \
    echo "    nodejs_22" >> ~/.config/home-manager/home.nix && \
    echo "  ];" >> ~/.config/home-manager/home.nix && \
    echo "}" >> ~/.config/home-manager/home.nix && \
    home-manager switch'

# Stage Nix for persistence
RUN mkdir -p /opt/workstation-skel/nix && \
    cp -a /nix/* /opt/workstation-skel/nix/ && \
    mkdir -p /opt/workstation-skel/.nix-profile && \
    cp -a /home/nixuser/.nix-profile/* /opt/workstation-skel/.nix-profile/ || true

# Install VS Code
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg && \
    install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg && \
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | tee /etc/apt/sources.list.d/vscode.list > /dev/null && \
    rm -f packages.microsoft.gpg && \
    apt-get update && \
    apt-get install -y code

# Install Tailscale
RUN curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null && \
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list && \
    apt-get update && \
    apt-get install -y tailscale && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# --------------
# Update: System Packages, Dependencies
# --------------
RUN apt-get update && \
    apt-get upgrade -y && \
    apt install -y \
    build-essential \
    ca-certificates \
    git-lfs \
    gnupg \
    lsb-release \
    python3-venv \
    software-properties-common \
    dbus-x11 \
    tigervnc-common \
    tigervnc-scraping-server \
    tigervnc-standalone-server \
    tigervnc-xorg-extension \
    python3-numpy  && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Install TigerVNC and noVNC
COPY --from=novnc-builder /out/noVNC /opt/noVNC

# Merge assets into the container and fix permissions.
COPY .gemini /opt/workstation-skel/.gemini
COPY boot /opt/workstation-skel/boot
COPY configs /opt/workstation-skel/configs
COPY dev-fonts /opt/workstation-skel/dev-fonts
COPY assets/opt /opt
COPY assets/. /
RUN chmod -R 755 /etc && \
    chmod 644 /etc/passwd /etc/group /etc/shadow /etc/profile /etc/bash.bashrc /etc/environment && \
    chmod 755 /google/scripts/entrypoint.sh

# Run TigerVNC and noVNC as services.
RUN ln -s /etc/systemd/system/tigervnc.service /etc/systemd/system/multi-user.target.wants/ && \
  ln -s /etc/systemd/system/novnc.service /etc/systemd/system/multi-user.target.wants/ && \
  systemctl enable tigervnc && \
  systemctl enable novnc

# This is implicit when extending workstations predefined images, however we are
# including it in the sample to explicitly call-out we are overriding the
# default entrypoint when merging assets.
ENTRYPOINT ["/google/scripts/entrypoint.sh"]
