# Utilux

Lightweight script aggregator with lazy loading. Scripts are downloaded on-demand from GitHub, cached locally, and executed.

## Installation

### Quick Install (Bash CLI)

```bash
curl -fsSL https://raw.githubusercontent.com/lamngockhuong/utilux/develop/install.sh | sudo bash
```

### Go CLI (Optional)

Download pre-built binary from [Releases](https://github.com/lamngockhuong/utilux/releases) or build from source:

```bash
cd cli
go build -ldflags "-s -w" -o utilux-go .
sudo mv utilux-go /usr/local/bin/
```

## Usage

```bash
# Run a script (downloads on first use)
utilux run git-clean
utilux run backup-home /path/to/backup

# List available scripts
utilux list
utilux list dev

# Search scripts
utilux search docker

# Show script details
utilux info git-clean

# Update cached scripts
utilux update --all

# Cache management
utilux cache list
utilux cache size
utilux cache clear
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
utilux (Bash CLI)          # Interactive menu + CLI commands
├── lib/                   # Core modules (config, cache, registry, loader, ui)
└── ~/.utilux/             # Local cache directory

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

| Variable              | Description                         | Default    |
| --------------------- | ----------------------------------- | ---------- |
| `UTILUX_LOG_LEVEL`    | Log level: debug, info, warn, error | info       |
| `UTILUX_OFFLINE`      | Offline mode (1/0)                  | 0          |
| `UTILUX_CACHE_DIR`    | Custom cache directory              | ~/.utilux  |
| `UTILUX_REGISTRY_URL` | Custom registry URL                 | GitHub raw |

## Development

```bash
# Launch dev container
# Uses docker or podman (auto-detected)
make dev                    # Ubuntu 22.04 (default)
make dev DISTRO=alpine      # Alpine Linux
make dev DISTRO=fedora      # Fedora

# Build Go CLI
cd cli && go build -o utilux-go .

# Create release package
./package.sh <version>
```

## Requirements

- Bash 4.0+
- curl
- Optional: jq (better JSON parsing), whiptail (interactive UI)
- Go 1.22+ (for Go CLI)
- Docker or Podman (for development containers)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute.

## License

MIT
