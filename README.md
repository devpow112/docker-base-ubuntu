# Ubuntu (Docker Base Container)

[![License][License]](LICENSE)
[![Release][Release Badge]][Release Workflow]

[Ubuntu] container for use as base for other containers. Supports multiple
Ubuntu releases (`noble`, `jammy`, `focal`) from a single repository.

## Structure

Each Ubuntu release has its own directory with a self-contained Docker build
context:

```text
releases/
  noble/        # Ubuntu 24.04 LTS (Noble Numbat)
  jammy/        # Ubuntu 22.04 LTS (Jammy Jellyfish)
  focal/        # Ubuntu 20.04 LTS (Focal Fossa)
```

Each release directory contains:

- `Dockerfile` - Release-specific Docker build file
- `packages/` - Package lists (`required.txt`, `temporary.txt`,
  `generated/install.txt`)
- `root/` - [s6 overlay] service definitions
- `test/` - Test Dockerfile and service

## Building

```console
docker build \
  --build-arg "TARGETPLATFORM=..." \
  --build-arg "LANGUAGE=..." \
  --build-arg "ENCODING=..." \
  --build-arg "S6_OVERLAY_VERSION=..." \
  -t base-ubuntu releases/noble/
```

Replace `releases/noble/` with `releases/jammy/` or `releases/focal/` to build a
different release.

### Arguments

- `TARGETPLATFORM` - Set by [Docker Buildx] automatically. Currently supported
  platforms are `amd64`, `arm/v7`, `arm64`, `ppc64le` `riscv64`, and `s390x`.
  This should be set automatically even if building locally using standard
  [Docker CLI].
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
standard [Ubuntu][Ubuntu Container] container.

### Base Container

This is the intended usage.

```dockerfile
FROM ghcr.io/devpow112/base-ubuntu:noble

...
```

Available tags: `noble`, `jammy`, `focal`, `latest` (points to `noble`).

### Interactive

Not recommended but will work if you need a quick Ubuntu environment to do
testing with.

```console
docker run --it --rm \
  --entrypoint /bin/bash \
  ghcr.io/devpow112/base-ubuntu:noble
```

<!-- links -->
[License]: https://img.shields.io/github/license/devpow112/docker-base-ubuntu?label=License
[Release Badge]: https://github.com/devpow112/docker-base-ubuntu/actions/workflows/release.yml/badge.svg?branch=main
[Release Workflow]: https://github.com/devpow112/docker-base-ubuntu/actions/workflows/release.yml?query=branch%3Amain
[Ubuntu]: https://ubuntu.com
[Docker Buildx]: https://docs.docker.com/buildx/working-with-buildx
[Docker CLI]: https://docs.docker.com/engine/reference/commandline/build
[locale]: https://manpages.ubuntu.com/manpages/noble/man1/locale.1.html
[s6 overlay]: https://github.com/just-containers/s6-overlay
[Ubuntu Container]: https://hub.docker.com/_/ubuntu
