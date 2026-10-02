#!/usr/bin/env bash
set -Eeuo pipefail

case "${COS_DESKTOP_CRD_ENABLED:-1}" in
  1)
    if compgen -G '/home/cos/.config/chrome-remote-desktop/host#*.json' >/dev/null; then
      exec /usr/local/sbin/run-cos-crd
    fi
    exec /usr/local/sbin/run-cos-local-desktop
    ;;
  0)
    exec /usr/local/sbin/run-cos-local-desktop
    ;;
  *)
    echo 'COS_DESKTOP_CRD_ENABLED must be 0 or 1.' >&2
    exit 64
    ;;
esac
