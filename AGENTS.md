# Agent instructions

## Goal

Maintain a two-architecture persistent desktop container for Chat On Steroids.

## Architecture contract

- AMD64 must build as native `linux/amd64`.
- ARM64 must build as native `linux/arm64`.
- Do not add Rosetta or AMD64 emulation to the ARM64 path.
- Chrome Remote Desktop is AMD64-only in this project.
- ARM64 must remain usable through localhost noVNC.
- CoS and Chrome must use native packages matching the image architecture.

## Security contract

- Keep noVNC published to host loopback only.
- Keep x11vnc bound to container loopback only.
- Do not expose CoS MCP directly. CoS owns its tunnel setup.
- Do not remove GNOME Keyring or Secret Service support.
- Do not configure Electron or Chromium to use insecure plaintext/basic-text credential storage.
- Do not mount the Docker socket or sensitive host directories by default.
- Downloaded application packages must remain checksum-pinned.

## Desktop/session contract

- CoS and Chrome launch through Xfce autostart so they inherit the same D-Bus session and Secret Service environment.
- The machine ID must persist across container replacement.
- `/home/cos` must persist.
- Before CRD registration, AMD64 uses the local Xvfb/Xfce session.
- After CRD registration and restart, AMD64 uses the CRD-managed Xfce session.
- ARM64 always uses the local Xvfb/Xfce session.

## Validation

Run `./scripts/validate.sh` after changes. When Docker is available, validate both Compose configurations and build the affected architecture before claiming success.
