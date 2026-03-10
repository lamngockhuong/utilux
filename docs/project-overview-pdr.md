# Project Overview & Product Development Requirements (PDR)

## Project Vision

Utilux is a unified Linux utility management system that provides curated, production-ready scripts across Ubuntu/Debian, Alpine, and Fedora distributions. The project aims to eliminate repetitive system administration tasks through a lazy-loading script registry accessible via both Bash and Go CLI interfaces.

## Target Users

**Primary Audience:**

- Linux system administrators managing multiple servers
- DevOps engineers automating infrastructure tasks
- Developers needing quick access to common utilities
- Technical users preferring CLI-first workflows

**User Personas:**

1. **DevOps Engineer**: Needs reliable automation scripts for CI/CD pipelines
2. **System Administrator**: Manages multiple Linux distributions, requires cross-distro compatibility
3. **Developer**: Wants development environment setup and maintenance utilities
4. **Home Lab Enthusiast**: Maintains personal Linux servers with periodic maintenance needs

## Core Features

### 1. Lazy-Loading Script Registry

- Scripts downloaded on-demand from GitHub registry
- SHA256 integrity verification via manifest.json
- Local caching (~/.utilux) for offline execution
- Automatic version checking and updates

### 2. Dual CLI Interfaces

**Bash CLI** (`utilux`):

- Interactive whiptail-based menu system
- Zero dependencies beyond bash, curl
- Modular library architecture (lib/)

**Go CLI** (`utilux-go`):

- High-performance compiled binary
- Cobra command framework
- Bubbletea TUI with spinner/list widgets
- Cross-platform release builds (Linux, macOS, Windows)

### 3. Multi-Distribution Support

- Ubuntu/Debian (apt)
- Alpine (apk)
- Fedora (dnf)
- Automatic distro detection
- Distribution-specific script variants where needed

### 4. Script Categories

- **automation**: backup-home, cron-helper
- **dev**: docker-prune, env-setup, git-clean
- **network**: port-scan, ssl-check
- **system**: disk-cleanup, log-rotate, system-info

### 5. Developer-Friendly Features

- manifest.json as source of truth
- generate-manifest.sh for automated SHA256 calculation
- Astro-powered documentation website
- GitHub Actions for website deployment and Go CLI releases

## Non-Goals

**Out of Scope:**

- GUI interface (CLI-only by design)
- Package management replacement (uses existing system tools)
- Proprietary/closed-source scripts
- Real-time monitoring or daemon services
- Database or stateful service management

## Success Criteria

### Version 1.0 (Current)

- [x] Core Bash CLI with modular lib/ structure
- [x] Script registry with 10+ production scripts
- [x] Manifest-based integrity verification
- [x] Local caching mechanism
- [x] Multi-distro support
- [x] Astro documentation website
- [x] Go CLI with feature parity to Bash version

### Version 1.1 (Planned)

- [ ] Script categories expansion (15-20 scripts)
- [ ] Plugin system for custom registries
- [ ] Script dependency resolution
- [ ] Rollback mechanism for failed scripts
- [ ] Enhanced error reporting and logging

### Version 2.0 (Future)

- [ ] Community script submissions via PR
- [ ] Script marketplace with ratings/reviews
- [ ] Encrypted script support for sensitive operations
- [ ] Remote execution on multiple hosts
- [ ] Integration with Ansible/Terraform

## Technical Requirements

### Functional Requirements

**FR-1: Script Discovery**

- Users can list all available scripts by category
- Search functionality for script names, tags, descriptions
- Display script metadata (version, requirements, author)

**FR-2: Script Execution**

- Download script from registry on first run
- Cache script locally for subsequent executions
- Verify SHA256 hash before execution
- Pass command-line arguments to scripts

**FR-3: Cache Management**

- List cached scripts with versions
- Clear individual or all cached scripts
- Show cache size and statistics
- Automatic cache expiry (optional)

**FR-4: Offline Mode**

- Execute cached scripts without network
- Graceful fallback when registry unreachable
- UTILUX_OFFLINE environment variable

**FR-5: Update Mechanism**

- Check for script updates via manifest version comparison
- Update individual scripts or all cached scripts
- Preserve user configuration during updates

### Non-Functional Requirements

**NFR-1: Performance**

- Script list operation < 500ms (cached manifest)
- Script download and cache < 2s on standard connection
- Go CLI startup time < 100ms

**NFR-2: Reliability**

- 99.9% uptime for GitHub-hosted registry
- Atomic cache operations (no partial writes)
- Retry logic for network failures (3 attempts)

**NFR-3: Security**

- All scripts verified via SHA256 checksums
- HTTPS-only for manifest and script downloads
- No execution of unverified code
- Minimal privilege requirements (non-root where possible)

**NFR-4: Compatibility**

- Bash 4.0+ for Bash CLI
- Go 1.22+ for Go CLI compilation
- Linux kernel 3.10+ (RHEL 7 era)
- Works in Docker containers (Alpine, Ubuntu, Fedora)

**NFR-5: Maintainability**

- Modular codebase (lib/ for shared functions)
- Automated manifest generation
- CI/CD for releases and website deployment
- Comprehensive documentation

## Dependencies

**Runtime Dependencies:**

- bash 4.0+
- curl
- jq (optional, enhances JSON parsing)
- whiptail (optional, enables interactive menu)

**Development Dependencies:**

- Go 1.22+ (for Go CLI)
- Node.js 20+ (for Astro website)
- repomix (for codebase documentation)

**External Services:**

- GitHub (script registry hosting)
- GitHub Pages (documentation website)
- GitHub Actions (CI/CD)

## Installation Methods

1. **Release Tarball**: Production installation from GitHub releases
2. **Develop Branch**: Latest features from develop branch
3. **Local Source**: Development installation from cloned repo
4. **Go Binary**: Standalone Go CLI from GitHub releases

## Configuration

**Environment Variables:**

- `UTILUX_LOG_LEVEL`: debug, info, warn, error (default: info)
- `UTILUX_OFFLINE`: Enable offline mode (1/0)
- `UTILUX_CACHE_DIR`: Custom cache location (default: ~/.utilux)
- `UTILUX_REGISTRY_URL`: Custom registry URL for enterprise deployments

**File Locations:**

- Binaries: /usr/local/bin/utilux, /usr/local/bin/utilux-go
- Libraries: /usr/local/lib/utilux/lib/
- Cache: ~/.utilux/cache/
- Config: ~/.utilux/config (future)

## Risk Assessment

**Technical Risks:**

1. **Registry Availability**: GitHub outage blocks script downloads
   - Mitigation: Local caching, offline mode, mirror support planned
2. **Script Security**: Compromised registry could distribute malicious scripts
   - Mitigation: SHA256 verification, HTTPS-only, code review process
3. **Distribution Fragmentation**: Package manager differences across distros
   - Mitigation: Distro detection, abstraction layer in scripts

**Operational Risks:**

1. **Breaking Changes**: Script updates may change behavior
   - Mitigation: Semantic versioning, changelog documentation
2. **Dependency Hell**: Scripts require unavailable packages
   - Mitigation: @requires metadata, graceful fallback

## Open Questions

1. Should scripts support interactive prompts or remain fully scriptable?
2. What is the threshold for cache size before automatic cleanup?
3. Should Go CLI fully replace Bash CLI, or maintain both long-term?
4. How to handle enterprise environments with restricted internet access?
5. Should scripts support configuration files for common parameters?

## Related Documentation

- [System Architecture](./system-architecture.md)
- [Code Standards](./code-standards.md)
- [Deployment Guide](./deployment-guide.md)
- [Project Roadmap](./project-roadmap.md)
