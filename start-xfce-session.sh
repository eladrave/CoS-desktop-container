#!/usr/bin/env bash
set -Eeuo pipefail

export HOME=/home/cos
export USER=cos
export LOGNAME=cos
export XDG_CONFIG_HOME=/home/cos/.config
export XDG_CACHE_HOME=/home/cos/.cache
export XDG_DATA_HOME=/home/cos/.local/share
export XDG_RUNTIME_DIR=/run/user/10001

install -d -m 0700 "${XDG_RUNTIME_DIR}"

if command -v gnome-keyring-daemon >/dev/null 2>&1; then
  keyring_env="$(gnome-keyring-daemon --start --components=secrets 2>/dev/null || true)"
  if [[ -n "${keyring_env}" ]]; then
    eval "${keyring_env}"
    export GNOME_KEYRING_CONTROL SSH_AUTH_SOCK
  fi
fi

dbus-update-activation-environment DISPLAY XAUTHORITY XDG_RUNTIME_DIR   GNOME_KEYRING_CONTROL SSH_AUTH_SOCK >/dev/null 2>&1 || true

exec xfce4-session
