FROM ubuntu:focal-20220113

# set default input arguments
ARG TARGETPLATFORM
ARG LANGUAGE="en_US"
ARG ENCODING="UTF-8"
ARG S6_OVERLAY_VERSION="3.0.0.2"

# set default shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# set environment variables
ENV HOME="/root" \
    TERM="xterm" \
    LANG=${LANGUAGE}.${ENCODING} \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6_GLOBAL_PATH="/command:/usr/bin:/usr/sbin:/usr/local/sbin:/usr/local/bin"
ENV S6_GLOBAL_PATH="${S6_GLOBAL_PATH}:/sbin:/bin"

# set up packages, locale and non-root user
RUN export DEBIAN_FRONTEND='noninteractive' && \
    echo '###### Set up packages' && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install --no-install-recommends --no-install-suggests -y \
      apt-utils \
      ca-certificates \
      curl \
      locales \
      tzdata \
      xz-utils && \
    echo '###### Set up locale' && \
    localedef \
      -i ${LANGUAGE} -c -f ${ENCODING} \
      -A /usr/share/locale/locale.alias \
      ${LANG} && \
    echo '###### Set up user' && \
    mkdir /config && \
    useradd \
      -U -d /config \
      -s /bin/false primary-user && \
    usermod -a -G users primary-user && \
    echo '###### Set up s6 overlay' && \
    PLATFORM_TRANSFORM='s/^linux\///' && \
    PLATFORM_TRANSFORM="${PLATFORM_TRANSFORM};s/^amd64/x86_64/" && \
    PLATFORM_TRANSFORM="${PLATFORM_TRANSFORM};s/^arm64/aarch64/" && \
    PLATFORM_TRANSFORM="${PLATFORM_TRANSFORM};s/^arm\/v7/armhf/" && \
    ARCH=$(echo ${TARGETPLATFORM} | sed "${PLATFORM_TRANSFORM}") && \
    echo "###### Platform mapping s6 overlay: ${TARGETPLATFORM} => ${ARCH}" && \
    URL='https://github.com/just-containers/s6-overlay/releases/download' && \
    URL="${URL}/v${S6_OVERLAY_VERSION}" && \
    curl -sSf \
      -o /tmp/s6-overlay-noarch.tar.xz \
      -L "${URL}/s6-overlay-noarch-${S6_OVERLAY_VERSION}.tar.xz" && \
    curl -sSf \
      -o /tmp/s6-overlay-arch.tar.xz \
      -L "${URL}/s6-overlay-${ARCH}-${S6_OVERLAY_VERSION}.tar.xz" && \
    curl -sSf \
      -o /tmp/s6-overlay-symlinks-noarch.tar.xz \
      -L "${URL}/s6-overlay-symlinks-noarch-${S6_OVERLAY_VERSION}.tar.xz" && \
    curl -sSf \
      -o /tmp/s6-overlay-symlinks-arch.tar.xz \
      -L "${URL}/s6-overlay-symlinks-arch-${S6_OVERLAY_VERSION}.tar.xz" && \
    curl -sSf \
      -o /tmp/syslogd-overlay-noarch.tar.xz \
      -L "${URL}/syslogd-overlay-noarch-${S6_OVERLAY_VERSION}.tar.xz" && \
    tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-arch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-symlinks-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-symlinks-arch.tar.xz && \
    tar -C / -Jxpf /tmp/syslogd-overlay-noarch.tar.xz && \
    echo "${S6_GLOBAL_PATH}" > /etc/s6-overlay/config/global_path && \
    echo '###### Clean up' && \
    apt-get autoremove --purge -y curl ca-certificates xz-utils && \
    apt-get autoremove --purge -y && \
    apt-get autoclean && \
    apt-get clean && \
    rm -rf \
      /var/lib/apt/lists/* \
      /var/tmp/* \
      /var/log/* \
      /tmp/*

# add local files
COPY root/ /

# entry (s6 overlays)
ENTRYPOINT ["/init"]

# set up config volume
VOLUME /config

# labels
LABEL maintainer devpow112 \
      org.opencontainers.image.authors devpow112 \
      org.opencontainers.image.description \
	      "Ubuntu docker container for use as base for other containers." \
      org.opencontainers.image.documentation \
        https://github.com/devpow112/docker-base-ubuntu#readme \
      org.opencontainers.image.licenses MIT \
      org.opencontainers.image.source \
        https://github.com/devpow112/docker-base-ubuntu \
      org.opencontainers.image.title "Docker Ubuntu (Base)" \
      org.opencontainers.image.url \
        https://github.com/devpow112/docker-base-ubuntu \
      org.opencontainers.image.vendor devpow112
