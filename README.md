# zero-desktop-lxde

![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)
![GitHub Tag](https://img.shields.io/github/v/tag/zero-desktop/zero-desktop-lxde?label=version&include_prereleases)
![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/zero-desktop/zero-desktop-lxde/build.yml?branch=master)
![Platforms](https://img.shields.io/badge/platform-linux%2Famd64%20%7C%20linux%2Farm64-lightgrey)

Lightweight LXDE desktop environment accessible via VNC.

## Quick Start

```bash
docker run -d \
  -p 5900:5900 \
  -e SYSTEM_USER=docker \
  -e VNC_PASS=yourpassword \
  ghcr.io/zero-desktop/zero-desktop-lxde:latest
```

Connect with any VNC client to `localhost:5900`

> **Note:** This project is distributed via GitHub Container Registry (ghcr.io) only. Not available on Docker Hub.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SYSTEM_USER` | `docker` | Linux user for desktop session |
| `VNC_PASS` | Required | VNC password |
| `RESOLUTION` | `1280x720` | Screen resolution (WxH) |
| `DISPLAY` | `:0` | X11 display number |
| `ALLOW_NOPW` | `false` | Disable VNC password (not recommended) |

## Docker Compose

```yaml
services:
  desktop:
    image: ghcr.io/zero-desktop/zero-desktop-lxde:latest
    ports:
      - "5900:5900"
    environment:
      - SYSTEM_USER=docker
      - VNC_PASS=yourpassword
      - RESOLUTION=1280x720
```

## Installing Applications

After connecting, open terminal and run:

```bash
sudo apt update
sudo apt install firefox-esr
refresh-menu
```

The `refresh-menu` command updates the LXDE menu.

## License

Apache License 2.0 - See [LICENSE](LICENSE) file for details.

Copyright 2024-2025 zero-desktop and José Meira (jmeiracorbal)
