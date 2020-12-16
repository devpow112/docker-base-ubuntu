FROM ubuntu:focal-20201106

# set input arguments to defaults
ARG TARGETPLATFORM
ARG LANGUAGE="en_US"
ARG ENCODING="UTF-8"
ARG S6_OVERLAY_VERSION="2.1.0.2"

# set basic environment variables
ENV HOME="/root" \
    TERM="xterm"

# set up directories and volumes
RUN mkdir /config
VOLUME /config

# upgrade and install packages, set up locale and set up non-root user
RUN export DEBIAN_FRONTEND='noninteractive' && \
    echo '#### Upgrade and install packages ####' && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install --no-install-recommends -y \
      apt-utils \
      ca-certificates \
      curl \
      locales \
      tzdata && \
    echo '#### Set up s6 overlay ####' && \
    TRANSFORM_PATTERN='s/^linux\///;s/^arm64/aarch64/;s/^arm\/v7/armhf/' && \
    S6_OVERLAY_ARCH=$(echo ${TARGETPLATFORM} | sed ${TRANSFORM_PATTERN}) && \
    URL='https://github.com/just-containers/s6-overlay/releases/download/' && \
    URL="${URL}v${S6_OVERLAY_VERSION}/" && \
    URL="${URL}s6-overlay-${S6_OVERLAY_ARCH}-installer" && \
    curl -sSfo /tmp/s6-overlay-installer -L ${URL} && \
    chmod u+x /tmp/s6-overlay-installer && \
    /tmp/s6-overlay-installer / && \
    echo '#### Set up locale ####' && \
    localedef \
      -i ${LANGUAGE} -c -f ${ENCODING} \
      -A /usr/share/locale/locale.alias \
      ${LANGUAGE}.${ENCODING} && \
    echo '#### Set up non-root user ####' && \
    useradd \
      -U -d /config \
      -s /bin/false primary-user && \
    usermod -a -G users primary-user && \
    echo '#### Clean up ####' && \
    apt-get autoremove --purge -y \
      ca-certificates \
      curl && \
    apt-get autoremove --purge -y && \
    apt-get clean && \
    rm -rf \
      /var/lib/apt/lists/* \
      /var/tmp/* \
      /tmp/*

# set language and s6 environment variables
ENV LANG=${LANGUAGE}.${ENCODING} \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6_KEEP_ENV=0

# add local files
COPY root/ /

# entry (s6 overlays)
ENTRYPOINT ["/init"]

# labels
LABEL maintainer devpow112
LABEL org.opencontainers.image.source \
      https://github.com/devpow112/docker-base-ubuntu
