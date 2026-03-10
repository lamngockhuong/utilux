# port-scan

Scan open ports on a host using pure bash or netcat.

## Overview

A lightweight TCP connect scanner for checking open ports. Scans common ports by default or custom ranges. Works without external tools using bash `/dev/tcp` with netcat as preferred method when available.

## Requirements

No strict dependencies. Optional:

| Dependency | Description |
|------------|-------------|
| `nc` (netcat) | Faster scanning (auto-detected) |
| `ss` or `netstat` | For listing local ports |

## Usage

```bash
utilux run port-scan [OPTIONS] HOST [PORTS]
```

### Options

| Option | Short | Description |
|--------|-------|-------------|
| `--range START END` | `-r` | Scan port range |
| `--common` | `-c` | Scan common ports only (default) |
| `--ports PORTS` | `-p` | Scan specific ports (comma-separated) |
| `--listen` | `-l` | Show listening ports on this machine |
| `--timeout SEC` | `-t` | Connection timeout (default: 1) |
| `--help` | `-h` | Show help |

## Examples

### Basic Usage

```bash
# Scan common ports on localhost
utilux run port-scan localhost

# Scan common ports on remote host
utilux run port-scan example.com

# Show local listening ports
utilux run port-scan -l
```

### Port Range Scanning

```bash
# Scan ports 1-100
utilux run port-scan -r 1 100 192.168.1.1

# Scan ports 8000-9000
utilux run port-scan -r 8000 9000 localhost

# Full scan (slow!)
utilux run port-scan -r 1 65535 localhost
```

### Specific Ports

```bash
# Scan web ports
utilux run port-scan -p 80,443,8080 example.com

# Scan database ports
utilux run port-scan -p 3306,5432,27017 localhost

# Scan SSH and HTTP
utilux run port-scan -p 22,80 server.local
```

### Timeout Adjustment

```bash
# Faster scan (may miss slow responses)
utilux run port-scan -t 0.5 localhost

# Slower scan for unreliable networks
utilux run port-scan -t 3 remote-server.com
```

## Common Ports Reference

| Port | Service |
|------|---------|
| 21 | FTP |
| 22 | SSH |
| 23 | Telnet |
| 25 | SMTP |
| 53 | DNS |
| 80 | HTTP |
| 110 | POP3 |
| 143 | IMAP |
| 443 | HTTPS |
| 3306 | MySQL |
| 5432 | PostgreSQL |
| 6379 | Redis |
| 8080 | HTTP-Alt |
| 27017 | MongoDB |

## Output Format

```
Open ports on localhost:

  PORT     STATE           SERVICE
  ----     -----           -------
  22       open            SSH
  80       open            HTTP
  443      open            HTTPS

Found 3 open ports
```

## Troubleshooting

### Scan is slow

**Problem:** Scanning large ranges takes too long

**Solution:**
1. Reduce timeout: `-t 0.5`
2. Use netcat if not installed: `apt install netcat`
3. Scan only needed ports: `-p 22,80,443`

### Permission denied

**Problem:** Cannot scan certain ports

**Solution:** Some ports require root:
```bash
sudo utilux run port-scan -r 1 1024 localhost
```

### Host unreachable

**Problem:** Cannot connect to host

**Solution:** Check network connectivity:
```bash
ping hostname
```

### False negatives

**Problem:** Port is open but not detected

**Solution:** Increase timeout:
```bash
utilux run port-scan -t 5 slow-server.com
```

## Limitations

- TCP only (no UDP scanning)
- Connect scan only (no SYN/stealth)
- No service version detection
- For comprehensive scanning, use `nmap`

## Related Scripts

- `ssl-check` - Check SSL certificates on open HTTPS ports
- `system-info` - Show network information

## Changelog

- **v1.0.0** - Initial release with common, range, and specific port scanning
