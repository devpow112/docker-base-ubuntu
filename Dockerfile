FROM ubuntu:noble-20260113

# set default input arguments
ARG TARGETPLATFORM \
    LANGUAGE=en_US \
    ENCODING=UTF-8 \
    S6_OVERLAY_VERSION=3.2.2.0

# set default shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# set environment variables
ENV HOME=/root \
    TERM=xterm \
    LANG="${LANGUAGE}.${ENCODING}" \
    S6_CMD_WAIT_FOR_SERVICES=1 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2

# add temporary package list
COPY packages/temporary.txt /tmp/packages/temporary.txt

# set up packages, locale and non-root user
RUN export 'DEBIAN_FRONTEND=noninteractive' && \
    echo '###### Set up packages' && \
    apt-get update && \
    apt-get install --no-install-recommends --no-install-suggests -y \
# packages:start
      'apt-utils=2.8.3' \n      'base-files=13ubuntu10.4' \n      'ca-certificates=20240203' \n      'curl=8.5.0-2ubuntu10.7' \n      'gcc-14-base=14.2.0-4ubuntu2~24.04.1' \n      'libbrotli1=1.1.0-2build2' \n      'libc-bin=2.39-0ubuntu8.7' \n      'libc6=2.39-0ubuntu8.7' \n      'libcurl4t64=8.5.0-2ubuntu10.7' \n      'libgcc-s1=14.2.0-4ubuntu2~24.04.1' \n      'libgnutls30t64=3.8.3-1.1ubuntu3.5' \n      'libgssapi-krb5-2=1.20.1-6ubuntu2.6' \n      'libk5crypto3=1.20.1-6ubuntu2.6' \n      'libkeyutils1=1.6.3-3build1' \n      'libkrb5-3=1.20.1-6ubuntu2.6' \n      'libkrb5support0=1.20.1-6ubuntu2.6' \n      'libldap2=2.6.10+dfsg-0ubuntu0.24.04.1' \n      'libnghttp2-14=1.59.0-1ubuntu0.2' \n      'libpsl5t64=0.21.2-1.1build1' \n      'librtmp1=2.4+20151223.gitfa8646d.1-2build7' \n      'libsasl2-2=2.1.28+dfsg1-5ubuntu3.1' \n      'libsasl2-modules-db=2.1.28+dfsg1-5ubuntu3.1' \n      'libssh-4=0.10.6-2ubuntu0.3' \n      'libssl3t64=3.0.13-0ubuntu3.7' \n      'libstdc++6=14.2.0-4ubuntu2~24.04.1' \n      'locales=2.39-0ubuntu8.7' \n      'openssl=3.0.13-0ubuntu3.7' \n      'tzdata=2025b-0ubuntu0.24.04.1' \n      'xz-utils=5.6.1+really5.4.5-1ubuntu0.2' && \n
# packages:end
    echo '###### Set up locale' && \
    echo "###### Language: ${LANGUAGE}" && \
    echo "###### Encoding: ${ENCODING}" && \
    localedef \
      -i "${LANGUAGE}" -c -f "${ENCODING}" \
      -A /usr/share/locale/locale.alias \
      "${LANG}" && \
    echo '###### Set up user' && \
    mkdir /config && \
    useradd -U -d /config -s /bin/false primary-user && \
    usermod -a -G users primary-user && \
    echo '###### Set up s6 overlay' && \
    PLATFORM_TRANSFORM='s/^linux\///' && \
    PLATFORM_TRANSFORM="${PLATFORM_TRANSFORM};s/^amd64/x86_64/" && \
    PLATFORM_TRANSFORM="${PLATFORM_TRANSFORM};s/^arm64/aarch64/" && \
    PLATFORM_TRANSFORM="${PLATFORM_TRANSFORM};s/^arm\/v7/armhf/" && \
    PLATFORM_TRANSFORM="${PLATFORM_TRANSFORM};s/^ppc64le/powerpc64le/" && \
    ARCH=$(echo "${TARGETPLATFORM}" | sed "${PLATFORM_TRANSFORM}") && \
    echo "###### Platform mapping s6 overlay: ${TARGETPLATFORM} => ${ARCH}" && \
    URL='https://github.com/just-containers/s6-overlay/releases/download' && \
    URL="${URL}/v${S6_OVERLAY_VERSION}" && \
    curl -sSfo /tmp/s6-overlay-noarch.tar.xz \
      -L "${URL}/s6-overlay-noarch.tar.xz" && \
    curl -sSfo /tmp/s6-overlay-arch.tar.xz \
      -L "${URL}/s6-overlay-${ARCH}.tar.xz" && \
    curl -sSfo /tmp/s6-overlay-symlinks-noarch.tar.xz \
      -L "${URL}/s6-overlay-symlinks-noarch.tar.xz" && \
    curl -sSfo /tmp/s6-overlay-symlinks-arch.tar.xz \
      -L "${URL}/s6-overlay-symlinks-arch.tar.xz" && \
    curl -sSfo /tmp/syslogd-overlay-noarch.tar.xz \
      -L "${URL}/syslogd-overlay-noarch.tar.xz" && \
    tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-arch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-symlinks-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-symlinks-arch.tar.xz && \
    tar -C / -Jxpf /tmp/syslogd-overlay-noarch.tar.xz && \
    echo '###### Clean up' && \
    TEMPORARY_PACKAGES="$(cat /tmp/packages/temporary.txt)" && \
    apt-get autoremove --purge -y ${TEMPORARY_PACKAGES} && \
    apt-get autoremove --purge -y && \
    apt-get autoclean && \
    apt-get clean && \
    rm -rf \
      /tmp/packages \
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

# buildtime related arguments
ARG BUILD_CREATED \
    BUILD_VERSION \
    BUILD_REF_NAME \
    BUILD_REVISION

# labels
LABEL maintainer=devpow112 \
      org.opencontainers.image.authors=devpow112 \
      org.opencontainers.image.title='Docker Ubuntu (Base)' \
      org.opencontainers.image.description='Ubuntu docker container for use as base for other containers.' \
      org.opencontainers.image.documentation=https://github.com/devpow112/docker-base-ubuntu#readme \
      org.opencontainers.image.licenses=MIT \
      org.opencontainers.image.source=https://github.com/devpow112/docker-base-ubuntu \
      org.opencontainers.image.url=https://github.com/devpow112/docker-base-ubuntu \
      org.opencontainers.image.vendor=devpow112 \
      org.opencontainers.image.created=${BUILD_CREATED} \
      org.opencontainers.image.version=${BUILD_VERSION} \
      org.opencontainers.image.ref.name=${BUILD_REF_NAME} \
      org.opencontainers.image.revision=${BUILD_REVISION}
