# Deployment Guide

## Overview

Installation, configuration, and deployment of Utix across different
environments and Linux distributions.

## Prerequisites

### System Requirements

**Minimum**:

- Linux kernel 3.10+
- Bash 4.0+
- curl
- 50MB disk space

**Supported Distributions**:

- Ubuntu 18.04+ / Debian 10+
- Alpine Linux 3.14+
- Fedora 34+ / RHEL 8+

**Optional Dependencies**:

- jq (improves JSON parsing)
- gum (modern TUI) or whiptail (legacy)
- Go 1.22+ (for Go CLI)

**Install gum** ([charmbracelet/gum](https://github.com/charmbracelet/gum)):

```bash
# macOS/Linux (Homebrew)
brew install gum

# Arch Linux
pacman -S gum

# Fedora/EPEL
dnf install gum

# Alpine
apk add gum

# Debian/Ubuntu
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
sudo apt update && sudo apt install gum
```

### Network Requirements

**Outbound HTTPS Access**:

- raw.githubusercontent.com (registry)
- github.com (releases)

**Proxy Configuration**:

```bash
export https_proxy="http://proxy.company.com:8080"
export HTTPS_PROXY="http://proxy.company.com:8080"
```

## Installation Methods

### Method 1: Quick Install (Recommended)

```bash
# From latest release
curl -fsSL https://raw.githubusercontent.com/lamngockhuong/utix/main/install.sh | sudo bash

# From develop branch
curl -fsSL https://raw.githubusercontent.com/lamngockhuong/utix/develop/install.sh | sudo bash -s -- --branch develop
```

**What It Does**:

1. Downloads latest release tarball
2. Verifies SHA256 checksum
3. Installs to /usr/local/bin
4. Sets up libraries in /usr/local/lib/utix

### Method 2: Manual Installation

```bash
VERSION="1.0.0"
wget https://github.com/lamngockhuong/utix/releases/download/v${VERSION}/utix-${VERSION}.tar.gz

# Verify checksum
wget https://github.com/lamngockhuong/utix/releases/download/v${VERSION}/checksums.txt
sha256sum -c checksums.txt

# Extract and install
tar -xzf utix-${VERSION}.tar.gz
cd utix-${VERSION}
sudo ./install.sh
```

**Manual Steps** (without install.sh):

```bash
sudo mkdir -p /usr/local/bin /usr/local/lib/utix/lib
sudo cp utix /usr/local/bin/
sudo cp -r lib/* /usr/local/lib/utix/lib/
sudo chmod 755 /usr/local/bin/utix
sudo chmod 755 /usr/local/lib/utix/lib/*.sh
utix version
```

### Method 3: Install from Source

```bash
git clone https://github.com/lamngockhuong/utix.git
cd utix
sudo ./install.sh --source .

# Build Go CLI (optional)
cd cli
make build
sudo make install
```

### Method 4: Go CLI Binary Only

```bash
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
case "$ARCH" in
  x86_64) ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
esac

VERSION="1.0.0"
BINARY="utix-go-${OS}-${ARCH}"
curl -fsSL -o utix-go \
  "https://github.com/lamngockhuong/utix/releases/download/cli-v${VERSION}/${BINARY}"

chmod +x utix-go
sudo mv utix-go /usr/local/bin/
utix-go version
```

**Available Platforms**: linux/amd64, linux/arm64, darwin/amd64, darwin/arm64

## Distribution-Specific Instructions

### Ubuntu / Debian

```bash
sudo apt update
sudo apt install -y curl bash jq  # Optional: install gum for modern TUI
curl -fsSL https://raw.githubusercontent.com/lamngockhuong/utix/main/install.sh | sudo bash
utix version
```

### Alpine Linux

```bash
apk add --no-cache bash curl jq newt
curl -fsSL https://raw.githubusercontent.com/lamngockhuong/utix/main/install.sh | sudo bash
which bash  # Verify bash is in PATH
```

### Fedora / RHEL / CentOS

```bash
sudo dnf install -y curl bash jq newt
curl -fsSL https://raw.githubusercontent.com/lamngockhuong/utix/main/install.sh | sudo bash
```

### Arch Linux

```bash
sudo pacman -S curl bash jq libnewt
curl -fsSL https://raw.githubusercontent.com/lamngockhuong/utix/main/install.sh | sudo bash
```

### macOS

```bash
brew install bash curl jq  # macOS uses bash 3.x by default

# Or use Go CLI (recommended)
curl -fsSL -o utix-go \
  https://github.com/lamngockhuong/utix/releases/download/cli-v1.0.0/utix-go-darwin-arm64
chmod +x utix-go
sudo mv utix-go /usr/local/bin/
```

## Configuration

### Environment Variables

```bash
# ~/.bashrc or ~/.zshrc
export UTIX_LOG_LEVEL="info"              # debug, info, warn, error
export UTIX_CACHE_DIR="$HOME/.utix/cache"
export UTIX_OFFLINE=1                      # Enable offline mode
export UTIX_REGISTRY_URL="https://custom-registry.com/manifest.json"
```

### Cache Configuration

**Default Location**: `~/.utix/cache/`

```bash
# Custom cache location
export UTIX_CACHE_DIR="/mnt/data/utix-cache"
mkdir -p "$UTIX_CACHE_DIR"

# Cache management
utix cache list
utix cache size
utix cache clear docker-prune
utix cache clear  # Clear all
```

### Offline Mode

```bash
export UTIX_OFFLINE=1

# Pre-cache scripts while online
utix run backup-home
utix run system-info

# Scripts execute from cache
utix run backup-home  # Works
utix run new-script   # Error: not cached
```

## Verification

```bash
# Check installation
which utix
utix version
ls -la /usr/local/lib/utix/lib/

# Test commands
utix list
utix search git
utix info system-info
utix run system-info

# Test connectivity
curl -fsSL https://raw.githubusercontent.com/lamngockhuong/utix/main/registry/manifest.json | head
```

## Upgrading

### Upgrade Bash CLI

```bash
# Re-run installer
curl -fsSL https://raw.githubusercontent.com/lamngockhuong/utix/main/install.sh | sudo bash

# Or manual upgrade
sudo cp /usr/local/bin/utix /usr/local/bin/utix.backup
VERSION="1.1.0"
wget https://github.com/lamngockhuong/utix/releases/download/v${VERSION}/utix-${VERSION}.tar.gz
tar -xzf utix-${VERSION}.tar.gz && cd utix-${VERSION}
sudo ./install.sh
```

### Upgrade Go CLI

```bash
VERSION="1.1.0"
curl -fsSL -o utix-go \
  "https://github.com/lamngockhuong/utix/releases/download/cli-v${VERSION}/utix-go-linux-amd64"
chmod +x utix-go
sudo mv utix-go /usr/local/bin/
```

### Update Scripts

```bash
utix update           # Update all
utix update docker-prune  # Update specific

# Force re-download
utix cache clear docker-prune
utix run docker-prune
```

## Uninstallation

```bash
# Using install.sh
sudo /usr/local/bin/utix --uninstall

# Manual removal
sudo rm -f /usr/local/bin/utix /usr/local/bin/utix-go
sudo rm -rf /usr/local/lib/utix
rm -rf ~/.utix  # Optional: remove cache
```

## Related Documentation

- [Enterprise Deployment](./deployment-enterprise.md)
- [System Architecture](./system-architecture.md)
- [Code Standards](./code-standards.md)
