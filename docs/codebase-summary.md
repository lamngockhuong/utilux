# Codebase Summary

## Project Statistics

- **Total Files**: 67 files
- **Total Tokens**: 63,416 tokens
- **Total Characters**: 217,470 chars
- **Primary Languages**: Bash, Go, JavaScript (Astro)

## Directory Structure

```
utilux/
├── cli/                      # Go CLI implementation
│   ├── cmd/                  # Cobra command definitions
│   ├── internal/             # Internal Go packages
│   │   ├── cache/           # Cache management
│   │   ├── loader/          # Script download/execution
│   │   ├── registry/        # Manifest fetching
│   │   └── tui/             # Bubbletea TUI components
│   ├── main.go              # Go CLI entry point
│   ├── Makefile             # Build automation
│   └── go.mod               # Go dependencies
│
├── lib/                      # Bash CLI modules (new architecture)
│   ├── cache.sh             # Local script caching
│   ├── config.sh            # Configuration management
│   ├── core.sh              # Logging, helpers, error handling
│   ├── loader.sh            # Script download/execution
│   ├── registry.sh          # Manifest fetching/parsing
│   └── ui.sh                # Interactive whiptail TUI
│
├── registry/                 # Script registry
│   ├── automation/          # Automation scripts
│   │   ├── backup-home.sh
│   │   └── cron-helper.sh
│   ├── dev/                 # Development tools
│   │   ├── docker-prune.sh
│   │   ├── env-setup.sh
│   │   └── git-clean.sh
│   ├── network/             # Network utilities
│   │   ├── port-scan.sh
│   │   └── ssl-check.sh
│   ├── system/              # System administration
│   │   ├── disk-cleanup.sh
│   │   ├── log-rotate.sh
│   │   └── system-info.sh
│   └── manifest.json        # Script metadata + SHA256 hashes
│
├── scripts/                  # Legacy scripts + distro detection
│   ├── alpine/
│   │   └── alpine.sh
│   ├── fedora/
│   │   └── fedora.sh
│   ├── ubuntu/
│   │   └── ubuntu.sh
│   ├── core.sh              # Core utilities
│   ├── distro-detect.sh     # Distribution detection
│   ├── generate-manifest.sh # Generate manifest.json
│   └── logging.sh           # Logging functions
│
├── website/                  # Astro documentation site
│   ├── src/
│   │   ├── components/      # Reusable UI components
│   │   │   ├── CopyButton.astro
│   │   │   └── ScriptCard.astro
│   │   ├── layouts/
│   │   │   └── BaseLayout.astro
│   │   ├── pages/
│   │   │   ├── catalog/    # Script catalog pages
│   │   │   ├── docs/       # Documentation pages
│   │   │   └── index.astro # Homepage
│   │   └── styles/
│   │       └── global.css
│   └── public/              # Static assets
│
├── .github/
│   └── workflows/
│       ├── deploy-website.yml    # Website deployment
│       └── go-cli-release.yml    # Go CLI releases
│
├── utilux                    # Main Bash CLI executable
├── tool.sh                   # Legacy CLI (deprecated)
├── install.sh                # Installation script (4,504 tokens)
├── package.sh                # Release packager
├── Makefile                  # Dev container commands
├── CLAUDE.md                 # AI assistant instructions
└── README.md                 # Project readme
```

## Key Components

### 1. Bash CLI (`utilux`)

**Location**: `/utilux`
**Size**: 3,288 tokens, 11,287 chars
**Purpose**: Main Bash CLI entry point with modular architecture

**Dependencies**:

- lib/core.sh - Core utilities
- lib/config.sh - Configuration
- lib/cache.sh - Cache management
- lib/registry.sh - Registry operations
- lib/loader.sh - Script loading
- lib/ui.sh - Interactive UI

**Key Functions**:

- `cmd_run()` - Execute script by name
- `cmd_list()` - List available scripts
- `cmd_search()` - Search scripts by query
- `cmd_info()` - Show script details
- `cmd_update()` - Update cached scripts
- `cmd_cache()` - Manage cache

### 2. Go CLI (`cli/`)

**Location**: `/cli/`
**Language**: Go 1.22+
**Purpose**: High-performance compiled CLI alternative

**Architecture**:

```
cli/
├── main.go                    # Entry point, version handling
├── cmd/root.go               # Root command + global flags
├── cmd/run.go                # Execute scripts
├── cmd/list.go               # List scripts
├── cmd/search.go             # Search functionality
├── cmd/info.go               # Script info
├── cmd/update.go             # Update scripts
├── cmd/cache.go              # Cache management
├── internal/cache/cache.go   # Cache implementation
├── internal/loader/loader.go # Download + execute
├── internal/registry/        # Registry client
│   ├── fetch.go             # Manifest fetching
│   └── types.go             # Data structures
└── internal/tui/             # Terminal UI
    ├── list.go              # List rendering
    ├── spinner.go           # Loading spinner
    └── styles.go            # Style definitions
```

