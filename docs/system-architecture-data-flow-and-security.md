# System Architecture: Data Flow & Security

Advanced architecture documentation covering data flows, network communication, security, and scalability.

## Script Execution Flow

```
┌─────────────┐
│ User Input  │
│ utix run  │
│ script args │
└──────┬──────┘
       ↓
┌──────────────────┐
│ Parse Arguments  │
└──────┬───────────┘
       ↓
┌─────────────────────────┐
│ Check Cache             │
│ • Exists?               │
│ • Read .version         │
└──────┬──────────────────┘
       ↓
    ┌──┴──┐
    │ Yes │ No
    ↓     ↓
┌───────────────┐  ┌────────────────────┐
│ Cache Hit     │  │ Cache Miss         │
│ Check Online  │  │ Fetch Manifest     │
└───┬───────────┘  └────────┬───────────┘
    ↓                       ↓
┌──────────────────┐  ┌──────────────────┐
│ Version Match?   │  │ Find Script Meta │
└──┬───────────────┘  └────────┬─────────┘
   ↓ Yes    ↓ No               ↓
   │        └──────┐      ┌────────────────┐
   │               ↓      │ Download Script│
   │         ┌───────────┐└────────┬───────┘
   │         │ Download  │         ↓
   │         └─────┬─────┘   ┌──────────────┐
   │               ↓         │ Verify SHA256│
   │         ┌───────────┐   └──────┬───────┘
   │         │ Verify    │          ↓ Match?
   │         └─────┬─────┘          ↓ Yes
   │               ↓           ┌──────────────┐
   │         ┌───────────┐     │ Store Cache  │
   │         │ Update    │     │ Write .version│
   │         │ Cache     │     └──────┬───────┘
   │         └─────┬─────┘            │
   │               ↓                  │
   └───────────────┴──────────────────┘
                   ↓
            ┌──────────────┐
            │ Execute      │
            │ bash script  │
            │ with args    │
            └──────┬───────┘
                   ↓
            ┌──────────────┐
            │ Return Exit  │
            │ Code         │
            └──────────────┘
```

## Registry Update Flow

```
┌────────────────────┐
│ Developer          │
│ • Edit script      │
│ • Update @version  │
└────────┬───────────┘
         ↓
┌────────────────────────────┐
│ Run generate-manifest.sh   │
│ • Parse all @metadata      │
│ • Calculate SHA256 hashes  │
│ • Update manifest.json     │
└────────┬───────────────────┘
         ↓
┌────────────────────┐
│ Git Commit + Push  │
└────────┬───────────┘
         ↓
┌────────────────────────┐
│ GitHub Repository      │
│ • Registry updated     │
│ • Available via HTTPS  │
└────────┬───────────────┘
         ↓
┌─────────────────────────────┐
│ Client Fetch Manifest       │
│ • Compare versions          │
│ • Identify updates needed   │
└─────────────────────────────┘
```

## Offline Mode Flow

```
UTIX_OFFLINE=1 utix run script
         ↓
┌────────────────────┐
│ Check Cache        │
│ Exists?            │
└──┬────────────┬────┘
   ↓ Yes       ↓ No
┌────────┐  ┌──────────────┐
│Execute │  │ Error:       │
│Cached  │  │ Script not   │
│Script  │  │ cached and   │
└────────┘  │ offline mode │
            └──────────────┘
```

## Network Communication

### Protocol: HTTPS Only

**Registry URL**:

```
https://raw.githubusercontent.com/{user}/{repo}/{branch}/registry/manifest.json
```

**Script Download URL**:

```
https://raw.githubusercontent.com/{user}/{repo}/{branch}/registry/{category}/{script}.sh
```

### Request Pattern

**Manifest Fetch**:

```
GET https://raw.githubusercontent.com/.../manifest.json
Headers:
  User-Agent: utix/1.0.0
  Accept: application/json

Response: 200 OK
{
  "version": "1.0.0",
  "scripts": [...]
}
```

**Script Download**:

```
GET https://raw.githubusercontent.com/.../registry/system/disk-cleanup.sh
Headers:
  User-Agent: utix/1.0.0
  Accept: text/plain

Response: 200 OK
#!/bin/bash
...script content...
```

### Error Handling

**Network Failures**:

1. Retry 3 times with exponential backoff (1s, 2s, 4s)
2. If all retries fail, check cache
3. If cached, use offline mode
4. If not cached, return error

**HTTP Errors**:

- 404: Script not found
- 403: Rate limit
- 500: Server error → retry
- Timeout: Network issue → retry

