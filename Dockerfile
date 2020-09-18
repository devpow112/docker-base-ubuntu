FROM ubuntu:focal-20200916

# labels
LABEL maintainer devpow112
LABEL org.opencontainers.image.source \
      https://github.com/devpow112/docker-base-ubuntu

# set input arguments to defaults
ARG TARGETPLATFORM
ARG TRANSFORM_PATTERN="s/^linux\///;s/^arm64/aarch64/;s/^arm\/v7/armhf/"
ARG S6_OVERLAY_VERSION="2.1.0.0"
ARG LANGUAGE="en_US"
ARG ENCODING="UTF-8"

# set basic environment variables
ENV DEBIAN_FRONTEND="noninteractive"\
    HOME="/root" \
    TERM="xterm"

# setup directories/volumes
RUN mkdir /config
VOLUME /config

# setup packages, language and non root user
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
      apt-utils \
      locales \
      tzdata \
      curl && \
    localedef \
      -i ${LANGUAGE} -c -f ${ENCODING} \
      -A /usr/share/locale/locale.alias \
      ${LANGUAGE}.${ENCODING} && \
    S6_OVERLAY_ARCH=$(echo ${TARGETPLATFORM} | sed ${TRANSFORM_PATTERN}) && \
    URL='https://github.com/just-containers/s6-overlay/releases/download/' && \
    URL="${URL}v${S6_OVERLAY_VERSION}/s6-overlay-${S6_OVERLAY_ARCH}.tar.gz" && \
    echo "Downloading s6 overlay: ${URL}" && \
    curl -o /tmp/s6-overlay.tar.gz -L ${URL} && \
    tar xfz \
      /tmp/s6-overlay.tar.gz \
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
