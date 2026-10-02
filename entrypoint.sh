#!/usr/bin/env bash
set -Eeuo pipefail

install -d -m 0755 /run/dbus /run/user
install -d -o cos -g cos -m 0700 /run/user/10001 /run/cos-desktop
install -d -m 0700 /var/lib/cos-desktop-persistent

test -d /home/cos
chown cos:cos /home/cos
setpriv --reuid=10001 --regid=10001 --init-groups chmod 0700 /home/cos

machine_id_file=/var/lib/cos-desktop-persistent/machine-id
if [[ ! -s "${machine_id_file}" ]]; then
  dbus-uuidgen > "${machine_id_file}"
  chmod 0600 "${machine_id_file}"
fi
install -o root -g root -m 0444 "${machine_id_file}" /etc/machine-id

if [[ ! -e /home/cos/.cos-desktop-initialized ]]; then
  chown -R cos:cos /home/cos
  setpriv --reuid=10001 --regid=10001 --init-groups     cp -R /opt/cos-desktop-home-skel/. /home/cos/
  setpriv --reuid=10001 --regid=10001 --init-groups     touch /home/cos/.cos-desktop-initialized
fi

setpriv --reuid=10001 --regid=10001 --init-groups   install -d -m 0700     /home/cos/.cache     /home/cos/.config     /home/cos/.config/autostart     /home/cos/.config/chrome-remote-desktop     /home/cos/.local     /home/cos/.local/share     /home/cos/Downloads     /home/cos/Projects

for desktop_file in cos.desktop chrome.desktop; do
  setpriv --reuid=10001 --regid=10001 --init-groups install -m 0644     "/opt/cos-desktop-home-skel/.config/autostart/${desktop_file}"     "/home/cos/.config/autostart/${desktop_file}"
done

for mime_type in text/html x-scheme-handler/http x-scheme-handler/https; do
  setpriv --reuid=10001 --regid=10001 --init-groups     env HOME=/home/cos USER=cos LOGNAME=cos XDG_CONFIG_HOME=/home/cos/.config     xdg-mime default google-chrome.desktop "${mime_type}"
done

exec /usr/bin/supervisord --nodaemon --configuration /etc/supervisor/supervisord.conf
