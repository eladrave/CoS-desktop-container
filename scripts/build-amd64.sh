#!/usr/bin/env bash
set -Eeuo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_dir}"

image_ref="${IMAGE_REF:-cos-desktop:2.1.25-amd64}"

docker buildx build   --pull   --platform linux/amd64   --load   --build-arg DESKTOP_ARCH=amd64   --build-arg INSTALL_CRD=1   --tag "${image_ref}"   .
