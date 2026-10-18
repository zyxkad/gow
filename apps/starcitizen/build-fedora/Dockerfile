ARG BASE_APP_IMAGE=ghcr.io/games-on-whales/base-app:fedora

######################################
# The issue here is, that you don't want to give privileged,
# but bwrap needs CAP_SYS_ADMIN.
# However if you explicitly give CAP_SYS_ADMIN, bwrap throws an error,
# because it detects that capabilities have been tempered with
FROM ${BASE_APP_IMAGE} AS bwrap-builder

WORKDIR /root
COPY ignore_capabilities.patch /root/
RUN dnf install -y git meson ca-certificates dpkg-dev && \
    git clone https://github.com/containers/bubblewrap && \
    cd bubblewrap && \
    ./ci/builddeps.sh && \
    patch -p1 < ../ignore_capabilities.patch && \
    meson _builddir && \
    meson compile -C _builddir

######################################

# hadolint ignore=DL3006
FROM ${BASE_APP_IMAGE}

RUN <<_INSTALL
#!/bin/bash
set -e

# Taken from https://docs.fedoraproject.org/en-US/gaming/proton/
dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
dnf config-manager setopt fedora-cisco-openh264.enabled=1

dnf install -y cabextract unzip

# Additional packages
dnf install -y NetworkManager bluez pkexec file pciutils lsb-release

_INSTALL

ARG LUG_HELPER_VERSION=v4.17
RUN <<_INSTALL_LUG
#!/bin/bash
set -eux

mkdir -p /usr/local/libexec/lug-helper/

curl -L -o - https://github.com/starcitizen-lug/lug-helper/releases/download/${LUG_HELPER_VERSION}/lug-helper-${LUG_HELPER_VERSION}.tar.gz | \
tar -C /usr/local/libexec/lug-helper/ --strip-components=1 -xzvf -

ln -s /usr/local/libexec/lug-helper/lug-helper.sh /usr/local/bin/lug-helper.sh
mkdir -p /home/retro/Games/star-citizen

_INSTALL_LUG

COPY --chmod=777 scripts/startup.sh /opt/gow/startup-app.sh
COPY --chmod=777 scripts/system-services.sh /etc/cont-init.d/system-services.sh
COPY --from=bwrap-builder --chmod=755 /root/bubblewrap/_builddir/bwrap /usr/bin/bwrap

ENV XDG_RUNTIME_DIR=/tmp/.X11-unix

ARG IMAGE_SOURCE
LABEL org.opencontainers.image.source=$IMAGE_SOURCE
