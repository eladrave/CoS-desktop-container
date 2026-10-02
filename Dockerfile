# syntax=docker/dockerfile:1.7
# check=skip=InvalidBaseImagePlatform

ARG UBUNTU_BASE_IMAGE="ubuntu@sha256:561618e2c15bf2397621dd04f96926663a3b5616c189cf7e38db7e82f5c538ea"
ARG DESKTOP_ARCH="amd64"
ARG INSTALL_CRD="1"

FROM --platform=$TARGETPLATFORM ${UBUNTU_BASE_IMAGE}

ARG DESKTOP_ARCH
ARG INSTALL_CRD

ARG COS_VERSION="2.1.25"
ARG COS_DEB_URL="https://github.com/totec448-spec/chat-on-steroids/releases/download/v2.1.25/Chat-On-Steroids-Linux-x64.deb"
ARG COS_DEB_SHA256="26fa6302e25ab9630bb332e91a8f342f209abc310e36bdf989bdbf88bae95a4e"

ARG CHROME_VERSION="152.0.7977.64-1"
ARG CHROME_DEB_URL="https://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_152.0.7977.64-1_amd64.deb"
ARG CHROME_DEB_SHA256="4eae0736a812d9bc851cd2937f7af00e47dbaf8305845eed452703ff009873c7"

ARG CRD_VERSION="154.0.8037.11"
ARG CRD_DEB_URL="https://dl.google.com/linux/chrome-remote-desktop/deb/pool/main/c/chrome-remote-desktop/chrome-remote-desktop_154.0.8037.11_amd64.deb"
ARG CRD_DEB_SHA256="572dee08ca024f922a4c35b4b028abda348c9b54f12888eaaae53f6870dd5924"

LABEL org.opencontainers.image.title="cos-desktop" \
      org.opencontainers.image.description="Persistent Chat On Steroids desktop with Chrome, Xfce, noVNC, and optional Chrome Remote Desktop" \
      org.opencontainers.image.source="https://github.com/eladrave/CoS-desktop-container" \
      io.chat-on-steroids.version="${COS_VERSION}" \
      io.cos-desktop.image.arch="${DESKTOP_ARCH}" \
      io.google.chrome.version="${CHROME_VERSION}" \
      io.google.chrome-remote-desktop.enabled="${INSTALL_CRD}" \
      io.google.chrome-remote-desktop.version="${CRD_VERSION}"

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=Etc/UTC \
    HOME=/home/cos \
    USER=cos \
    LOGNAME=cos \
    SHELL=/bin/bash \
    XDG_CONFIG_HOME=/home/cos/.config \
    XDG_CACHE_HOME=/home/cos/.cache \
    XDG_DATA_HOME=/home/cos/.local/share \
    COS_DESKTOP_COS_VERSION=${COS_VERSION} \
    COS_DESKTOP_CHROME_VERSION=${CHROME_VERSION} \
    COS_DESKTOP_CRD_VERSION=${CRD_VERSION} \
    COS_DESKTOP_CRD_ENABLED=${INSTALL_CRD} \
    COS_DESKTOP_IMAGE_ARCH=${DESKTOP_ARCH} \
    LIBGL_ALWAYS_SOFTWARE=1

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        dbus \
        dbus-user-session \
        dbus-x11 \
        desktop-file-utils \
        fonts-dejavu-core \
        fonts-liberation \
        fonts-noto-color-emoji \
        git \
        gnome-keyring \
        jq \
        less \
        libpam-gnome-keyring \
        libsecret-1-0 \
        libsecret-tools \
        locales \
        openssh-client \
        novnc \
        procps \
        sudo \
        supervisor \
        thunar \
        tini \
        tzdata \
        util-linux \
        vim-tiny \
        wget \
        websockify \
        xdg-utils \
        xfce4-panel \
        xfce4-session \
        xfce4-settings \
        xfce4-terminal \
        xfconf \
        xfdesktop4 \
        xfwm4 \
        x11-xserver-utils \
        xauth \
        x11vnc \
        xvfb \
    && locale-gen en_US.UTF-8 \
    && groupadd --gid 10001 cos \
    && useradd --uid 10001 --gid 10001 --create-home --shell /bin/bash cos \
    && printf '%s\n' 'cos ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/cos-desktop \
    && chmod 0440 /etc/sudoers.d/cos-desktop \
    && visudo -cf /etc/sudoers

