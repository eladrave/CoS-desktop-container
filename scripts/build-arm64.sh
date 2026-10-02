#!/usr/bin/env bash
set -Eeuo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_dir}"

image_ref="${IMAGE_REF:-cos-desktop:2.1.25-arm64}"

docker buildx build   --pull   --platform linux/arm64   --load   --build-arg 'UBUNTU_BASE_IMAGE=ubuntu@sha256:ec0b1c9058e44c837a21c3f9d8a3d5e9aaa94ed28edceb18e154af5efecf0950'   --build-arg DESKTOP_ARCH=arm64   --build-arg INSTALL_CRD=0   --build-arg 'COS_DEB_URL=https://github.com/totec448-spec/chat-on-steroids/releases/download/v2.1.25/Chat-On-Steroids-Linux-arm64.deb'   --build-arg 'COS_DEB_SHA256=9ce4bfc18c350444930460da017ecbc50694267fa1e0147dbb0b71b9d2c5d8ef'   --build-arg 'CHROME_DEB_URL=https://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_152.0.7977.64-1_arm64.deb'   --build-arg 'CHROME_DEB_SHA256=6ccab79a7afe1d174c89e28cf0d5a265e6e8855ff3b45c6a2151a65d7ddae9e8'   --tag "${image_ref}"   .
