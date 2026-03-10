# log-rotate

Rotate, compress, and manage log files.

## Overview

Rotates log files that exceed a size threshold, compresses old logs, and removes logs older than a retention period. Useful for managing application logs outside of system logrotate.

## Requirements

| Dependency | Description |
|------------|-------------|
| `gzip` | For compressing rotated logs |

## Usage

```bash
utilux run log-rotate [OPTIONS] [DIRECTORY]
```

### Options

| Option | Short | Description |
|--------|-------|-------------|
| `--size SIZE` | `-s` | Max file size before rotation (default: 10M) |
| `--keep DAYS` | `-k` | Keep logs for N days (default: 30) |
| `--no-compress` | `-n` | Don't compress rotated logs |
| `--dry-run` | `-d` | Show what would be done |
| `--help` | `-h` | Show help |

### Size Units

| Unit | Example |
|------|---------|
| K | 100K = 100 KB |
| M | 10M = 10 MB |
| G | 1G = 1 GB |

## Examples

### Basic Usage

```bash
# Rotate /var/log (requires sudo)
sudo utilux run log-rotate

# Rotate custom directory
utilux run log-rotate /home/user/app/logs

# Preview what would be rotated
utilux run log-rotate --dry-run
```

### Custom Settings

```bash
# Rotate at 50MB, keep 7 days
utilux run log-rotate -s 50M -k 7 /var/log/myapp

# Rotate at 100MB, keep 14 days
utilux run log-rotate -s 100M -k 14 ./logs

# Don't compress rotated files
utilux run log-rotate -n /var/log/myapp
```

### Application Logs

```bash
# Rotate Node.js app logs
utilux run log-rotate -s 20M ~/apps/myapp/logs

# Rotate nginx logs
sudo utilux run log-rotate -s 100M /var/log/nginx
```

## How Rotation Works

1. **Find large logs**: Scans for `.log` files exceeding size limit
2. **Rotate existing**: Moves `.log.1` → `.log.2`, etc. (up to .10)
3. **Create new rotation**: Copies current log to `.log.1`
4. **Truncate original**: Clears the original log file (keeps fd open)
5. **Compress**: Gzips the rotated file (`.log.1` → `.log.1.gz`)
6. **Cleanup**: Removes logs older than retention period

## File Naming

```
app.log         # Current log
app.log.1.gz    # Most recent rotation
app.log.2.gz    # Second most recent
...
app.log.10.gz   # Oldest rotation
```

## Output

```
==========================================
  Log Rotate Utility
==========================================

  Directory: /var/log/myapp
  Max Size:  10M
  Keep Days: 30
  Compress:  Yes

[INFO] Processing: /var/log/myapp
[INFO] Rotating: /var/log/myapp/app.log (15M)
[OK] Rotated: /var/log/myapp/app.log

[INFO] Cleaning logs older than 30 days in /var/log/myapp
[OK] Removed 3 old files

[OK] Done!
```

## Troubleshooting

### Permission denied

**Problem:** Cannot rotate system logs

**Solution:** Run with sudo:
```bash
sudo utilux run log-rotate /var/log
```

### Disk full

**Problem:** Cannot rotate, no space

**Solution:**
1. Reduce retention: `-k 7`
2. Run cleanup first: `utilux run disk-cleanup`
3. Remove old rotations manually

### Log file in use

**Problem:** Process writing to log

**Solution:** The script uses truncate, which keeps the file descriptor open. The writing process continues normally.

### Compression failed

**Problem:** gzip not available

**Solution:**
1. Install gzip: `apt install gzip`
2. Or disable compression: `-n`

### Files not cleaned

**Problem:** Old files not removed

**Solution:** Check file modification time:
```bash
ls -la /path/to/logs/*.gz
# Files are cleaned based on mtime, not filename
```

## Comparison with System logrotate

| Feature | log-rotate | System logrotate |
|---------|------------|------------------|
| Config | CLI flags | Config files |
| Scheduling | Manual/cron | Cron daily |
| Scope | Single directory | System-wide |
| Flexibility | Simple | Very configurable |
| Use case | App logs | System logs |

## Related Scripts

- `disk-cleanup` - General disk cleanup
- `cron-helper` - Schedule log rotation with cron

## Changelog

- **v1.0.0** - Initial release with size-based rotation and retention cleanup
