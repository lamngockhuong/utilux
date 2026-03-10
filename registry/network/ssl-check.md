# ssl-check

Check SSL certificate expiry and details for websites.

## Overview

Connects to HTTPS servers and displays certificate information including expiry date, issuer, subject, and SANs. Supports batch checking from file and configurable expiry warnings.

## Requirements

| Dependency | Description |
|------------|-------------|
| `openssl` | SSL/TLS toolkit |

## Usage

```bash
utilux run ssl-check [OPTIONS] HOST[:PORT]
```

### Options

| Option | Short | Description |
|--------|-------|-------------|
| `--port PORT` | `-p` | Port number (default: 443) |
| `--warn DAYS` | `-w` | Warning threshold in days (default: 30) |
| `--file FILE` | `-f` | Check hosts from file |
| `--chain` | `-c` | Show certificate chain |
| `--help` | `-h` | Show help |

## Examples

### Basic Usage

```bash
# Check certificate for a domain
utilux run ssl-check example.com

# Check custom port
utilux run ssl-check example.com:8443

# Check with URL (protocol stripped automatically)
utilux run ssl-check https://example.com
```

### Expiry Warnings

```bash
# Warn if expiring within 60 days
utilux run ssl-check -w 60 example.com

# Warn if expiring within 90 days
utilux run ssl-check -w 90 mysite.com
```

### Batch Checking

```bash
# Check multiple hosts from file
utilux run ssl-check -f hosts.txt

# File format (one per line):
# example.com
# mysite.org:8443
# # comments are ignored
```

### Certificate Chain

```bash
# Show full certificate chain
utilux run ssl-check -c example.com
```

## Output Format

### Single Host

```
Certificate Details:
====================

  Host:       example.com:443
  Subject:    CN=example.com
  Issuer:     CN=R3, O=Let's Encrypt
  Not Before: Jan 01 00:00:00 2026 GMT
  Not After:  Apr 01 00:00:00 2026 GMT

  Status:     Valid (90 days remaining)

  Subject Alt Names:
    - DNS:example.com
    - DNS:www.example.com
```

### Batch Report

```
SSL Certificate Report
======================

  HOST                           PORT       DAYS LEFT
  ----                           ----       ---------
  example.com                    443        90 days
  expiring-soon.com              443        15 days    (yellow)
  expired-site.com               443        EXPIRED    (red)

Summary:
  Total:    3
  OK:       1
  Warning:  1
  Expired:  1
```

## Status Colors

| Status | Color | Condition |
|--------|-------|-----------|
| Valid | Green | > warning days |
| Expiring Soon | Yellow | < warning days |
| Expired | Red | Past expiry date |

## Troubleshooting

### Connection refused

**Problem:** Cannot connect to host

**Solution:** Verify the host and port:
```bash
# Check if port is open
utilux run port-scan -p 443 hostname

# Try with explicit port
utilux run ssl-check hostname:443
```

### Certificate parse error

**Problem:** Could not parse certificate

**Solution:**
- Host may not have valid SSL
- Try with openssl directly:
```bash
echo | openssl s_client -connect hostname:443 2>/dev/null
```

### SNI issues

**Problem:** Wrong certificate returned for shared hosting

**Solution:** The script uses `-servername` flag automatically. Ensure hostname is correct.

### Timeout on slow servers

**Problem:** Connection times out

**Solution:** The default timeout is 5 seconds. For slow servers, the script may need modification.

## Hosts File Format

```txt
# Production servers
example.com
api.example.com:443

# Staging
staging.example.com:8443

# Skip this one
# old.example.com
```

## Related Scripts

- `port-scan` - Find open ports before SSL checking
- `system-info` - Show network configuration

## Changelog

- **v1.0.0** - Initial release with single/batch checking and chain display
