# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Project Overview

Utix is a Unix utility management tool written in bash. It provides a unified
interface for package management across Linux (Ubuntu/Debian, Alpine, Fedora)
and macOS. The tool supports installing packages from system repos, GitHub
releases, and direct URLs.

## Development Commands

```bash
# Launch dev container (uses Podman)
# Uses docker or podman (auto-detected)
make dev                    # Ubuntu 22.04 (default)
make dev DISTRO=alpine      # Alpine Linux
make dev DISTRO=fedora      # Fedora

# Inside container: install dependencies
apk add --no-cache bash curl gum   # Alpine (gum for modern TUI)
apt update && apt install -y curl bash  # Ubuntu/Debian (install gum separately)

# Run the tool
chmod +x utix && ./utix

# Install from source (requires root)
sudo ./install.sh --source .

# Create release package
./package.sh <version>      # Creates build/utix-<version>.tar.gz

# Clean build artifacts
make clean
```

## Architecture

```
utix                       # Bash CLI: interactive menu + commands
└── lib/
    ├── core.sh              # Shared functions (logging, utilities)
    ├── config.sh            # Configuration management
    ├── cache.sh             # Local script caching
    ├── registry.sh          # Script registry (manifest.json)
    ├── loader.sh            # Script download + execution
    └── ui.sh                # Interactive UI (gum > whiptail > simple)

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
- `DEFAULT_APP_NAME`: utix

**Key patterns:**

- Scripts are lazy-loaded: downloaded on first use, cached locally
- `manifest.json` contains script metadata + SHA256 hashes for integrity
  verification
- Bash CLI uses gum for interactive menus (whiptail fallback)
- Go CLI uses cobra (commands) + bubbletea (TUI)
- Both CLIs share the same registry and cache format

## CLI Parity Rule

**IMPORTANT:** Both CLIs (Bash and Go) must maintain feature parity.

- When modifying `./utix` (Bash), apply equivalent changes to `./cli/` (Go)
- When modifying `./cli/` (Go), apply equivalent changes to `./utix` (Bash)
- Features, menu options, and behaviors should match between both CLIs
- TUI implementations differ (gum vs bubbletea) but UX should be consistent

## Adding New Scripts

1. Create script in `registry/{category}/{script-name}.sh` with metadata header:
   ```bash
   #!/bin/bash
   # @name: script-name
   # @version: v1.0.0
   # @description: What this script does
   # @category: automation|dev|network|system
   # @requires: curl, jq
   # @tags: tag1, tag2
   # @author: your-name
   # @draft              # Optional: hides from list/website, still runnable
   ```
2. Create docs in `registry/{category}/{script-name}.md`
3. Run `./generate-manifest.sh` to update manifest.json
4. Test: `UTIX_DEV_MODE=1 ./utix run {script-name}`

### Draft Scripts

Add `# @draft` to script header to mark as work-in-progress:

- Hidden from `utix list`, search, and website catalog
- Still runnable via `utix run <script-name>`
- Remove `# @draft` when ready for release

## Environment Variables

- `UTIX_LOG_LEVEL`: Set to `info`, `warn`, `error`, or `debug`
- `UTIX_DEV_MODE`: Set to `1` to run from local source (no cache, instant
  updates)
- `UTIX_OFFLINE`: Set to `1` to use cached manifest only
- `UTIX_AUTO_UPDATE`: Set to `0` to disable auto-update checks