**Key Features**:

- Cobra for command structure
- Bubbletea for interactive TUI
- Singleton pattern for registry/cache
- Cross-platform builds via GitHub Actions

### 3. Registry System (`registry/`)

**Location**: `/registry/`
**Purpose**: Centralized script storage with integrity verification

**manifest.json Structure**:

```json
{
  "version": "1.0.0",
  "updated": "2024-03-10T00:00:00Z",
  "scripts": [
    {
      "name": "script-name",
      "version": "v1.0.0",
      "description": "Script description",
      "category": "automation|dev|network|system",
      "path": "registry/category/script-name.sh",
      "url": "https://raw.githubusercontent.com/.../script-name.sh",
      "sha256": "abc123...",
      "requires": ["package1", "package2"],
      "tags": ["tag1", "tag2"],
      "author": "username"
    }
  ]
}
```

**Script Metadata Format** (in script headers):

```bash
#!/bin/bash
# @name: script-name
# @version: v1.0.0
# @description: Script description
# @category: system
# @requires: curl, jq
# @tags: cleanup, maintenance
# @author: username
```

**Current Scripts** (10 total):

**automation/** (2 scripts)

- `backup-home.sh`: Home directory backup with rotation
- `cron-helper.sh`: Interactive cron job manager

**dev/** (3 scripts)

- `docker-prune.sh`: Docker cleanup (images, containers, volumes)
- `env-setup.sh`: Dev environment setup (2,944 tokens - largest script)
- `git-clean.sh`: Git repository cleanup

**network/** (2 scripts)

- `port-scan.sh`: Port scanning utility
- `ssl-check.sh`: SSL certificate checker (2,729 tokens)

**system/** (3 scripts)

- `disk-cleanup.sh`: Disk space cleanup
- `log-rotate.sh`: Log rotation utility
- `system-info.sh`: System information display

### 4. Library Modules (`lib/`)

**lib/core.sh** - Core utilities

- Logging functions (log_debug, log_info, log_warn, log_error)
- Error handling (die function)
- String manipulation helpers
- File operations wrappers

**lib/config.sh** - Configuration management

- Environment variable handling
- Config file parsing
- Default value setup
- Validation functions

**lib/cache.sh** - Cache management

- Cache directory structure: ~/.utilux/cache/{script-name}/
- Version tracking
- Size calculation
- Cleanup operations

**lib/registry.sh** - Registry operations

- Manifest fetching from GitHub
- JSON parsing (using jq or fallback)
- Script metadata extraction
- Version comparison

**lib/loader.sh** - Script loading

- Download from registry URL
- SHA256 verification
- Cache storage
- Execution with argument forwarding

**lib/ui.sh** - Interactive UI

- Whiptail-based menus
- Category selection
- Script picker
- Progress indicators

### 5. Installation System (`install.sh`)

**Location**: `/install.sh`
**Size**: 4,504 tokens (largest file)
**Purpose**: Multi-mode installation script

**Installation Modes**:

1. **Release Mode** (default): Install from GitHub release tarball
2. **Develop Mode**: Install from develop branch
3. **Local Mode**: Install from current directory

**Installation Paths**:

- Binary: `/usr/local/bin/utilux`
- Libraries: `/usr/local/lib/utilux/lib/`
- Registry: Not installed (fetched on-demand)

**Features**:

- Checksum verification for releases
- Backup of existing installation
- Dependency checking (curl, bash)
- Uninstall functionality
- Multi-distro support

### 6. Website (`website/`)

**Framework**: Astro 5.x (pnpm)
**Purpose**: Documentation and script catalog

**Pages**:

- `/` - Homepage with feature overview
- `/catalog/` - Script catalog grid
- `/catalog/[slug]` - Individual script pages
- `/docs/` - Documentation hub

**Components**:

- `ScriptCard.astro` - Script display card
- `CopyButton.astro` - Copy-to-clipboard button
- `BaseLayout.astro` - Site-wide layout

**Deployment**: GitHub Pages via GitHub Actions

## Data Flow

### Script Execution Flow

```
User: utilux run docker-prune
  ↓
1. Parse command (cmd/run or cmd_run)
  ↓
2. Check cache (~/.utilux/cache/docker-prune/)
  ↓
3. If cached → Verify version → Execute
  ↓
4. If not cached:
   a. Fetch manifest.json from GitHub
   b. Find script metadata
   c. Download script from registry URL
   d. Verify SHA256 hash
   e. Store in cache
   f. Execute script
  ↓
5. Forward exit code to user
```

### Cache Structure

```
~/.utilux/
├── cache/
│   ├── docker-prune/
│   │   ├── docker-prune.sh
│   │   └── .version (contains: v1.0.0)
│   ├── git-clean/
│   │   ├── git-clean.sh
│   │   └── .version
│   └── ...
└── config (future)
```

### Registry Update Flow

```
1. Developer modifies script in registry/
  ↓
2. Run: scripts/generate-manifest.sh
  ↓
3. Generates:
   - Extracts metadata from @name, @version, etc.
   - Calculates SHA256 for each script
   - Updates manifest.json
  ↓
4. Commit and push to GitHub
  ↓
5. Users fetch updated manifest
  ↓
6. Compare cached version vs manifest version
  ↓
7. Download updated scripts if version mismatch
```

## Code Patterns

### Error Handling Pattern

**Bash**:

```bash
set -euo pipefail  # Strict mode

die() {
  log_error "$*"
  exit 1
}

# Usage
[[ -f "$file" ]] || die "File not found: $file"
```

**Go**:

```go
if err != nil {
  return fmt.Errorf("operation failed: %w", err)
}
```

### Logging Pattern

**Bash**:

```bash
log_debug "Fetching manifest from $url"
log_info "Cached script found: $name"
log_warn "Network unavailable, using cache"
log_error "SHA256 mismatch for $name"
```

**Go**:

```go
if logLevel == "debug" {
  fmt.Fprintf(os.Stderr, "[DEBUG] %s\n", msg)
}
```

### Distro Detection Pattern

```bash
detect_distro() {
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    echo "$ID"
  elif [[ -f /etc/alpine-release ]]; then
    echo "alpine"
  else
    echo "unknown"
  fi
}
```

## External Dependencies

### Runtime Dependencies

- **bash** 4.0+ (required)
- **curl** (required for downloads)
- **jq** (optional, improves JSON parsing)
- **whiptail** (optional, enables interactive menu)

### Build Dependencies

- **Go** 1.22+ (for Go CLI)
- **Node.js** 20+ (for website)
- **pnpm** 10+ (for website)

### CI/CD Dependencies

- GitHub Actions
- GitHub Pages
- actions/checkout@v4
- actions/setup-node@v4
- actions/setup-go@v5

## File Size Analysis

**Top 5 Files by Token Count**:

1. install.sh - 4,504 tokens (17,094 chars) - 7.1%
2. utilux - 3,288 tokens (11,287 chars) - 5.2%
3. registry/dev/env-setup.sh - 2,944 tokens (9,884 chars) - 4.6%
4. registry/network/ssl-check.sh - 2,729 tokens (8,750 chars) - 4.3%
5. registry/automation/cron-helper.sh - 2,504 tokens (7,814 chars) - 3.9%

## Security Considerations

1. **SHA256 Verification**: All scripts verified before execution
2. **HTTPS-Only**: Registry and script downloads over HTTPS
3. **No Code Injection**: Scripts executed as-is, no eval/source of untrusted input
4. **Minimal Privileges**: Most scripts run as regular user
5. **Transparent Source**: All code visible in registry/ directory

## Testing Strategy

**Current State**: Manual testing via:

- `make dev` - Launch test containers (Ubuntu/Alpine/Fedora)
- `.claude/settings.local.json` - Permitted test commands
- GitHub Actions - Build verification

**Future Testing**:

- Unit tests for lib/ modules
- Integration tests for CLI commands
- Script validation tests
- Cross-distro compatibility tests

## Performance Characteristics

**Bash CLI**:

- Cold start: ~50-100ms (depends on lib/ sourcing)
- Script list (cached manifest): ~100-200ms
- Script download + cache: 1-3s (network dependent)

**Go CLI**:

- Cold start: ~10-50ms (compiled binary)
- Script list (cached manifest): ~20-50ms
- Script download + cache: 1-2s (network dependent)

## Migration Notes

**Legacy to Modern Architecture**:

- `tool.sh` (legacy) → `utilux` (modern)
- Monolithic script → Modular lib/ approach
- Inline functions → Separate module files
- Hard-coded paths → Environment variable driven

**Bash to Go Migration**:

- Feature parity achieved
- Go CLI is optional upgrade path
- Both CLIs share same registry format
- Users can switch transparently

## Related Documentation

- [Project Overview & PDR](./project-overview-pdr.md)
- [Code Standards](./code-standards.md)
- [System Architecture](./system-architecture.md)
- [Deployment Guide](./deployment-guide.md)
