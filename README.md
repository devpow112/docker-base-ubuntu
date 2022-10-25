# Docker Ubuntu (Base)

[![License][License]](LICENSE)
[![Release][Release Badge]][Release Workflow]

Ubuntu docker container for use as base for other containers.

## Building

```console
docker build \
  --build-arg "TARGETPLATFORM=..." \
  --build-arg "LANGUAGE=..." \
  --build-arg "ENCODING=..." \
  --build-arg "S6_OVERLAY_VERSION=..." \
  -t base-ubuntu .
```

### Arguments

- `TARGETPLATFORM` - Set by [Docker Buildx] automatically. Currently supported
  platforms are `amd64`, `arm/v7`, `arm64`, `riscv64` and `s390x`. This should
  be set automatically even if building locally using standard [Docker CLI].
- `LANGUAGE` - The language code that is set globally for the system. Defaults
  to `en_US`. See [locale] for more details.
- `ENCODING` - Character encoding that is set globally for the system. Defaults
  to `UTF-8`. See [locale] for more details.
- `S6_OVERLAY_VERSION` - Version of the [s6 overlay] that is installed. This is
  automatically updated to the latest release and should only really need to be
  set manually if trying out a new version locally when building. Only versions
  **3** and higher are supported.

## Usage

This container is intended to be used as a base for other containers. It will
work as an interactive environment but doesn't provide much more then the
standard [Ubuntu] container.

### Container Base

This is the intended usage.

```dockerfile
FROM ghcr.io/devpow112/base-ubuntu:latest

...
```

### Interactive

Not recommended but will work if you need a quick Ubuntu environment to do
testing with.

```console
docker run --it --rm \
  --entrypoint /bin/bash \
  ghcr.io/devpow112/base-ubuntu:latest
```

<!-- links -->
[License]: https://img.shields.io/github/license/devpow112/docker-base-ubuntu?label=License
[Release Badge]: https://github.com/devpow112/docker-base-ubuntu/actions/workflows/release.yml/badge.svg?branch=main
[Release Workflow]: https://github.com/devpow112/docker-base-ubuntu/actions/workflows/release.yml?query=branch%3Amain
[Docker Buildx]: https://docs.docker.com/buildx/working-with-buildx
[Docker CLI]: https://docs.docker.com/engine/reference/commandline/build
[locale]: https://manpages.ubuntu.com/manpages/bionic/man1/locale.1.html
[s6 overlay]: https://github.com/just-containers/s6-overlay
[Ubuntu]: https://hub.docker.com/_/ubuntu
