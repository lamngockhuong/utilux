# Code Standards: Go & Registry

Go coding standards and registry script requirements.

## Go Coding Standards

### Project Structure

```
cli/
├── main.go              # Entry point
├── cmd/                 # CLI commands
├── internal/            # Private packages
└── go.mod
```

### Package Organization

**Command files** (`cmd/`):

```go
package cmd

var runCmd = &cobra.Command{
  Use:   "run <script>",
  Short: "Run a script",
  Args:  cobra.ExactArgs(1),
  RunE:  runScript,
}

func runScript(cmd *cobra.Command, args []string) error {
  name := args[0]
  return nil
}

func init() {
  rootCmd.AddCommand(runCmd)
}
```

**Internal packages** (`internal/`):

```go
package cache

type Cache struct {
  dir string
}

func New(dir string) (*Cache, error) {
  // Constructor
}

func (c *Cache) Get(name string) ([]byte, error) {
  // Method
}
```

### Naming Conventions

**Files**: lowercase, underscore for multi-word

```
cache.go, fetch.go, types.go
```

**Types**: PascalCase

```go
type ScriptMetadata struct {}
type Registry struct {}
```

**Functions/Methods**: camelCase

```go
func fetchManifest() {}
func (r *Registry) GetScript(name string) {}
```

**Constants**: PascalCase or SCREAMING_SNAKE_CASE

```go
const DefaultCacheDir = "~/.utix/cache"
const MAX_RETRIES = 3
```

### Error Handling

```go
// Always check errors
data, err := os.ReadFile(path)
if err != nil {
  return fmt.Errorf("failed to read file: %w", err)
}

// Wrap errors with context
if err := cache.Store(name, data); err != nil {
  return fmt.Errorf("failed to cache %s: %w", name, err)
}

// Custom error types (when needed)
type ScriptNotFoundError struct {
  Name string
}

func (e *ScriptNotFoundError) Error() string {
  return fmt.Sprintf("script not found: %s", e.Name)
}
```

### Function Design

```go
// Single responsibility
func downloadScript(url string) ([]byte, error) {
  resp, err := http.Get(url)
  if err != nil {
    return nil, err
  }
  defer resp.Body.Close()
  return io.ReadAll(resp.Body)
}

func verifyChecksum(data []byte, expected string) error {
  hash := sha256.Sum256(data)
  actual := hex.EncodeToString(hash[:])
  if actual != expected {
    return fmt.Errorf("checksum mismatch")
  }
  return nil
}
```

**Options pattern**:

```go
type Option func(*Client)

func WithTimeout(d time.Duration) Option {
  return func(c *Client) {
    c.timeout = d
  }
}

client := NewClient(WithTimeout(30*time.Second))
```

### Interface Usage

```go
// Accept interfaces, return structs
func ProcessScripts(r io.Reader) ([]Script, error) {}

// Keep interfaces small
type Cacher interface {
  Get(name string) ([]byte, error)
  Set(name string, data []byte) error
}
```

### Concurrency Patterns

```go
// Use contexts for cancellation
func fetchWithContext(ctx context.Context, url string) error {
  req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
  if err != nil {
    return err
  }
  // Execute request...
}

// Proper goroutine cleanup
func worker(ctx context.Context, jobs <-chan Job) {
  for {
    select {
    case job := <-jobs:
      process(job)
    case <-ctx.Done():
      return
    }
  }
}
```

### Testing Standards

```go
func TestParseScript(t *testing.T) {
  tests := []struct {
    name    string
    input   string
    want    Script
    wantErr bool
  }{
    {"valid script", "#!/bin/bash\n# @name: test", Script{Name: "test"}, false},
    {"invalid format", "invalid", Script{}, true},
  }

  for _, tt := range tests {
    t.Run(tt.name, func(t *testing.T) {
      got, err := ParseScript(tt.input)
      if (err != nil) != tt.wantErr {
        t.Errorf("ParseScript() error = %v, wantErr %v", err, tt.wantErr)
      }
      if !reflect.DeepEqual(got, tt.want) {
        t.Errorf("ParseScript() = %v, want %v", got, tt.want)
      }
    })
  }
}
```

## Registry Script Standards

### Metadata Requirements

```bash
#!/bin/bash
# @name: script-name           # REQUIRED
# @version: v1.0.0             # REQUIRED
# @description: One line desc  # REQUIRED
# @category: system            # REQUIRED: automation|dev|network|system
# @requires: curl, jq          # OPTIONAL
# @tags: cleanup, disk         # OPTIONAL
# @author: username            # REQUIRED

set -euo pipefail
```

### Documentation Requirements

Each script MUST have a corresponding Markdown documentation file:

