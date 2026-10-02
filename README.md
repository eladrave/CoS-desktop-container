# CoS Desktop Container

A persistent Linux desktop container for [Chat On Steroids](https://github.com/totec448-spec/chat-on-steroids), derived from the desktop/container infrastructure in [eladrave/codex-desktop-container](https://github.com/eladrave/codex-desktop-container).

The goal is to run Chat On Steroids in an isolated desktop environment with a persistent Chrome profile and persistent CoS state, while keeping the host machine clean.

## Supported targets

| Host | Container architecture | Remote desktop | Status |
| --- | --- | --- | --- |
| Ubuntu/Linux AMD64, including CodexGUI | `linux/amd64` | Chrome Remote Desktop, plus localhost noVNC fallback | Supported |
| Apple silicon MacBook | `linux/arm64` | localhost noVNC | Supported |

Chrome Remote Desktop is intentionally not installed in the ARM64 image because Google's Linux CRD package is not available for ARM64. The ARM64 container is fully native, including Chat On Steroids and Google Chrome.

## Pinned application versions

- Chat On Steroids: **2.1.25**
- Google Chrome: **152.0.7977.64**
- Chrome Remote Desktop on AMD64: **154.0.8037.11**

The CoS release artifacts are downloaded from the upstream GitHub release and verified by SHA-256 during the image build.

## What is included

- Ubuntu 24.04 desktop runtime
- Xfce
- Chat On Steroids
- Google Chrome with a persistent profile
- GNOME Keyring / Secret Service for CoS secure credential storage
- Chrome Remote Desktop on AMD64
- Xvfb + x11vnc + noVNC fallback
- Persistent `/home/cos`
- Persistent machine ID
- Passwordless `sudo` inside the container only

CoS provides its own MCP server and tunnel mechanism. This container does not expose the CoS MCP endpoint directly.

## AMD64 deployment on CodexGUI

Clone the repository:

```bash
git clone https://github.com/eladrave/CoS-desktop-container.git
cd CoS-desktop-container
cp deploy.env.example deploy.env
```

Build the native AMD64 image:

```bash
./scripts/build-amd64.sh
```

Create the persistent host directories:

```bash
sudo mkdir -p /var/lib/cos-desktop/home /var/lib/cos-desktop/machine
sudo chown -R 10001:10001 /var/lib/cos-desktop/home
sudo chmod 700 /var/lib/cos-desktop/home
sudo chmod 700 /var/lib/cos-desktop/machine
```

Start the container:

```bash
docker compose --env-file deploy.env up -d
```

Before CRD is registered, the container runs its own Xvfb/Xfce desktop. You can inspect it locally through noVNC:

```text
http://127.0.0.1:6080/vnc.html
```

On a remote server, reach that localhost URL through an SSH tunnel if needed:

```bash
ssh -L 6080:127.0.0.1:6080 <server>
```

### Register Chrome Remote Desktop

Open Google's Chrome Remote Desktop headless setup page on a trusted browser and copy the generated Linux registration command.

Open a shell in the container:

```bash
docker exec -it cos-desktop-desktop-1 bash
```

Run the generated `/opt/google/chrome-remote-desktop/start-host ...` command inside the container. The image provides a compatibility wrapper that forces registration to the persistent `cos` user.

After registration succeeds:

```bash
docker restart cos-desktop-desktop-1
```

The container will then use the CRD-managed Xfce session.

## Apple silicon MacBook

The Mac build is native ARM64. It does not use Rosetta or an AMD64 container.

```bash
git clone https://github.com/eladrave/CoS-desktop-container.git
cd CoS-desktop-container
cp deploy.macos.env.example deploy.env
./scripts/build-arm64.sh
docker compose --env-file deploy.env -f compose.yaml -f compose.macos.yaml up -d
```

Open:

```text
http://127.0.0.1:6080/vnc.html
```

The Mac variant uses Docker named volumes for persistent state.

## First CoS setup

After the desktop is visible:

1. Allow the GNOME Keyring prompt to create or unlock the desktop keyring if it appears.
2. Sign in to ChatGPT in Chrome.
3. Open Chat On Steroids.
4. In CoS, approve the folders you want it to access under **Settings > Workspace**.
5. Configure the CoS Core connection under **Settings > Setup**.
6. Load the CoS companion extension. CoS can open its packaged extension directory, then use `chrome://extensions`, enable Developer mode, and choose **Load unpacked**.
7. Pair the extension and complete the CoS setup.

The Chrome profile, CoS application state, extension state, browser cookies, keyring files, and project files under `/home/cos` persist across container replacement.

## Secure credential storage

CoS deliberately refuses Electron's insecure Linux `basic_text` fallback. This image therefore starts GNOME Keyring's Secret Service inside the same D-Bus desktop session that launches CoS.

On a fresh persistent home, GNOME Keyring may ask you to create or unlock a keyring. Do not disable this. CoS uses the Secret Service for encrypted credentials such as its tunnel API key and bridge token.

If CoS reports:

```text
Secure credential storage is unavailable
```

verify that the desktop session is running and that `gnome-keyring-daemon` is active:

```bash
docker exec cos-desktop-desktop-1 pgrep -af gnome-keyring-daemon
```

Then unlock the keyring from the desktop and restart CoS.

## Projects

The persistent home includes:

```text
/home/cos/Projects
```

For host repositories, add a bind mount in a local Compose override instead of mounting sensitive host directories broadly. Example:

```yaml
services:
  desktop:
    volumes:
      - type: bind
        source: /home/elad/git
        target: /workspace/git
```

Then approve only the required folders inside CoS.

Do not mount the Docker socket, host SSH directory, or the host root filesystem into this container.

## Persistence

### Linux / CodexGUI

```text
/var/lib/cos-desktop/home     -> /home/cos
/var/lib/cos-desktop/machine  -> /var/lib/cos-desktop-persistent
```

### Apple silicon

```text
cos-desktop-home
cos-desktop-machine
```

The machine ID is persisted because browser and desktop credential systems can depend on machine identity remaining stable.

## noVNC exposure

The default Compose file publishes noVNC only to host loopback:

```text
127.0.0.1:6080
```

Do not change this to `0.0.0.0` unless you add a separate authenticated TLS reverse proxy. x11vnc itself is also loopback-only and has no VNC password.

## Validation

Run:

```bash
./scripts/validate.sh
```

This checks shell syntax, Compose configuration, architecture contracts, and required files.

## Updating CoS

CoS DEB installs do not self-update in place. Update the pinned version, download URL, and SHA-256 values in:

- `Dockerfile` for AMD64 defaults
- `scripts/build-arm64.sh` for ARM64 overrides
- the version shown in the example deploy files

Then rebuild the image. Persistent application and browser state remains in the home volume.

## Security

See [SECURITY.md](SECURITY.md).

This container intentionally gives the desktop user passwordless root access inside the container, matching the convenience model of the source desktop container. A CoS tool with command execution can therefore obtain container root. Treat the CoS MCP connection, browser session, and persistent home as sensitive credentials.
