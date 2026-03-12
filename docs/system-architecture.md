# System Architecture

## Overview

Utix is a distributed script management system with client-server architecture
where the "server" is a static GitHub repository and clients are CLI tools (Bash
or Go) that fetch, cache, and execute scripts on-demand.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         GitHub Repository                        │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ registry/                                                 │  │
│  │  ├── manifest.json        ← Single source of truth       │  │
│  │  ├── automation/          ← Script categories            │  │
│  │  ├── dev/                                                │  │
│  │  ├── network/                                            │  │
│  │  └── system/                                             │  │
│  └───────────────────────────────────────────────────────────┘  │
│                              ↓ HTTPS                             │
└──────────────────────────────┼──────────────────────────────────┘
                               ↓
        ┌──────────────────────┴───────────────────────┐
        │                                              │
        ↓                                              ↓
┌───────────────┐                              ┌──────────────┐
│  Bash CLI     │                              │  Go CLI      │
│  (utix)     │                              │  (utix-go) │
├───────────────┤                              ├──────────────┤
│ • lib/core.sh │                              │ • cmd/       │
│ • lib/cache   │                              │ • internal/  │
│ • lib/registry│                              │   - cache    │
│ • lib/loader  │                              │   - registry │
│ • lib/ui.sh   │                              │   - loader   │
└───────┬───────┘                              └──────┬───────┘
        │                                             │
        └─────────────┬───────────────────────────────┘
                      ↓
            ┌─────────────────────┐
            │   Local Cache       │
            │   ~/.utix/cache/  │
            ├─────────────────────┤
            │ script-name/        │
            │  ├── script.sh      │
            │  └── .version       │
            └─────────────────────┘
                      ↓
            ┌─────────────────────┐
            │  Script Execution   │
            └─────────────────────┘
```

## Component Architecture

### 1. Registry (GitHub Repository)

**Purpose**: Static file server for script distribution

**Components**:

- `manifest.json` - Registry index with metadata and checksums
- `registry/{category}/{script}.sh` - Actual script files

**Characteristics**:

- Read-only for clients
- Versioned via Git
- CDN-backed via GitHub

**manifest.json Structure**:

```json
{
  "version": "1.0.0",
  "updated": "2024-03-10T00:00:00Z",
  "scripts": [
    {
      "name": "script-name",
      "version": "v1.0.0",
      "description": "Purpose",
      "category": "system",
      "file": "system/script-name.sh",
      "sha256": "abc123...",
      "docs": "system/script-name.md",
      "docs_sha256": "def456...",
      "requires": ["curl"],
      "tags": ["cleanup", "disk"],
      "author": "username"
    }
  ]
}
```

### 2. Bash CLI Architecture

**Entry Point**: `utix` executable

**Module Structure**:

```
utix (main executable)
  ↓
  ├── lib/core.sh       ← Logging, error handling
  ├── lib/config.sh     ← Configuration, env vars
  ├── lib/cache.sh      ← Cache CRUD operations
  ├── lib/registry.sh   ← Manifest fetch/parse
  ├── lib/loader.sh     ← Script download/verify/execute
  ├── lib/docs.sh       ← Documentation fetch/cache/render
  └── lib/ui.sh         ← Whiptail menus
```

**Key Functions**:

**lib/core.sh**:

```bash
log_debug()    # Debug logging
log_info()     # Info messages
log_warn()     # Warnings
log_error()    # Errors
die()          # Fatal error + exit 1
```

**lib/cache.sh**:

```bash
cache_get()      # Get cached script path
cache_store()    # Store script in cache
cache_version()  # Get cached version
cache_list()     # List all cached scripts
cache_clear()    # Clear cache
```

**lib/registry.sh**:

```bash
registry_fetch()       # Download manifest.json
registry_parse()       # Parse manifest
registry_get_script()  # Extract script metadata
registry_list()        # List all scripts
registry_search()      # Search by name/tag
```

**lib/loader.sh**:

```bash
loader_download()   # Download script
loader_verify()     # Verify SHA256 checksum
loader_execute()    # Execute script with args
```

**lib/docs.sh**:

```bash
docs_fetch()        # Fetch script documentation
docs_cache_get()    # Get cached docs
docs_cache_store()  # Store docs in cache
docs_render()       # Render markdown with glow/bat
```

### 3. Go CLI Architecture

**Entry Point**: `cli/main.go`

**Package Structure**:

```
main.go
  ↓
