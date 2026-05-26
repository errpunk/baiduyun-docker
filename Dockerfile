FROM jlesage/baseimage-gui:ubuntu-22.04-v4
LABEL maintainer="errpunk <alex.liutao@outlook.com>"
LABEL description="BaiduNetdisk for Synology NAS / 群晖 NAS 版百度网盘"

ENV LANG=zh_CN.UTF-8
ENV APP_NAME=baiduyun
ENV APP_VERSION=4.17.8
ENV USER_ID=0
ENV GROUP_ID=0
ENV ENABLE_CJK_FONT=1
ENV DISPLAY_WIDTH=1920
ENV DISPLAY_HEIGHT=1080
ENV DEBIAN_FRONTEND=noninteractive
ENV container=docker

# Expose ports for Web VNC (5800) and native VNC (5900)
EXPOSE 5800 5900

# Declare volumes for Synology NAS persistence
VOLUME ["/config", "/downloads"]

# Configure apt with retries for better network resilience
RUN echo 'Acquire::Retries "5";' > /etc/apt/apt.conf.d/80-retries && \
    echo 'Acquire::http::Timeout "120";' >> /etc/apt/apt.conf.d/80-retries && \
    echo 'Acquire::https::Timeout "120";' >> /etc/apt/apt.conf.d/80-retries

# Update and upgrade
RUN apt-get update -y && apt-get upgrade -y

# setup locale
RUN apt-get install -y locales && \
    sed -i -e 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen

# setup dependency
RUN apt-get install -y --no-install-recommends ca-certificates curl libgbm-dev libasound2-dev apt-utils libx11-xcb1 && \
    rm -rf /var/lib/apt/lists/*

# Pre-install CJK font files (unpack only, skip postinst)
# This creates /usr/share/fonts/truetype/wqy/ so the init script skips apt-get
RUN apt-get update && \
    cd /tmp && \
    apt-get download fonts-wqy-zenhei && \
    dpkg --unpack fonts-wqy-zenhei*.deb && \
    rm -f fonts-wqy-zenhei*.deb && \
    rm -rf /var/lib/apt/lists/*

# Download and install baiduyun deb
# Override BAIDUYUN_URL at build time: --build-arg BAIDUYUN_URL=<custom-url>
ARG BAIDUYUN_URL=https://8b7d8c-1993640123.antpcdn.com:19001/b/pkg-ant.baidu.com/issue/netdisk/LinuxGuanjia/${APP_VERSION}/baidunetdisk_${APP_VERSION}_amd64.deb

RUN curl -fsSL -o /tmp/baidunetdisk_${APP_VERSION}_amd64.deb "${BAIDUYUN_URL}" && \
    dpkg -i --force-depends /tmp/baidunetdisk_${APP_VERSION}_amd64.deb && \
    rm -f /tmp/baidunetdisk_${APP_VERSION}_amd64.deb && \
    apt-get update && \
    (apt-get install -f -y --no-install-recommends || \
     (for pkg in systemd libpam-systemd:amd64 dbus dbus-user-session; do \
        printf '#!/bin/sh\nexit 0\n' > /var/lib/dpkg/info/$pkg.postinst 2>/dev/null || true; \
      done; \
      dpkg --configure -a --force-depends || true; \
      dpkg --configure -a || true; \
      apt-get install -f -y --no-install-recommends || true)) && \
    rm -rf /var/lib/apt/lists/*

# fix statoverride to prevent container-init errors
RUN echo -n '' > /var/lib/dpkg/statoverride

# Health check for Synology NAS Container Manager
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -fsS http://localhost:5800/ > /dev/null || exit 1

COPY main-window-selection.xml /etc/openbox/main-window-selection.xml
COPY --chmod=755 startapp.sh /startapp.sh
