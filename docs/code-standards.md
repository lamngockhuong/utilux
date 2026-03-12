# Code Standards

## General Principles

**Core Philosophy**: YAGNI, KISS, DRY

**Design Goals**:

- Readability over cleverness
- Modularity over monolithic code
- Explicit over implicit behavior
- Fail-fast with clear error messages

## File Naming Conventions

### Bash Scripts

- Use kebab-case: `backup-home.sh`, `docker-prune.sh`
- Extension: `.sh` for all shell scripts

### Go Files

- Use snake_case for packages: `cache`, `registry`
- Use camelCase for filenames: `cache.go`, `fetch.go`

### Documentation

- Use kebab-case: `project-overview-pdr.md`, `code-standards.md`
- Extension: `.md` for markdown

## Directory Structure Rules

### Bash CLI Organization

```
lib/                          # Shared library modules
├── core.sh                   # Logging, error handling
├── config.sh                 # Configuration
├── cache.sh                  # Cache operations
├── registry.sh               # Registry fetching
├── loader.sh                 # Script execution
└── ui.sh                     # Interactive UI

registry/                     # Script registry
├── {category}/
│   └── {script-name}.sh
└── manifest.json

lib/                          # Core library modules
├── core.sh                   # Logging, error handling
├── config.sh                 # Configuration
├── cache.sh                  # Cache operations
├── registry.sh               # Registry fetching
├── loader.sh                 # Script execution
└── ui.sh                     # Interactive UI
```

### Go CLI Organization

```
cli/
├── main.go                   # Entry point
├── cmd/                      # Cobra commands
│   ├── root.go
│   └── {command}.go
└── internal/                 # Internal packages
    ├── cache/
    ├── loader/
    ├── registry/
    └── tui/
```

## Bash Coding Standards

### Script Header Template

```bash
#!/bin/bash
# @name: script-name
# @version: v1.0.0
# @description: Brief description
# @category: automation|dev|network|system
# @requires: dependency1, dependency2
# @tags: tag1, tag2
# @author: github-username

set -euo pipefail
```

### Strict Mode

```bash
set -euo pipefail
# -e: Exit on command failure
# -u: Exit on undefined variable
# -o pipefail: Exit on pipe failure
```

### Variable Naming

**Constants** (uppercase):

```bash
CACHE_DIR="$HOME/.utix/cache"
DEFAULT_REGISTRY_URL="https://..."
```

**Local variables** (lowercase):

```bash
script_name="docker-prune"
cache_path="$CACHE_DIR/$script_name"
```

**Function parameters**:

```bash
function process_script() {
  local name="$1"
  local version="$2"
  local category="${3:-system}"
}
```

### Function Definitions

```bash
function fetch_manifest() {
  local url="$1"
  local output="$2"

  [[ -n "$url" ]] || die "URL required"
  log_debug "Fetching manifest from: $url"
  curl -fsSL "$url" -o "$output" || die "Failed to fetch"
}
```

**Naming**: verb_noun format (`fetch_manifest`, `verify_checksum`)

### Logging Standards

```bash
log_debug "Variable value: $var"     # UTIX_LOG_LEVEL=debug
log_info "Processing script: $name"  # Normal operations
log_warn "Cache outdated"            # Warnings
log_error "SHA256 mismatch"          # Errors
```

### Error Handling

```bash
# Fatal errors
[[ -f "$manifest" ]] || die "Manifest not found"

# Input validation
[[ -n "$script_name" ]] || die "Script name required"
[[ "$script_name" =~ ^[a-z0-9-]+$ ]] || die "Invalid name"

# Command availability
command -v curl &>/dev/null || die "curl required"

# Graceful degradation
if command -v jq &>/dev/null; then
  scripts=$(jq -r '.scripts[].name' "$manifest")
else
  scripts=$(grep -o '"name":"[^"]*"' "$manifest" | cut -d'"' -f4)
fi
```

### String Handling

```bash
# Always quote variables
echo "$variable"
rm "$file_path"

# Use arrays for multiple values
files=("file1.sh" "file2.sh")
for file in "${files[@]}"; do
  process "$file"
done

# Substring extraction
filename="${path##*/}"        # basename
extension="${filename##*.}"   # Extension
name="${filename%.*}"         # Without extension

# Default values
cache_dir="${CACHE_DIR:-$HOME/.utix/cache}"
```

### Conditional Expressions

**File tests**:

```bash
[[ -f "$file" ]]      # File exists
[[ -d "$dir" ]]       # Directory exists
[[ -x "$binary" ]]    # Executable
```

**String tests**:

```bash
[[ -n "$var" ]]       # Not empty
[[ -z "$var" ]]       # Empty
[[ "$a" == "$b" ]]    # Equal
[[ "$a" =~ ^v[0-9] ]] # Regex match
```

### Loop Patterns

```bash
# Iterating arrays
for script in "${scripts[@]}"; do
  log_info "Processing: $script"
done

# Reading files
while IFS= read -r line; do
  echo "$line"
done < "$input_file"

# Command output
while IFS= read -r script; do
  cache_script "$script"
done < <(list_available_scripts)
```

### Modularity Rules

```bash
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/lib" && pwd)"

source "$LIB_DIR/core.sh"
source "$LIB_DIR/config.sh"
source "$LIB_DIR/cache.sh"
```

**Library files should**:

- Contain only function definitions
- Not execute code on source
- Be independently testable

## Git Commit Standards

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**: feat, fix, docs, style, refactor, test, chore

**Examples**:

```
feat(cli): add search command for script discovery

Implement fuzzy search across names, descriptions, and tags.
Uses registry manifest for offline searching.

Closes #42
```

## Linting & Formatting

### Tools Overview

| Tool   | Target          | Config File          |
| ------ | --------------- | -------------------- |
| dprint | Markdown        | `dprint.json`        |
| shfmt  | Shell scripts   | CLI flags            |
| Biome  | JS/TS (website) | `website/biome.json` |

### Markdown (dprint)

```bash
npm install        # Install dprint
npm run format     # Format all .md files
npm run format:check  # Check formatting
```

### Shell Scripts (shfmt)

```bash
# Install
sudo apt install shfmt  # Debian/Ubuntu
brew install shfmt      # macOS

# Format
npm run format:sh       # Format all .sh
npm run format:sh:check # Check formatting
```

**shfmt flags**: `-i 2` (2-space indent), `-ci` (case indent), `-bn` (binary
newline)

### Website JS/TS (Biome)

```bash
cd website
pnpm install
pnpm run check       # Lint + format check
pnpm run check:fix   # Auto-fix all issues
```

## Code Review Checklist

**Before submitting**:

- [ ] Code follows style guidelines
- [ ] Proper error handling
- [ ] No hardcoded paths or credentials
- [ ] Logging used appropriately
- [ ] Comments explain WHY, not WHAT
- [ ] Edge cases handled
- [ ] Works on target distributions

**Bash-specific**:

- [ ] Uses `set -euo pipefail`
- [ ] Variables properly quoted
- [ ] Functions use local variables

## Related Documentation

- [Go & Registry Standards](./code-standards-go-and-registry.md)
- [System Architecture](./system-architecture.md)
- [Codebase Summary](./codebase-summary.md)