cmd/root.go (Cobra root command)
  ├── cmd/run.go      → internal/loader
  ├── cmd/list.go     → internal/registry
  ├── cmd/search.go   → internal/registry
  ├── cmd/info.go     → internal/registry
  ├── cmd/update.go   → internal/loader
  └── cmd/cache.go    → internal/cache
```

**Internal Packages**:

**internal/registry**:

```go
type Registry struct {
  url          string
  manifestPath string
  manifest     *Manifest
}

type Script struct {
  Name        string   `json:"name"`
  Version     string   `json:"version"`
  Description string   `json:"description"`
  Category    string   `json:"category"`
  File        string   `json:"file"`
  SHA256      string   `json:"sha256"`
  Docs        string   `json:"docs"`
  DocsSHA256  string   `json:"docs_sha256"`
  Requires    []string `json:"requires"`
  Tags        []string `json:"tags"`
}
```

**internal/cache**:

```go
type Cache struct {
  baseDir string
}

// Methods: Get, Store, Version, List, Remove, Clear, Size
```

**internal/loader**:

```go
type Loader struct {
  registry *registry.Registry
  cache    *cache.Cache
}

// Methods: LoadScript, VerifyChecksum, Execute, UpdateScript
```

**internal/docs**:

```go
type DocsManager struct {
  registry *registry.Registry
  cache    *cache.Cache
  renderer Renderer
}

// Methods: FetchDocs, RenderDocs, GetCachedDocs
```

### 4. Cache System

**Location**: `~/.utix/cache/`

**Structure**:

```
~/.utix/
├── cache/
│   ├── backup-home/
│   │   ├── backup-home.sh    ← Actual script
│   │   └── .version          ← Contains: v1.0.0
│   ├── docker-prune/
│   │   ├── docker-prune.sh
│   │   └── .version
│   └── git-clean/
│       ├── git-clean.sh
│       └── .version
└── docs_cache/
    ├── backup-home.md        ← Cached documentation
    ├── docker-prune.md
    └── git-clean.md
```

**Cache Operations**:

**Read (cache hit)**:

1. Check if `~/.utix/cache/{script}/{script}.sh` exists
2. Read version from `.version` file
3. Compare with manifest version (if online)
4. Execute if version matches

**Write (cache miss)**:

1. Create directory: `~/.utix/cache/{script}/`
2. Download script to temp location
3. Verify SHA256 checksum
4. Atomically move to cache
5. Write version to `.version`

**Update**:

1. Fetch latest manifest
2. Compare cached vs manifest version
3. Download new version if different
4. Verify and replace

**Clear**:

```bash
rm -rf ~/.utix/cache/{script}/  # Specific
rm -rf ~/.utix/cache/*          # All
```

## API Reference

### Bash CLI Commands

```bash
utix [OPTIONS] <COMMAND> [ARGS]

COMMANDS:
  run <script> [args...]   # Execute script
  list [category]          # List scripts
  search <query>           # Search scripts
  info <script> [-d]       # Show script details (--docs for full docs)
  docs <script>            # Show full documentation
  update [script]          # Update cached scripts
  cache <subcommand>       # Manage cache
  version                  # Show version

CACHE SUBCOMMANDS:
  list                     # List cached scripts
  clear [script]           # Clear cache
  size                     # Show cache size
```

### Go CLI Commands

```bash
utix-go [OPTIONS] <COMMAND> [ARGS]

COMMANDS:
  run <script> [args...]   # Execute script
  list [category]          # List scripts (aliases: ls)
  search <query>           # Search scripts
  info <script> [-d]       # Show details (aliases: show, --docs for full docs)
  docs <script>            # Show full documentation
  update [script]          # Update scripts
  cache <subcommand>       # Cache management
  version                  # Show version
```

## Related Documentation

- [Advanced Architecture](./system-architecture-data-flow-and-security.md)
- [Code Standards](./code-standards.md)
- [Deployment Guide](./deployment-guide.md)