**Location**: `registry/{category}/{script-name}.md`

**Template Structure**:

```markdown
# script-name

Brief one-line description.

## Overview

Detailed explanation of what the script does and use cases.

## Requirements

| Dependency | Description |
| ---------- | ----------- |
| `tool`     | Purpose     |

## Usage

\`\`\`bash utix run script-name [COMMAND] [OPTIONS] \`\`\`

### Commands (if applicable)

| Command  | Description  |
| -------- | ------------ |
| `action` | What it does |

### Options

| Option   | Short | Description |
| -------- | ----- | ----------- |
| `--flag` | `-f`  | Purpose     |

## Examples

### Basic Usage

\`\`\`bash

# Example with explanation

utix run script-name \`\`\`

### Advanced Usage

\`\`\`bash

# More complex examples

utix run script-name --advanced \`\`\`

## Environment Variables

| Variable   | Default | Description |
| ---------- | ------- | ----------- |
| `VAR_NAME` | `value` | Purpose     |

## Troubleshooting

### Issue Title

**Problem:** Description

**Solution:** How to fix

## Related Scripts

- `other-script` - Brief description

## Changelog

- **v1.0.0** - Initial release
```

**Manifest Entry**: Both `file` and `docs` fields required:

```json
{
  "name": "script-name",
  "file": "system/script-name.sh",
  "sha256": "abc123...",
  "docs": "system/script-name.md",
  "docs_sha256": "def456..."
}
```

### Script Structure Template

```bash
#!/bin/bash
# [Metadata header]

set -euo pipefail

# ===== Configuration =====
DEFAULT_VAR="value"

# ===== Colors & Logging =====
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# ===== Helper Functions =====
check_requirements() { }

# ===== Core Functions =====
main_operation() { }

# ===== Usage & Help =====
show_usage() {
  cat << EOF
Script Name - Brief description

Usage: $(basename "$0") [OPTIONS]

OPTIONS:
  -h, --help     Show this help
  -v, --verbose  Verbose output
EOF
}

# ===== Main Entry Point =====
main() { }

main "$@"
```

### Argument Parsing Pattern

```bash
main() {
  local verbose=false
  local dry_run=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -v|--verbose) verbose=true; shift ;;
      --dry-run) dry_run=true; shift ;;
      -h|--help) show_usage; exit 0 ;;
      *) log_error "Unknown option: $1"; show_usage; exit 1 ;;
    esac
  done

  perform_operation "$verbose" "$dry_run"
}
```

### Dependency Checking

```bash
check_requirements() {
  local missing=()
  for cmd in curl jq docker; do
    command -v "$cmd" &>/dev/null || missing+=("$cmd")
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    log_error "Missing: ${missing[*]}"
    exit 1
  fi
}
```

## Documentation Standards

### Inline Comments

**When to comment**:

- Complex algorithms
- Non-obvious workarounds
- Security-critical sections

**Examples**:

```bash
# Good: Explains WHY
# Use raw.githubusercontent.com for direct file access
url="${raw_url//github.com/raw.githubusercontent.com}"

# Bad: Explains WHAT (obvious)
# Replace github.com with raw.githubusercontent.com
url="${raw_url//github.com/raw.githubusercontent.com}"
```

### Function Documentation

```bash
# fetch_manifest downloads the registry manifest
#
# Arguments:
#   $1 - Registry URL (required)
#   $2 - Output file path (required)
#
# Returns:
#   0 on success, 1 on failure
function fetch_manifest() { }
```

## Performance Guidelines

**Bash**:

- Minimize subprocess spawning
- Cache expensive operations
- Use `grep -F` for literal strings

**Go**:

- Reuse HTTP clients
- Buffer I/O operations
- Profile before optimizing

## Security Guidelines

**Input validation**:

```bash
[[ "$name" =~ ^[a-z0-9-]+$ ]] || die "Invalid name"

safe_path=$(realpath -m "$user_input")
[[ "$safe_path" == "$CACHE_DIR"/* ]] || die "Path outside cache"
```

**Avoid code injection**:

```bash
# Bad
eval "$user_command"

# Good
case "$command" in
  start|stop|restart) systemctl "$command" "$service" ;;
  *) die "Invalid command" ;;
esac
```

**Credential handling**:

- Never hardcode credentials
- Use environment variables
- Don't log sensitive data

## Go-specific Review Checklist

- [ ] Errors wrapped with context
- [ ] Follows standard project layout
- [ ] Interfaces used appropriately
- [ ] No goroutine leaks

## Related Documentation

- [Bash Code Standards](./code-standards.md)
- [System Architecture](./system-architecture.md)
- [Codebase Summary](./codebase-summary.md)
