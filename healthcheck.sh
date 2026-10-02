#!/usr/bin/env bash
set -Eeuo pipefail

pgrep -x dbus-daemon >/dev/null
test -x /usr/bin/chat-on-steroids
test -x /usr/bin/google-chrome-stable
test -x /usr/bin/gnome-keyring-daemon
test -x /usr/bin/secret-tool
test -x /usr/bin/x11vnc
test -x /usr/bin/websockify
test -x /usr/bin/Xvfb
test "$(dpkg-query -W -f='${Version}' google-chrome-stable)" = "${COS_DESKTOP_CHROME_VERSION}"
test "$(dpkg-query -W -f='${Architecture}' google-chrome-stable)" = "${COS_DESKTOP_IMAGE_ARCH}"

case "${COS_DESKTOP_CRD_ENABLED}" in
  1)
    test "${COS_DESKTOP_IMAGE_ARCH}" = amd64
    test "$(dpkg-query -W -f='${Version}' chrome-remote-desktop)" = "${COS_DESKTOP_CRD_VERSION}"
    test -x /opt/google/chrome-remote-desktop/start-host
    test -x /opt/google/chrome-remote-desktop/start-host.real
    ;;
  0)
    ! dpkg-query -W chrome-remote-desktop >/dev/null 2>&1
    ;;
  *)
    exit 1
    ;;
esac

test "$(passwd -S cos | cut -d ' ' -f2)" = "L"
test "$(setpriv --reuid=10001 --regid=10001 --init-groups sudo -n id -u)" = 0

supervisorctl status desktop-session | grep -Eq 'RUNNING'
supervisorctl status x11vnc | grep -Eq 'RUNNING'
supervisorctl status novnc | grep -Eq 'RUNNING'

curl --fail --silent --show-error --max-time 5 http://127.0.0.1:6080/ | grep -qi noVNC

[[ -f /run/cos-desktop/desktop.env && ! -L /run/cos-desktop/desktop.env ]]
[[ "$(stat -c '%u:%g:%a' /run/cos-desktop/desktop.env)" == '10001:10001:600' ]]

display="$(sed -n 's/^DISPLAY=//p' /run/cos-desktop/desktop.env | head -n 1)"
xauthority="$(sed -n 's/^XAUTHORITY=//p' /run/cos-desktop/desktop.env | head -n 1)"
[[ "${display}" =~ ^:[0-9]+$ && -r "${xauthority}" ]]

pgrep -u 10001 -f gnome-keyring-daemon >/dev/null
