---
title: "env-setup"
description: "Setup development environment with common tools"
category: "dev"
version: "v1.0.0"
tags: ["dev","setup","tools"]
requires: ["curl"]
author: "lamngockhuong"
---

## Overview

Automates installation of development tools across different Linux
distributions. Supports Node.js, Python, Go, Rust, Docker, and common utilities
with automatic package manager detection.

## Requirements

| Dependency | Description                   |
| ---------- | ----------------------------- |
| `curl`     | For downloading installers    |
| `sudo`     | For system-wide installations |

## Usage

```bash
utix run env-setup [OPTIONS]
```

### Options

| Option     | Short | Description                        |
| ---------- | ----- | ---------------------------------- |
| `--all`    | `-a`  | Install everything                 |
| `--basic`  | `-b`  | Basic tools (git, curl, vim, etc.) |
| `--build`  | `-B`  | Build tools (gcc, make, etc.)      |
| `--node`   | `-n`  | Node.js via nvm                    |
| `--python` | `-p`  | Python3 and pip                    |
| `--go`     | `-g`  | Go programming language            |
| `--rust`   | `-r`  | Rust via rustup                    |
| `--docker` | `-d`  | Docker and Docker Compose          |
| `--git`    | `-G`  | Configure Git                      |
| `--help`   | `-h`  | Show help                          |

## Examples

### Basic Usage

```bash
# Show usage
utix run env-setup

# Install basic tools
utix run env-setup -b

# Install everything
utix run env-setup -a
```

### Selective Installation

```bash
# Node.js only
utix run env-setup -n

# Node.js and Docker
utix run env-setup -n -d

# Python and Go
utix run env-setup -p -g

# Build tools for compiling
utix run env-setup -B
```

### Git Configuration

```bash
# Configure Git (name, email, defaults)
utix run env-setup -G
```

## What Gets Installed

### Basic Tools (`-b`)

- git, curl, wget
- vim, htop, tree
- jq, unzip, tar, gzip

### Build Tools (`-B`)

- build-essential (Ubuntu/Debian)
- Development Tools (Fedora/RHEL)
- base-devel (Arch)
- build-base (Alpine)

### Node.js (`-n`)

- nvm (Node Version Manager)
- Latest LTS Node.js
- npm package manager

### Python (`-p`)

- Python 3
- pip package manager

### Go (`-g`)

- Go 1.22.0
- Adds to PATH in ~/.bashrc

### Rust (`-r`)

- rustup installer
- Latest stable Rust
- cargo package manager

### Docker (`-d`)

- Docker Engine
- Docker Compose plugin
- Adds user to docker group

## Supported Distributions

| Distribution  | Package Manager |
| ------------- | --------------- |
| Ubuntu/Debian | apt             |
| Fedora        | dnf             |
| CentOS/RHEL   | yum             |
| Alpine        | apk             |
| Arch          | pacman          |
| macOS         | brew            |

## Troubleshooting

### Command not found after installation

**Problem:** Installed tool not in PATH

**Solution:** Reload shell or source profile:

```bash
source ~/.bashrc
# or
exec $SHELL
```

### Permission denied

**Problem:** Cannot install packages

**Solution:** Ensure sudo access:

```bash
sudo -v
```

### Docker requires logout

**Problem:** Docker commands need sudo after install

**Solution:** Log out and back in, or:

```bash
newgrp docker
```

### nvm not found

**Problem:** Node.js installed but nvm command missing

**Solution:** Source nvm in current shell:

```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```

### Package manager not detected

**Problem:** Unknown package manager error

**Solution:** Install using distribution-specific commands manually.

## Related Scripts

- `docker-prune` - Clean up Docker resources
- `git-clean` - Clean up Git repositories

## Changelog

- **v1.0.0** - Initial release with multi-distro support
