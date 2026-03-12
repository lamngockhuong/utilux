---
title: "backup-home"
description: "Backup home directory to compressed archive"
category: "automation"
version: "v1.0.0"
tags: ["backup","archive","home"]
requires: ["tar"]
author: "lamngockhuong"
---


## Overview

Creates compressed tar.gz backups of your home directory with smart exclusions for cache, temporary files, and large directories. Supports automatic cleanup of old backups and restore functionality.

## Requirements

| Dependency | Description |
|------------|-------------|
| `tar` | Archive creation and extraction |
| `gzip` | Compression (usually bundled with tar) |
| `pv` | Optional: progress bar during backup |

## Usage

```bash
utix run backup-home [COMMAND] [OPTIONS]
```

### Commands

| Command | Description |
|---------|-------------|
| `create` | Create a new backup (default) |
| `list` | List existing backups |
| `restore <file>` | Restore from backup file |
| `info <file>` | Show backup information |
| `clean` | Remove old backups |

### Options

| Option | Short | Description |
|--------|-------|-------------|
| `--dir DIR` | `-d` | Backup directory (default: ~/backups) |
| `--keep N` | `-k` | Keep N most recent backups (default: 5) |
| `--exclude PAT` | `-e` | Exclude pattern (can be repeated) |
| `--source DIR` | `-s` | Source directory (default: ~) |
| `--help` | `-h` | Show help |

## Examples

### Basic Usage

```bash
# Create backup with defaults
utix run backup-home

# List existing backups
utix run backup-home list

# Show backup info
utix run backup-home info ~/backups/home_myhost_20260310.tar.gz
```

### Advanced Usage

```bash
# Backup to external drive
utix run backup-home -d /mnt/backup

# Keep only 3 backups
utix run backup-home -k 3

# Add custom exclusion
utix run backup-home -e "*.iso" -e "Videos"

# Restore from backup
utix run backup-home restore ~/backups/home_myhost_20260310.tar.gz

# Clean old backups (keep 5 most recent)
utix run backup-home clean -k 5
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `BACKUP_DIR` | `~/backups` | Default backup directory |
| `KEEP_BACKUPS` | `5` | Number of backups to keep |

## Default Exclusions

The script automatically excludes:
- `.cache`, `.local/share/Trash`
- `node_modules`, `.npm`, `.nvm`
- `go/pkg`, `.cargo`, `.rustup`
- `.gradle`, `.m2`
- `snap`, `.steam`, `Games`
- Large downloads (`*.iso`, `*.zip` in Downloads)

## Troubleshooting

### Backup takes too long

**Problem:** Large directories slow down backup

**Solution:** Add exclusions for large directories you don't need:
```bash
utix run backup-home -e "Videos" -e "VirtualBox VMs"
```

### Permission denied errors

**Problem:** Cannot backup some files due to permissions

**Solution:** Run with sudo or exclude system directories:
```bash
sudo utix run backup-home
```

### No space on device

**Problem:** Backup destination is full

**Solution:** Clean old backups or use external storage:
```bash
utix run backup-home clean -k 2
utix run backup-home -d /mnt/external
```

## Related Scripts

- `disk-cleanup` - Free up disk space before backup
- `log-rotate` - Manage log files

## Changelog

- **v1.0.0** - Initial release with create, list, restore, clean commands
