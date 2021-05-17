# Docker Ubuntu (Base)

[![License]](LICENSE)
[![CI][CI Badge]][CI Workflow]
[![Release][Release Badge]][Release Workflow]

Ubuntu docker container for use as base for other containers.

## Building

```bash
docker build -t base-ubuntu -f Dockerfile docker-base-ubuntu
```

## Usage

```dockerfile
FROM ghcr.io/devpow112/base-ubuntu

...
```

<!-- links -->
[License]: https://img.shields.io/github/license/devpow112/docker-base-ubuntu?label=License
[CI Badge]: https://github.com/devpow112/docker-base-ubuntu/actions/workflows/ci.yml/badge.svg?branch=main
[CI Workflow]: https://github.com/devpow112/docker-base-ubuntu/actions/workflows/ci.yml?query=branch%3Amain
[Release Badge]: https://github.com/devpow112/docker-base-ubuntu/actions/workflows/release.yml/badge.svg?branch=main
[Release Workflow]: https://github.com/devpow112/docker-base-ubuntu/actions/workflows/release.yml?query=branch%3Amain
