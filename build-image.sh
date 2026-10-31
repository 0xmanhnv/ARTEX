#!/usr/bin/env bash
# Build the ARTEX Docker runtime image locally, without a published image and
# without a Go/Node toolchain on the host (everything runs inside Docker).
#
# Two steps:
#   1) Dockerfile.binbuild compiles the frontend + Go binary and exports it to
#      dist/<arch>/artex.
#   2) The main Dockerfile copies that binary and installs the recon toolbox.
#
# Then optionally push to a registry.
#
# Env vars:
#   IMAGE=ghcr.io/0xmanhnv/artex   target image name (no tag)
#   TAG=latest                     image tag
#   ARCH=amd64                     target arch (amd64|arm64, must match host for the Go build)
#   PUSH=1                         also `docker push` after building
#
# Examples:
#   ./build-image.sh                       # build ghcr.io/0xmanhnv/artex:latest
#   PUSH=1 ./build-image.sh                # build + push (run `docker login ghcr.io` first)
#   IMAGE=myuser/artex TAG=v0.4.0 ./build-image.sh
set -euo pipefail

cd "$(cd "$(dirname "$0")" && pwd)"

IMAGE="${IMAGE:-ghcr.io/0xmanhnv/artex}"
TAG="${TAG:-latest}"
ARCH="${ARCH:-amd64}"
PUSH="${PUSH:-0}"
REF="${IMAGE}:${TAG}"

echo "[*] 1/2 building binary -> dist/${ARCH}/artex"
docker build -f Dockerfile.binbuild --target export \
  --output "type=local,dest=dist/${ARCH}" .

echo "[*] 2/2 building runtime image -> ${REF}"
docker build --build-arg "TARGETARCH=${ARCH}" -t "${REF}" .

if [ "${PUSH}" = "1" ]; then
  echo "[*] pushing ${REF} (run 'docker login' for the registry first if needed)"
  docker push "${REF}"
fi

echo "[+] done: ${REF}"
