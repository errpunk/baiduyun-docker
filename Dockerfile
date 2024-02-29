FROM jlesage/baseimage-gui:ubuntu-22.04-v4
LABEL maintainer="errpunk <alex.liutao@outlook.com>"

ENV LANG zh_CN.UTF-8
ENV APP_NAME        "baiduyun"
ENV APP_VERSION     "4.17.7"
ENV USER_ID         0
ENV GROUP_ID        0
ENV ENABLE_CJK_FONT 1
ENV DISPLAY_WIDTH   "1920"
ENV DISPLAY_HEIGHT  "1080"
ENV APT_SOURCE_HOST "mirrors.ustc.edu.cn"
ENV FILE_NAME       "/tmp/baiduyun_${APP_VERSION}.deb"
ENV FILE_URL        "https://issuepcdn.baidupcs.com/issue/netdisk/LinuxGuanjia/${APP_VERSION}/baidunetdisk_${APP_VERSION}_amd64.deb"
ENV DEBIAN_FRONTEND noninteractive

# setup apt source
RUN sed -i "s@//.*.ubuntu.com@//${APT_SOURCE_HOST}@g" /etc/apt/sources.list
RUN apt-get update -y && apt-get upgrade -y

# setup locale
RUN apt-get install -y locales && \
    sed -i -e 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen

# setup dependency
RUN apt-get install -y curl libgbm-dev libasound2-dev apt-utils

# download baiduyun deb file, retry if download failed
RUN while true; do \
        curl -w "%{http_code}" -o "${FILE_NAME}" -s -L "${FILE_URL}" | grep -q 200 && break; \
        sleep 1; \
    done
RUN dpkg -i /tmp/baiduyun_${APP_VERSION}.deb || apt --fix-broken install -y

# workaround for error: "unknown system group 'messagebus' in statoverride file; the system group got removed"
# don't really know why this happen, welcome to PR
RUN echo -n '' > /var/lib/dpkg/statoverride

COPY --chmod=755 startapp.sh /startapp.sh