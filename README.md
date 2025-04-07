# Utilux
Utilities for Linux

## Develop

```bash
make dev                # Launch with Ubuntu by default
make dev DISTRO=alpine  # Launch with Alpine Linux
make dev DISTRO=fedora  # Launch with Fedora
```

Inside the container:

```bash
apk add --no-cache bash curl whiptail   # Alpine
apt update && apt install -y curl whiptail bash  # Ubuntu/Debian

chmod +x tool.sh
./tool.sh
```
