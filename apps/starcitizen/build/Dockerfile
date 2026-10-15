ARG BASE_APP_IMAGE

######################################
# The issue here is, that you don't want to give privileged,
# but bwrap needs CAP_SYS_ADMIN.
# However if you explicitly give CAP_SYS_ADMIN, bwrap throws an error,
# because it detects that capabilities have been tempered with
FROM ${BASE_APP_IMAGE} AS bwrap-builder

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /root
COPY ignore_capabilities.patch /root/
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends git meson ca-certificates dpkg-dev && \
    git clone https://github.com/containers/bubblewrap && \
    cd bubblewrap && \
    ./ci/builddeps.sh && \
    patch -p1 < ../ignore_capabilities.patch && \
    meson _builddir && \
    meson compile -C _builddir

######################################

# hadolint ignore=DL3006
FROM ${BASE_APP_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive

ARG REQUIRED_PACKAGES=" \
    dbus-daemon dbus-system-bus-common dbus-session-bus-common whoopsie network-manager bluez \
    ibus curl pkexec xz-utils zenity file xdg-user-dirs xdg-utils pciutils lsb-release mesa-utils \
    libfontconfig1 libfreetype6 \
    flatpak \
    linux-tools-generic linux-image-extra-virtual \
    cabextract unzip \
"

ARG AVOID_PACKAGES=" \
    nvidia-driver-libs- nvidia-vulkan-icd- \
"

RUN apt-get update -y && \
    apt-get install -y python3-six software-properties-common && \
    # \
    add-apt-repository multiverse && \
    apt-get update -y && \
    apt-get install -y $REQUIRED_PACKAGES $AVOID_PACKAGES && \
    # \
    # Fix steam updater UI font file \
    ln -s /usr/share/fonts/truetype/dejavu /usr/share/fonts/truetype/ttf-dejavu && \
    # \
    # Cleanup \
    apt-get remove -y python3-six software-properties-common && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*
# fix NetworkManager not picking up devices
RUN touch /etc/NetworkManager/conf.d/10-globally-managed-devices.conf

# skip annoying debian dialog
RUN rm /usr/bin/zenity && ln -s /usr/bin/true /usr/bin/zenity

# refresh system font cache. For font warnings on startup see: https://github.com/ValveSoftware/steam-runtime/issues/482
RUN fc-cache -f -v

COPY --chmod=777 scripts/startup.sh /opt/gow/startup-app.sh
COPY --chmod=777 scripts/system-services.sh /etc/cont-init.d/system-services.sh
COPY --from=bwrap-builder --chmod=755 /root/bubblewrap/_builddir/bwrap /usr/bin/bwrap

ARG LUG_HELPER_VERSION=v4.17
RUN mkdir -p /usr/local/libexec/lug-helper/ && \
 curl -L -o - https://github.com/starcitizen-lug/lug-helper/releases/download/${LUG_HELPER_VERSION}/lug-helper-${LUG_HELPER_VERSION}.tar.gz | \
 tar -C /usr/local/libexec/lug-helper/ --strip-components=1 -xzvf - && \
 ln -s /usr/local/libexec/lug-helper/lug-helper.sh /usr/local/bin/lug-helper.sh && \
 mkdir -p /home/retro/Games/star-citizen

RUN function id() { echo dummy id; } && \
 export -f id && \
 /usr/local/libexec/lug-helper/lug-helper.sh -g -i && \
 unset -f id

ENV XDG_RUNTIME_DIR=/tmp/.X11-unix

ARG IMAGE_SOURCE
LABEL org.opencontainers.image.source=$IMAGE_SOURCE