RUN set -eux; \
    package_dir="$(mktemp -d)"; \
    curl --fail --location --retry 5 --retry-all-errors --output "${package_dir}/cos.deb" "${COS_DEB_URL}"; \
    echo "${COS_DEB_SHA256}  ${package_dir}/cos.deb" | sha256sum --check --strict; \
    test "$(dpkg-deb -f "${package_dir}/cos.deb" Architecture)" = "${DESKTOP_ARCH}"; \
    curl --fail --location --retry 5 --retry-all-errors --output "${package_dir}/google-chrome.deb" "${CHROME_DEB_URL}"; \
    echo "${CHROME_DEB_SHA256}  ${package_dir}/google-chrome.deb" | sha256sum --check --strict; \
    test "$(dpkg-deb -f "${package_dir}/google-chrome.deb" Architecture)" = "${DESKTOP_ARCH}"; \
    if [ "${INSTALL_CRD}" = 1 ]; then \
      test "${DESKTOP_ARCH}" = amd64; \
      curl --fail --location --retry 5 --retry-all-errors --output "${package_dir}/chrome-remote-desktop.deb" "${CRD_DEB_URL}"; \
      echo "${CRD_DEB_SHA256}  ${package_dir}/chrome-remote-desktop.deb" | sha256sum --check --strict; \
    fi; \
    apt-get update; \
    set -- "${package_dir}/cos.deb" "${package_dir}/google-chrome.deb"; \
    if [ "${INSTALL_CRD}" = 1 ]; then set -- "$@" "${package_dir}/chrome-remote-desktop.deb"; fi; \
    apt-get install -y --no-install-recommends "$@"; \
    test -x /usr/bin/chat-on-steroids; \
    test "$(dpkg-query -W -f='${Version}' google-chrome-stable)" = "${CHROME_VERSION}"; \
    test "$(dpkg-query -W -f='${Architecture}' google-chrome-stable)" = "${DESKTOP_ARCH}"; \
    if [ "${INSTALL_CRD}" = 1 ]; then \
      test "$(dpkg-query -W -f='${Version}' chrome-remote-desktop)" = "${CRD_VERSION}"; \
      test -x /opt/google/chrome-remote-desktop/start-host; \
      mv /opt/google/chrome-remote-desktop/start-host /opt/google/chrome-remote-desktop/start-host.real; \
    fi; \
    rm -rf "${package_dir}" /var/lib/apt/lists/*

COPY start-host-wrapper.sh /usr/local/share/cos-desktop/start-host-wrapper
COPY chrome-remote-desktop.pam /etc/pam.d/chrome-remote-desktop
COPY chrome-remote-desktop-session /etc/chrome-remote-desktop-session
COPY supervisord.conf /etc/supervisor/conf.d/cos-desktop.conf
COPY entrypoint.sh /usr/local/sbin/cos-desktop-entrypoint
COPY start-xfce-session.sh /usr/local/sbin/start-cos-xfce-session
COPY run-session.sh /usr/local/sbin/run-cos-session
COPY run-local-desktop.sh /usr/local/sbin/run-cos-local-desktop
COPY run-crd.sh /usr/local/sbin/run-cos-crd
COPY configure-crd.sh /usr/local/bin/configure-chrome-remote-desktop
COPY run-x11vnc.sh /usr/local/sbin/run-cos-x11vnc
COPY run-novnc.sh /usr/local/sbin/run-cos-novnc
COPY healthcheck.sh /usr/local/sbin/cos-desktop-healthcheck
COPY cos-autostart.desktop /opt/cos-desktop-home-skel/.config/autostart/cos.desktop
COPY chrome-autostart.desktop /opt/cos-desktop-home-skel/.config/autostart/chrome.desktop

RUN chmod 0755 \
      /usr/local/sbin/cos-desktop-entrypoint \
      /usr/local/sbin/start-cos-xfce-session \
      /usr/local/sbin/run-cos-session \
      /usr/local/sbin/run-cos-local-desktop \
      /usr/local/sbin/run-cos-crd \
      /usr/local/bin/configure-chrome-remote-desktop \
      /usr/local/sbin/run-cos-x11vnc \
      /usr/local/sbin/run-cos-novnc \
      /usr/local/sbin/cos-desktop-healthcheck \
      /usr/local/share/cos-desktop/start-host-wrapper \
      /etc/chrome-remote-desktop-session \
    && chmod 0644 \
      /etc/pam.d/chrome-remote-desktop \
      /etc/supervisor/conf.d/cos-desktop.conf \
      /opt/cos-desktop-home-skel/.config/autostart/cos.desktop \
      /opt/cos-desktop-home-skel/.config/autostart/chrome.desktop \
    && install -d -o cos -g cos -m 0700 \
      /home/cos/.cache \
      /home/cos/.config \
      /home/cos/.config/autostart \
      /home/cos/.config/chrome-remote-desktop \
      /home/cos/.local/share \
      /home/cos/Downloads \
      /home/cos/Projects \
    && install -d -m 0755 /run/dbus /run/user \
    && install -d -o cos -g cos -m 0700 /run/user/10001 \
    && install -d -m 0700 /var/lib/cos-desktop-persistent \
    && ln -sf /usr/share/novnc/vnc.html /usr/share/novnc/index.html \
    && if [ "${INSTALL_CRD}" = 1 ]; then \
      install -o root -g root -m 0755 \
        /usr/local/share/cos-desktop/start-host-wrapper \
        /opt/google/chrome-remote-desktop/start-host; \
      chmod 0755 /opt/google/chrome-remote-desktop/start-host.real; \
    else \
      rm -f \
        /usr/local/share/cos-desktop/start-host-wrapper \
        /usr/local/sbin/run-cos-crd \
        /usr/local/bin/configure-chrome-remote-desktop \
        /etc/pam.d/chrome-remote-desktop \
        /etc/chrome-remote-desktop-session; \
    fi

WORKDIR /home/cos

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=5 \
  CMD ["/usr/local/sbin/cos-desktop-healthcheck"]

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/sbin/cos-desktop-entrypoint"]