## Security Architecture

### Threat Model

**Threats**:

1. **Man-in-the-Middle**: Attacker intercepts download
2. **Registry Compromise**: Malicious scripts in registry
3. **Cache Poisoning**: Attacker modifies cached scripts
4. **Code Injection**: Malicious input in arguments

**Mitigations**:

1. HTTPS-only communication
2. SHA256 verification
3. File permissions
4. Input validation

### Integrity Verification

```
1. Download script to memory/temp
   ↓
2. Calculate SHA256 hash
   hash = sha256sum(downloaded_content)
   ↓
3. Compare with manifest
   if hash != manifest.sha256:
     error("Checksum mismatch")
     exit 1
   ↓
4. Save to cache only if verified
```

**Bash Implementation**:

```bash
verify_checksum() {
  local file="$1"
  local expected="$2"

  local actual
  actual=$(sha256sum "$file" | cut -d' ' -f1)

  if [[ "$actual" != "$expected" ]]; then
    log_error "SHA256 mismatch"
    return 1
  fi
  return 0
}
```

### Permission Model

**File Permissions**:

```
~/.utix/          → 755 (rwxr-xr-x)
~/.utix/cache/    → 755
~/.utix/cache/*/  → 755
~/.utix/cache/*/*.sh → 744 (rwxr--r--)
~/.utix/cache/*/.version → 644 (rw-r--r--)
```

**Process Permissions**:

- CLI runs as regular user
- Scripts inherit user permissions
- Privileged operations require sudo

## Scalability Considerations

### Client Scalability

**Caching Strategy**:

- Manifest cached for 1 hour
- Scripts cached indefinitely (until version change)
- No cache size limit

### Registry Scalability

**GitHub Infrastructure**:

- CDN-backed (low latency)
- Rate limits: 60 req/hour (unauth), 5000/hour (auth)

**Optimization**:

- Manifest is small (~10-50KB)
- Scripts downloaded once and cached
- No server-side processing

### Custom Registry

```bash
UTIX_REGISTRY_URL=https://internal.company.com/manifest.json
```

**Requirements**:

- Serve manifest.json via HTTPS
- Serve scripts via HTTPS
- Same manifest schema
- Provide SHA256 checksums

## Monitoring & Observability

### Logging Levels

**UTIX_LOG_LEVEL**:

- `debug`: All operations, timing
- `info`: Normal operations (default)
- `warn`: Recoverable issues
- `error`: Fatal errors

**Example Output**:

```
[DEBUG] Checking cache: ~/.utix/cache/git-clean/
[INFO] Script not cached, downloading...
[DEBUG] Fetching: https://raw.githubusercontent.com/.../git-clean.sh
[DEBUG] SHA256 verification passed
[INFO] Cached git-clean v1.0.0
[INFO] Executing: git-clean --dry-run
```

## Configuration Management

### Environment Variables

```bash
# Registry
UTIX_REGISTRY_URL       # Custom registry URL
UTIX_BRANCH="main"      # Git branch

# Cache
UTIX_CACHE_DIR="$HOME/.utix/cache"

# Behavior
UTIX_OFFLINE=1          # Offline mode
UTIX_LOG_LEVEL="info"   # Logging
UTIX_NO_COLOR=1         # Disable colors

# Network
UTIX_HTTP_TIMEOUT=30    # Timeout (seconds)
UTIX_MAX_RETRIES=3      # Retry count
```

### Configuration File (Future)

```yaml
# ~/.utix/config.yaml
registry:
  url: "https://raw.githubusercontent.com/user/utix/main"
  update_interval: 3600

cache:
  dir: "~/.utix/cache"
  max_size: "1G"
  auto_cleanup: true

logging:
  level: "info"

network:
  timeout: 30
  retries: 3
```

## Deployment Architecture

### Development Environment

```
Developer Workstation
  ↓
make dev (Docker/Podman auto-detected)
  ├── Ubuntu 22.04
  ├── Alpine Linux
  └── Fedora
        ↓
  Test utix commands
```

### CI/CD Pipeline

**go-cli-release.yml**:

```
Trigger: Git tag (cli-v*)
  ↓
Build: linux/amd64, linux/arm64, darwin/amd64, darwin/arm64
  ↓
Create GitHub Release + upload binaries
```

**deploy-website.yml**:

```
Trigger: Push to main
  ↓
Build Astro site → Deploy to GitHub Pages
```

## Related Documentation

- [System Architecture](./system-architecture.md)
- [Code Standards](./code-standards.md)
- [Deployment Guide](./deployment-guide.md)
