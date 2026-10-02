# Security

This repository runs Chat On Steroids inside a dedicated container. Treat the persistent desktop home as a credential store.

## Persistent state

The persistent home can contain:

- ChatGPT cookies and browser sessions
- the CoS companion extension and extension state
- CoS configuration and session history
- GNOME Keyring files
- encrypted CoS credentials
- approved project data

Do not copy this state into Git, tickets, logs, or public backups.

## Secret Service

Chat On Steroids refuses Electron's insecure Linux `basic_text` storage fallback. This image runs GNOME Keyring's Secret Service inside the same D-Bus desktop session as CoS.

Do not remove GNOME Keyring, force `basic_text`, or launch CoS outside the desktop session. If the keyring is locked, unlock it from the desktop rather than weakening the storage configuration.

## noVNC

The Compose file publishes noVNC only on host loopback:

`127.0.0.1:6080`

x11vnc has no VNC password because it is reachable only from inside the container. Do not publish port 6080 or 5900 on a wildcard host address without an authenticated TLS gateway.

## Chrome Remote Desktop

Chrome Remote Desktop registration files under `~/.config/chrome-remote-desktop` are sensitive. Do not commit registration commands, OAuth codes, PINs, or host JSON files.

CRD is installed only in the AMD64 image. The ARM64 image uses noVNC.

## Container root

The `cos` user has passwordless `sudo` inside the container. CoS command execution therefore can obtain container root. This does not grant host root unless sensitive host resources are mounted.

Never mount:

- `/var/run/docker.sock`
- the host root filesystem
- host SSH private keys
- cloud credential directories
- unrelated secret stores

Mount only the project directories CoS actually needs.

## CoS MCP and tunnel

CoS binds its local MCP services according to its own security model and publishes them through the tunnel you configure in CoS. This container intentionally does not add a second public MCP proxy.

Use the upstream CoS setup flow for OpenAI Secure MCP Tunnel or another supported transport.

## Updates

The image verifies pinned download SHA-256 values for CoS, Chrome, and CRD before installing them. When updating a pinned package, verify the release artifact and replace both the URL and checksum.
