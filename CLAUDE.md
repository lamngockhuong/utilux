# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Utilux is a Linux utility management tool written in bash. It provides a unified interface for package management across Ubuntu/Debian, Alpine, and Fedora distributions. The tool supports installing packages from system repos, GitHub releases, and direct URLs.

## Development Commands

```bash
# Launch dev container (uses Podman)
make dev                    # Ubuntu 22.04 (default)
make dev DISTRO=alpine      # Alpine Linux
make dev DISTRO=fedora      # Fedora

# Inside container: install dependencies
apk add --no-cache bash curl whiptail   # Alpine
apt update && apt install -y curl whiptail bash  # Ubuntu/Debian

# Run the tool
chmod +x utilux && ./utilux

# Install from source (requires root)
sudo ./install.sh --source .

# Create release package
./package.sh <version>      # Creates build/utilux-<version>.tar.gz

# Clean build artifacts
make clean
```

## Architecture

```
utilux                       # Bash CLI: interactive menu + commands
└── lib/
    ├── core.sh              # Shared functions (logging, utilities)
    ├── config.sh            # Configuration management
    ├── cache.sh             # Local script caching
    ├── registry.sh          # Script registry (manifest.json)
    ├── loader.sh            # Script download + execution
    └── ui.sh                # Interactive UI (whiptail)

cli/                         # Go CLI (optional, high-performance)
├── cmd/                     # Cobra commands (run, list, search, info, update, cache)
└── internal/
    ├── registry/            # Manifest fetching + parsing
    ├── cache/               # Local cache management
    ├── loader/              # Download, verify, execute
    └── tui/                 # Bubbletea spinner, list, styles

registry/                    # Script registry
├── manifest.json            # Script metadata + SHA256 hashes
└── {category}/*.sh          # Actual scripts (automation, dev, network, system)

website/                     # Astro documentation site
```

### Installation Paths (Constants)

- `INSTALL_BIN_DIR`: /usr/local/bin (main executable)
- `INSTALL_LIB_BASE`: /usr/local/lib (library modules)
- `DEFAULT_APP_NAME`: utilux

**Key patterns:**

- Scripts are lazy-loaded: downloaded on first use, cached locally
- `manifest.json` contains script metadata + SHA256 hashes for integrity verification
- Bash CLI uses whiptail for interactive menus
- Go CLI uses cobra (commands) + bubbletea (TUI)
- Both CLIs share the same registry and cache format

## Adding New Scripts

1. Create script in `registry/{category}/{script-name}.sh`
2. Add entry to `registry/manifest.json` with name, description, version, sha256, tags, requires
3. Test: `utilux run {script-name}`

## Environment Variables

- `UTILUX_LOG_LEVEL`: Set to `info`, `warn`, `error`, or `debug`
- `UTILUX_API_KEY`: API key for custom package servers (optional)
