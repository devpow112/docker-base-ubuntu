FROM ubuntu:focal-20201106 AS s6-overlay

# set input arguments to defaults
ARG TARGETPLATFORM
ARG S6_OVERLAY_VERSION="2.1.0.0"

# download s6 overlay archive
RUN export DEBIAN_FRONTEND='noninteractive' && \
    apt-get update && \
    apt-get install -y curl && \
    TRANSFORM_PATTERN='s/^linux\///;s/^arm64/aarch64/;s/^arm\/v7/armhf/' && \
    S6_OVERLAY_ARCH=$(echo ${TARGETPLATFORM} | sed ${TRANSFORM_PATTERN}) && \
    URL='https://github.com/just-containers/s6-overlay/releases/download/' && \
    URL="${URL}v${S6_OVERLAY_VERSION}/s6-overlay-${S6_OVERLAY_ARCH}.tar.gz" && \
    curl -o /tmp/s6-overlay.tar.gz -L ${URL}

FROM ubuntu:focal-20201106

# set input arguments to defaults
ARG LANGUAGE="en_US"
ARG ENCODING="UTF-8"

# set basic environment variables
ENV HOME="/root" \
    TERM="xterm"

# setup directories and volumes
RUN mkdir /config
VOLUME /config

# copy over s6 archive
COPY --from=s6-overlay /tmp/s6-overlay.tar.gz /tmp

# setup packages, locale and non-root user
RUN export DEBIAN_FRONTEND='noninteractive' && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
      apt-utils \
      locales \
      tzdata && \
    localedef \
      -i ${LANGUAGE} -c -f ${ENCODING} \
      -A /usr/share/locale/locale.alias \
      ${LANGUAGE}.${ENCODING} && \
    tar xzf /tmp/s6-overlay.tar.gz -C / --exclude='./bin' && \
    tar xzf /tmp/s6-overlay.tar.gz -C /usr ./bin && \
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
