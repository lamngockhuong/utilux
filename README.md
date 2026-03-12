# Utix

Lightweight script aggregator with lazy loading. Scripts are downloaded
on-demand from GitHub, cached locally, and executed.

## Installation

### Quick Install (Bash CLI)

```bash
curl -fsSL https://raw.githubusercontent.com/lamngockhuong/utix/main/install.sh | sudo bash
```

### Go CLI (Optional)

Download pre-built binary from
[Releases](https://github.com/lamngockhuong/utix/releases) or build from source:

```bash
cd cli
go build -ldflags "-s -w" -o utix-go .
sudo mv utix-go /usr/local/bin/
```

## Usage

```bash
# Launch interactive TUI menu
utix

# Run a script (downloads on first use)
utix run git-clean
utix run backup-home /path/to/backup

# List available scripts
utix list
utix list dev

# Search scripts
utix search docker

# Show script details
utix info git-clean

# Update cached scripts
utix update --all

# Cache management
utix cache list
utix cache size
utix cache clear
```

## Available Scripts

| Category   | Script       | Description                                     |
| ---------- | ------------ | ----------------------------------------------- |
| automation | backup-home  | Backup home directory to compressed archive     |
| automation | cron-helper  | Interactively manage cron jobs                  |
| dev        | docker-prune | Clean unused Docker images/containers/volumes   |
| dev        | env-setup    | Setup development environment with common tools |
| dev        | git-clean    | Clean merged branches, prune remotes            |
| network    | port-scan    | Scan open ports on a host                       |
| network    | ssl-check    | Check SSL certificate expiry and details        |
| system     | disk-cleanup | Clean temporary files, old logs, package cache  |
| system     | log-rotate   | Rotate, compress, and manage log files          |
| system     | system-info  | Display comprehensive system information        |

## Architecture

```
utix (Bash CLI)          # Interactive menu + CLI commands
├── lib/                   # Core modules (config, cache, registry, loader, ui)
└── ~/.utix/             # Local cache directory

cli/ (Go CLI)              # Optional high-performance CLI
├── cmd/                   # Cobra commands
└── internal/              # Registry, cache, loader, TUI

registry/                  # Script registry
├── manifest.json          # Script metadata + SHA256 hashes
└── {category}/*.sh        # Actual scripts

website/                   # Astro documentation site
```

## Configuration

Environment variables:

| Variable            | Description                           | Default    |
| ------------------- | ------------------------------------- | ---------- |
| `UTIX_LOG_LEVEL`    | Log level: debug, info, warn, error   | info       |
| `UTIX_OFFLINE`      | Offline mode (1/0)                    | 0          |
| `UTIX_DEV_MODE`     | Run from local source, no cache (1/0) | 0          |
| `UTIX_CACHE_DIR`    | Custom cache directory                | ~/.utix    |
| `UTIX_REGISTRY_URL` | Custom registry URL                   | GitHub raw |

## Development

```bash
# Launch dev container
# Uses docker or podman (auto-detected)
make dev                    # Ubuntu 22.04 (default)
make dev DISTRO=alpine      # Alpine Linux
make dev DISTRO=fedora      # Fedora

# Build Go CLI
cd cli && go build -o utix-go .

# Format code
npm install && npm run format      # Markdown (dprint)
npm run format:sh                  # Shell (shfmt)
cd website && pnpm install && pnpm run check:fix  # JS/TS (Biome)

# Create release package
./package.sh <version>
```

## Requirements

- Bash 4.0+
- curl
- Optional: jq (better JSON parsing),
  [gum](https://github.com/charmbracelet/gum) (modern TUI) or whiptail (legacy
  TUI)
- Go 1.22+ (for Go CLI)
- Docker or Podman (for development containers)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute.

## Author

**Lam Ngoc Khuong** - [khuong.dev](https://khuong.dev) -
[hi@khuong.dev](mailto:hi@khuong.dev)

## License

BSD-3-Clause
