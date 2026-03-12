---
title: "cron-helper"
description: "Interactively manage cron jobs"
category: "automation"
version: "v1.0.0"
tags: ["cron","schedule","automation"]
requires: []
author: "lamngockhuong"
---

## Overview

A friendly interface for managing cron jobs without memorizing cron syntax.
Supports adding jobs with common schedules, removing by number, editing
directly, and backup/restore of crontab.

## Requirements

No external dependencies. Uses built-in `crontab` command.

## Usage

```bash
utix run cron-helper [COMMAND] [OPTIONS]
```

### Commands

| Command            | Description                      |
| ------------------ | -------------------------------- |
| `list`             | List current cron jobs (default) |
| `add SCHEDULE CMD` | Add a new cron job               |
| `remove [N]`       | Remove cron job by number        |
| `edit`             | Open crontab in editor           |
| `export [FILE]`    | Export cron jobs to file         |
| `import FILE`      | Import cron jobs from file       |
| `clear`            | Remove all cron jobs             |
| `examples`         | Show schedule examples           |
| `menu`             | Interactive menu                 |

## Examples

### Basic Usage

```bash
# List current cron jobs
utix run cron-helper list

# Interactive menu
utix run cron-helper menu

# Show schedule syntax examples
utix run cron-helper examples
```

### Adding Jobs

```bash
# Run daily at midnight
utix run cron-helper add "@daily" "/path/to/backup.sh"

# Run every hour
utix run cron-helper add "0 * * * *" "/path/to/script.sh"

# Run every 5 minutes
utix run cron-helper add "*/5 * * * *" "ping -c 1 google.com"

# Run at startup
utix run cron-helper add "@reboot" "/path/to/startup.sh"

# Run weekdays at 9 AM
utix run cron-helper add "0 9 * * 1-5" "/path/to/workday.sh"
```

### Managing Jobs

```bash
# Remove job #2
utix run cron-helper remove 2

# Export crontab to file
utix run cron-helper export backup.txt

# Import from file (replaces all jobs)
utix run cron-helper import backup.txt

# Edit crontab directly
utix run cron-helper edit
```

## Cron Schedule Reference

### Format

```
MIN HOUR DOM MON DOW command
```

| Field | Values | Description                |
| ----- | ------ | -------------------------- |
| MIN   | 0-59   | Minute                     |
| HOUR  | 0-23   | Hour                       |
| DOM   | 1-31   | Day of Month               |
| MON   | 1-12   | Month                      |
| DOW   | 0-7    | Day of Week (0,7 = Sunday) |

### Special Characters

| Char | Description | Example                         |
| ---- | ----------- | ------------------------------- |
| `*`  | Any value   | `* * * * *` = every minute      |
| `,`  | Value list  | `1,15 * * * *` = at :01 and :15 |
| `-`  | Range       | `0 9-17 * * *` = 9 AM to 5 PM   |
| `/`  | Step        | `*/15 * * * *` = every 15 min   |

### Special Schedules

| Schedule   | Equivalent  | Description           |
| ---------- | ----------- | --------------------- |
| `@reboot`  | -           | Run at startup        |
| `@hourly`  | `0 * * * *` | Every hour            |
| `@daily`   | `0 0 * * *` | Every day at midnight |
| `@weekly`  | `0 0 * * 0` | Every Sunday          |
| `@monthly` | `0 0 1 * *` | First of month        |
| `@yearly`  | `0 0 1 1 *` | January 1st           |

## Troubleshooting

### Job not running

**Problem:** Cron job doesn't execute

**Solution:**

1. Check cron service is running: `systemctl status cron`
2. Use full paths in commands
3. Check script permissions: `chmod +x script.sh`
4. Check cron logs: `grep CRON /var/log/syslog`

### Permission denied

**Problem:** Cannot edit crontab

**Solution:** Ensure user is not in `/etc/cron.deny`:

```bash
cat /etc/cron.deny
```

### Environment variables not set

**Problem:** Script works manually but not from cron

**Solution:** Set PATH at top of crontab:

```
PATH=/usr/local/bin:/usr/bin:/bin
0 * * * * /path/to/script.sh
```

## Related Scripts

- `backup-home` - Backup script to schedule with cron
- `log-rotate` - Log rotation to schedule daily

## Changelog

- **v1.0.0** - Initial release with interactive menu and all management commands
