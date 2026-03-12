# system-info

Display comprehensive system information.

## Overview

Shows detailed information about OS, CPU, memory, disk, network, users,
processes, and services in a formatted report. Useful for system diagnostics and
documentation.

## Requirements

No strict dependencies. Uses standard Linux utilities.

## Usage

```bash
utix run system-info [SECTION]
```

### Sections

| Section    | Description                 |
| ---------- | --------------------------- |
| `all`      | Show all sections (default) |
| `os`       | Operating system info       |
| `cpu`      | CPU information             |
| `memory`   | Memory and swap usage       |
| `disk`     | Disk usage                  |
| `network`  | Network configuration       |
| `users`    | User information            |
| `process`  | Process statistics          |
| `services` | systemd services status     |

## Examples

### Basic Usage

```bash
# Show all system information
utix run system-info

# Show specific section
utix run system-info cpu
utix run system-info memory
utix run system-info disk
```

### Common Use Cases

```bash
# Quick system overview
utix run system-info os

# Check memory usage
utix run system-info memory

# Check disk space
utix run system-info disk

# Network troubleshooting
utix run system-info network
```

## Output Sections

### Operating System

```
=== Operating System ===
  OS              : Ubuntu 22.04.3 LTS
  ID              : ubuntu
  Kernel          : 5.15.0-91-generic
  Arch            : x86_64
  Hostname        : myserver
  Uptime          : up 15 days, 3 hours
```

### CPU

```
=== CPU ===
  Model           : Intel(R) Core(TM) i7-9750H @ 2.60GHz
  Cores           : 12
  Frequency       : 2600 MHz
  Usage           : 15%
  Load Avg        : 0.52 0.48 0.45
```

### Memory

```
=== Memory ===
  Total           : 16384 MB
  Used            : 8192 MB
  Free            : 4096 MB
  Available       : 6144 MB
  Usage           : 50%
  Swap Total      : 2048 MB
  Swap Used       : 256 MB
```

### Disk

```
=== Disk ===
  /dev/sda1         25G /   100G (25%) → /
  /dev/sda2         50G /   200G (25%) → /home
```

### Network

```
=== Network ===
  Hostname        : myserver.local
  Local IPs       : 192.168.1.100, 10.0.0.5
  Public IP       : 203.0.113.50
  DNS             : 8.8.8.8, 8.8.4.4
```

### Users

```
=== Users ===
  Current User    : john
  Home            : /home/john
  Shell           : /bin/bash
  Logged In       : 2 users
```

### Processes

```
=== Processes ===
  Total           : 245
  Running         : 3
  Sleeping        : 242

  Top 5 by CPU:
    root      15.2% /usr/bin/Xorg
    john       8.5% /usr/bin/firefox
    john       5.2% code
    mysql      3.1% /usr/sbin/mysqld
    john       2.8% /usr/bin/gnome-shell
```

### Services (systemd)

```
=== Services (systemd) ===
  Running         : 85
  Failed          : 2

  Failed services:
    - bluetooth.service
    - cups.service
```

## Troubleshooting

### Public IP shows N/A

**Problem:** Cannot fetch public IP

**Solution:** Requires internet access. The script uses `ifconfig.me`:

```bash
curl ifconfig.me
```

### Service info not showing

**Problem:** Services section empty

**Solution:** Only works on systemd systems:

```bash
systemctl --version
```

### Permission for some info

**Problem:** Some details missing

**Solution:** Run with sudo for complete info:

```bash
sudo utix run system-info
```

### Slow network section

**Problem:** Takes long to display

**Solution:** Public IP lookup has 2-second timeout. Skip with:

```bash
utix run system-info os cpu memory disk
```

## Output to File

```bash
# Save report to file
utix run system-info > system-report.txt

# Save with timestamp
utix run system-info > "system-$(date +%Y%m%d).txt"
```

## Related Scripts

- `disk-cleanup` - Free up disk space
- `port-scan` - Check network ports
- `ssl-check` - Check SSL certificates

## Changelog

- **v1.0.0** - Initial release with all major system sections
