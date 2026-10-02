#!/usr/bin/env bash
set -Eeuo pipefail

exec /usr/bin/websockify   --web=/usr/share/novnc/   0.0.0.0:6080   127.0.0.1:5900
