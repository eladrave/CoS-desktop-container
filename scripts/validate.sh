#!/usr/bin/env bash
set -Eeuo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_dir}"

shell_files=(
  entrypoint.sh
  start-xfce-session.sh
  run-session.sh
  run-local-desktop.sh
  run-crd.sh
  configure-crd.sh
  start-host-wrapper.sh
  run-x11vnc.sh
  run-novnc.sh
  healthcheck.sh
  scripts/build-amd64.sh
  scripts/build-arm64.sh
  scripts/validate.sh
)

for file in "${shell_files[@]}"; do
  bash -n "${file}"
done

grep -Fq 'Chat-On-Steroids-Linux-x64.deb' Dockerfile
grep -Fq 'DESKTOP_ARCH=amd64' scripts/build-amd64.sh
grep -Fq 'platform: linux/arm64' compose.macos.yaml
grep -Fq 'DESKTOP_ARCH=arm64' scripts/build-arm64.sh
grep -Fq 'INSTALL_CRD=0' scripts/build-arm64.sh
grep -Fq 'Chat-On-Steroids-Linux-arm64.deb' scripts/build-arm64.sh
grep -Fq 'gnome-keyring' Dockerfile
grep -Fq 'gnome-keyring-daemon --start --components=secrets' start-xfce-session.sh
grep -Fq '127.0.0.1:${NOVNC_PORT:-6080}:6080' compose.yaml

if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  docker compose --env-file deploy.env.example -f compose.yaml config --quiet
  docker compose --env-file deploy.macos.env.example -f compose.yaml -f compose.macos.yaml config --quiet
fi

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck "${shell_files[@]}"
fi

echo "Validation passed."
