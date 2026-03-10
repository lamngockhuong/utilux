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

# Run the tool interactively
chmod +x tool.sh && ./tool.sh

# Install from source (requires root)
sudo ./install.sh --source .

# Create release package
./package.sh <version>      # Creates build/utilux-<version>.tar.gz

# Clean build artifacts
make clean
```

## Architecture

The codebase supports two installation structures:

### New Structure (utilux + lib/)

```
utilux                       # Entry point: CLI/interactive menu
└── lib/
    ├── core.sh              # Shared functions (logging, utilities)
    ├── registry.sh          # Script registry management
    └── *.sh                 # Additional library modules
```

### Legacy Structure (tool.sh + scripts/)

```
tool.sh                      # Entry point: CLI/interactive menu
├── scripts/core.sh          # Shared functions (logging, install_utilities, require_root)
├── scripts/distro-detect.sh # Auto-detects distro, loads appropriate adapter
├── scripts/logging.sh       # Logging utilities with color support
└── scripts/{distro}/        # Distro adapters implementing install_package/remove_package
    ├── ubuntu/ubuntu.sh     # apt-get wrapper
    ├── alpine/alpine.sh     # apk wrapper
    └── fedora/fedora.sh     # dnf wrapper
```

### Installation Paths (Constants)

- `INSTALL_BIN_DIR`: /usr/local/bin (main executable)
- `INSTALL_LIB_BASE`: /usr/local/lib (library modules)
- `DEFAULT_APP_NAME`: utilux

**Key patterns:**

- `detect_source_structure()` returns "new", "legacy", or "invalid"
- `install_core_scripts()` dispatches to appropriate installer based on structure
- Each distro adapter must implement: `update_package_list()`, `install_package()`, `remove_package()`
- Adapters call `require_root` at load time (not deferred)
- `install.sh` handles installation from release, develop branch, or local source
- `package.sh` creates .tar.gz releases for GitHub

## Adding New Distribution Support

1. Create `scripts/{distro}/{distro}.sh` with the three required functions
2. Add case entry in `scripts/distro-detect.sh:load_distro_script()`
3. Test in container: `make dev DISTRO={distro}`

## Environment Variables

- `UTILUX_LOG_LEVEL`: Set to `info`, `warn`, `error`, or `debug`
- `UTILUX_API_KEY`: API key for custom package servers (optional)
