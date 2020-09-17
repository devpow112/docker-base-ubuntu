FROM ubuntu:focal-20200916
LABEL maintainer devpow112
LABEL org.opencontainers.image.source https://github.com/devpow112/docker-base-ubuntu

# set input arguments to defaults
ARG S6_OVERLAY_VERSION="2.0.0.1"
ARG S6_OVERLAY_ARCH="amd64"
ARG S6_OVERLAY_URL="https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_OVERLAY_ARCH}.tar.gz"
ARG LANGUAGE="en_US"
ARG ENCODING="UTF-8"
ARG DEBIAN_FRONTEND="noninteractive"

# set basic environment variables
ENV HOME="/root" \
    TERM="xterm"

# setup directories/volumes
RUN mkdir /config
VOLUME /config

# download s6 overlays
ADD ${S6_OVERLAY_URL} /tmp

# setup packages, language and non root user
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
      apt-utils \
      locales \
      tzdata && \
    localedef \
      -i ${LANGUAGE} -c -f ${ENCODING} \
      -A /usr/share/locale/locale.alias \
      ${LANGUAGE}.${ENCODING} && \
    tar xfz \
      /tmp/s6-overlay-${S6_OVERLAY_ARCH}.tar.gz \
      -C / && \
    useradd \
      -U -d /config \
      -s /bin/false primary-user && \
    usermod -a -G users primary-user && \
    apt-get autoremove --purge -y && \
    apt-get clean && \
    rm -rf \
      /var/lib/apt/lists/* \
      /var/tmp/* \
      /tmp/*

# set language environment variables
ENV LANG=${LANGUAGE}.${ENCODING}

# set s6 environment variables
ENV S6_KEEP_ENV=0 \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2

# add local files
COPY root/ /

# entry (s6 overlays)
ENTRYPOINT ["/init"]
