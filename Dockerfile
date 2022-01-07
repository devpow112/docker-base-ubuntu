FROM ubuntu:focal-20220105

# set default input arguments
ARG TARGETPLATFORM
ARG LANGUAGE="en_US"
ARG ENCODING="UTF-8"
ARG S6_OVERLAY_VERSION="2.2.0.3"

# set default shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# set environment variables
ENV HOME="/root" \
    TERM="xterm" \
    LANG=${LANGUAGE}.${ENCODING} \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6_KEEP_ENV=0

# set up packages, locale and non-root user
RUN export DEBIAN_FRONTEND='noninteractive' && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install --no-install-recommends -y \
      apt-utils \
      ca-certificates \
      curl \
      locales \
      tzdata && \
    localedef \
      -i ${LANGUAGE} -c -f ${ENCODING} \
      -A /usr/share/locale/locale.alias \
      ${LANG} && \
    mkdir /config && \
    useradd \
      -U -d /config \
      -s /bin/false primary-user && \
    usermod -a -G users primary-user && \
    PLATFORM_TRANSFORM="s/^linux\///;s/^arm64/aarch64/;s/^arm\/v7/armhf/" && \
    ARCH=$(echo ${TARGETPLATFORM} | sed "${PLATFORM_TRANSFORM}") && \
    URL='https://github.com/just-containers/s6-overlay/releases/download/' && \
    URL="${URL}v${S6_OVERLAY_VERSION}/s6-overlay-${ARCH}-installer" && \
    curl -sSfo /tmp/s6-overlay-installer -L "${URL}" && \
    chmod u+x /tmp/s6-overlay-installer && \
    /tmp/s6-overlay-installer / && \
    apt-get autoremove --purge -y curl ca-certificates && \
    apt-get autoremove --purge -y && \
    apt-get clean && \
    rm -rf \
      /var/lib/apt/lists/* \
      /var/tmp/* \
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
