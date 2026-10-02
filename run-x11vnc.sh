#!/usr/bin/env bash
set -Eeuo pipefail

session_file="${COS_DESKTOP_SESSION_FILE:-/run/cos-desktop/desktop.env}"

while true; do
  if [[ ! -f "${session_file}" || -L "${session_file}" || "$(stat -c '%u:%g:%a' "${session_file}" 2>/dev/null || true)" != '10001:10001:600' ]]; then
    sleep 2
    continue
  fi
  display="$(sed -n 's/^DISPLAY=//p' "${session_file}" | head -n 1)"
  xauthority="$(sed -n 's/^XAUTHORITY=//p' "${session_file}" | head -n 1)"
  if [[ "${display}" =~ ^:[0-9]+$ && "${xauthority}" =~ ^/ && -r "${xauthority}" ]]; then
    break
  fi
  sleep 2
done

exec /usr/bin/x11vnc   -display "${display}"   -auth "${xauthority}"   -nopw   -rfbport 5900   -listen 127.0.0.1   -noipv6   -forever   -shared
