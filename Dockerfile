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
RUN apt-get install -y --no-install-recommends curl libgbm-dev libasound2-dev apt-utils && \
    rm -rf /var/lib/apt/lists/*

# Copy pre-downloaded baiduyun deb file
COPY baidunetdisk_${APP_VERSION}_amd64.deb /tmp/baidunetdisk_${APP_VERSION}_amd64.deb

# Install baiduyun deb. Workaround systemd postinst failing in Docker by
# replacing its postinst script with a no-op if configuration fails.
RUN dpkg -i /tmp/baidunetdisk_${APP_VERSION}_amd64.deb || \
    (apt-get update && \
     { apt-get --fix-broken install -y --no-install-recommends || \
       (printf '#!/bin/sh\nexit 0\n' > /var/lib/dpkg/info/systemd.postinst && \
        dpkg --configure -a || true); })

# workaround for error: "unknown system group 'messagebus' in statoverride file; the system group got removed"
RUN echo -n '' > /var/lib/dpkg/statoverride

# Cleanup to reduce image size
RUN rm -f /tmp/baidunetdisk_${APP_VERSION}_amd64.deb && \
    rm -rf /var/lib/apt/lists/*

# Health check for Synology NAS Container Manager
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -fsS http://localhost:5800/ > /dev/null || exit 1

COPY --chmod=755 startapp.sh /startapp.sh
