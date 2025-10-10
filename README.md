# zero-desktop-lxde

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
