# Contributing to Utilux

Thank you for your interest in contributing to Utilux! This guide will help you get started.

## Code of Conduct

Be respectful, inclusive, and constructive. We welcome contributions from everyone.

## Ways to Contribute

### Reporting Bugs

Open an issue with:

- Clear description of the bug
- Steps to reproduce
- Expected vs actual behavior
- Environment (distro, bash version, etc.)

### Suggesting Features

Open an issue with:

- Use case description
- Proposed solution
- Alternatives considered

### Adding Scripts

1. Create script in `registry/{category}/{script-name}.sh`
2. Follow the [script header template](#script-requirements)
3. Add entry to `registry/manifest.json`
4. Test on target distributions
5. Submit PR

### Improving Documentation

- Fix typos, clarify instructions
- Add examples, troubleshooting guides
- Translate documentation

## Development Setup

### Prerequisites

- Bash 4.0+
- curl
- Optional: jq, whiptail
- Go 1.22+ (for Go CLI)
- Podman or Docker (for containers)

### Local Development

```bash
# Clone the repository
git clone https://github.com/lamngockhuong/utilux.git
cd utilux

# Launch dev container
make dev                    # Ubuntu 22.04 (default)
make dev DISTRO=alpine      # Alpine Linux
make dev DISTRO=fedora      # Fedora

# Install dependencies (inside container)
# Alpine
apk add --no-cache bash curl whiptail jq

# Ubuntu/Debian
apt update && apt install -y curl whiptail jq

# Run the tool
chmod +x tool.sh && ./tool.sh
```

### Building Go CLI

```bash
cd cli
go build -o utilux-go .
./utilux-go --help
```

## Script Requirements

### Header Template

```bash
#!/bin/bash
# @name: script-name
# @version: v1.0.0
# @description: Brief description of what the script does
# @category: automation|dev|network|system
# @requires: dependency1, dependency2
# @tags: tag1, tag2
# @author: your-github-username

set -euo pipefail
```

### Coding Standards

- Use `set -euo pipefail` for strict mode
- Quote all variables: `"$variable"`
- Use local variables in functions
- Handle errors gracefully
- Log with `log_info`, `log_warn`, `log_error`
- See [Code Standards](docs/code-standards.md) for details

### Manifest Entry

Add to `registry/manifest.json`:

```json
{
  "name": "script-name",
  "description": "Brief description",
  "version": "v1.0.0",
  "category": "dev",
  "path": "dev/script-name.sh",
  "sha256": "<sha256-hash>",
  "tags": ["tag1", "tag2"],
  "requires": ["curl", "jq"]
}
```

Generate SHA256: `sha256sum registry/dev/script-name.sh`

## Testing

### Test Your Script

```bash
# Test locally
./registry/dev/script-name.sh [args]

# Test via CLI
./tool.sh run script-name

# Test on multiple distros
make dev DISTRO=ubuntu && ./tool.sh run script-name
make dev DISTRO=alpine && ./tool.sh run script-name
make dev DISTRO=fedora && ./tool.sh run script-name
```

### Go CLI Tests

```bash
cd cli
go test ./...
```

## Pull Request Process

1. **Fork** the repository
2. **Create branch**: `git checkout -b feat/your-feature`
3. **Make changes** following code standards
4. **Test** on target distributions
5. **Commit** with conventional commits:
   ```
   feat(registry): add docker-compose script
   fix(cli): handle missing manifest gracefully
   docs: add troubleshooting section
   ```
6. **Push** to your fork
7. **Open PR** with:
   - Clear title and description
   - Link to related issue (if any)
   - Screenshots/output (if applicable)
   - Checklist of tested distros

### PR Checklist

- [ ] Code follows [Code Standards](docs/code-standards.md)
- [ ] Script has proper header with metadata
- [ ] Manifest entry added with correct SHA256
- [ ] Tested on Ubuntu/Debian
- [ ] Tested on Alpine (if applicable)
- [ ] Tested on Fedora (if applicable)
- [ ] Documentation updated (if needed)

## Project Structure

```
utilux/
├── tool.sh              # Main Bash CLI entry point
├── install.sh           # Installation script
├── lib/                 # Bash library modules
├── cli/                 # Go CLI (optional)
├── registry/            # Script registry
│   ├── manifest.json    # Script metadata
│   └── {category}/      # Scripts by category
├── website/             # Documentation site
└── docs/                # Technical documentation
```

## Getting Help

- [Documentation](https://utilux.khuong.dev)
- [Issues](https://github.com/lamngockhuong/utilux/issues)
- [Discussions](https://github.com/lamngockhuong/utilux/discussions)

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
