# disk-cleanup

Clean temporary files, old logs, and package cache.

## Overview

Frees up disk space by removing temporary files, user cache, package manager
cache, old logs, and systemd journal entries. Runs as user for safe cleanup or
as root for full system cleanup.

## Requirements

No strict dependencies. Works with standard Linux utilities.

## Usage

```bash
utix run disk-cleanup [OPTIONS]
```

### Options

| Option      | Short | Description                   |
| ----------- | ----- | ----------------------------- |
| `--dry-run` | `-n`  | Preview what would be cleaned |

## Examples

### Basic Usage

```bash
# Run cleanup (user-level)
utix run disk-cleanup

# Preview what would be cleaned
utix run disk-cleanup --dry-run

# Full system cleanup (requires root)
sudo utix run disk-cleanup
```

## What Gets Cleaned

### User Mode (no sudo)

| Location                     | What's Removed   |
| ---------------------------- | ---------------- |
| `/tmp/$USER*`                | User temp files  |
| `~/.cache/thumbnails`        | Thumbnail cache  |
| `~/.cache/pip`               | Python pip cache |
| `~/.cache/npm`               | npm cache        |
| `~/.cache/yarn`              | Yarn cache       |
| `~/.cache/pnpm`              | pnpm cache       |
| `~/.cache/go-build`          | Go build cache   |
| `~/.cache/fontconfig`        | Font cache       |
| `~/.cache/mesa_shader_cache` | GPU shader cache |

### Root Mode (with sudo)

Everything above, plus:

| Location         | What's Removed           |
| ---------------- | ------------------------ |
| `/tmp/*`         | All temp files           |
| `/var/tmp/*`     | Persistent temp files    |
| Package cache    | apt/dnf/yum/apk cache    |
| `/var/log/*.log` | Logs older than 7 days   |
| `/var/log/*.gz`  | Compressed logs > 7 days |
| `/var/log/*.old` | Old log files            |
| Journal          | systemd journal > 7 days |

### Package Manager Cleanup

| Distribution  | Commands Run                               |
| ------------- | ------------------------------------------ |
| Ubuntu/Debian | `apt-get clean`, `autoclean`, `autoremove` |
| Fedora        | `dnf clean all`                            |
| CentOS/RHEL   | `yum clean all`                            |
| Alpine        | Remove `/var/cache/apk/*`                  |

## Output

```
==========================================
  Disk Cleanup Utility
==========================================

[INFO] Cleaning temporary files...
[OK] Temp cleaned: 1.2G -> 0

[INFO] Cleaning user cache...
[OK] User cache cleaned: 3.4G -> 1.1G

[INFO] Cleaning package cache...
[OK] Package cache cleaned

[INFO] Cleaning old logs...
[OK] Logs cleaned: 500M -> 100M

[INFO] Cleaning journal logs...
[OK] Journal cleaned

[INFO] Disk usage summary:
  Root: 25G used / 100G total (25% used)
  Home: 50G used / 200G total (25% used)

[OK] Cleanup complete!
```

## Troubleshooting

### Permission denied

**Problem:** Cannot clean system files

**Solution:** Run with sudo:

```bash
sudo utix run disk-cleanup
```

### Disk still full after cleanup

**Problem:** Space not freed as expected

**Solution:** Check for large files:

```bash
# Find files over 100MB
sudo find / -type f -size +100M 2>/dev/null | head -20

# Check Docker usage
docker system df
```

### Important files deleted

**Problem:** Needed cache was removed

**Solution:** Cache files regenerate automatically. For package cache:

```bash
# Reinstall package to restore cache
sudo apt-get install --reinstall package-name
```

### Journal vacuum failed

**Problem:** Cannot clean systemd journal

**Solution:** May require root or journal permissions:

```bash
sudo journalctl --vacuum-time=7d
```

## Safe to Clean

These locations are safe to clean:

- Temporary files (`/tmp`, `/var/tmp`)
- Package manager cache
- Browser cache (not cleaned by this script)
- Thumbnail cache
- Build caches (pip, npm, go-build)

## Not Cleaned (Intentionally)

- Browser profiles and data
- Application settings
- Downloaded files
- User documents
- Docker volumes (use `docker-prune`)

## Related Scripts

- `docker-prune` - Clean Docker resources
- `log-rotate` - Manage log files
- `backup-home` - Backup before cleanup

## Changelog

- **v1.0.0** - Initial release with user and system cleanup modes
