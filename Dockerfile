FROM ubuntu:focal-20210416 AS temp

# set input arguments to defaults
ARG TARGETPLATFORM
ARG PLATFORM_TRANSFORM="s/^linux\///;s/^arm64/aarch64/;s/^arm\/v7/armhf/"
ARG S6_OVERLAY_VERSION="2.2.0.3"

# download s6 overlay archive
RUN export DEBIAN_FRONTEND='noninteractive' && \
    apt-get update && \
    apt-get install --no-install-recommends -y \
      ca-certificates \
      curl && \
    ARCH=$(echo ${TARGETPLATFORM} | sed "${PLATFORM_TRANSFORM}") && \
    URL='https://github.com/just-containers/s6-overlay/releases/download/' && \
    URL="${URL}v${S6_OVERLAY_VERSION}/s6-overlay-${ARCH}-installer" && \
    curl -sSfo /tmp/s6-overlay-installer -L ${URL} && \
    chmod u+x /tmp/s6-overlay-installer

FROM ubuntu:focal-20210416

# set input arguments to defaults
ARG LANGUAGE="en_US"
ARG ENCODING="UTF-8"

# set basic environment variables
ENV HOME="/root" \
    TERM="xterm"

# set up directories and volumes
RUN mkdir /config
VOLUME /config

# copy over s6 archive
COPY --from=temp /tmp/s6-overlay-installer /tmp

# set up packages, locale and non-root user
RUN export DEBIAN_FRONTEND='noninteractive' && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install --no-install-recommends -y \
      apt-utils \
      locales \
      tzdata && \
    localedef \
      -i ${LANGUAGE} -c -f ${ENCODING} \
      -A /usr/share/locale/locale.alias \
      ${LANGUAGE}.${ENCODING} && \
    /tmp/s6-overlay-installer / && \
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
