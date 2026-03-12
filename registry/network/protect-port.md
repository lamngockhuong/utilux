# protect-port

Add basic auth to any port via nginx reverse proxy.

## Overview

Creates nginx reverse proxy with HTTP Basic Authentication for protecting internal services. Useful for securing Docker services, development tools, or any localhost-bound applications.

## Requirements

| Dependency | Description                           |
| ---------- | ------------------------------------- |
| `nginx`    | Web server / reverse proxy            |
| `htpasswd` | Password file utility (apache2-utils) |

## Usage

```bash
utix run protect-port <ACTION> [OPTIONS]
```

### Actions

| Action    | Arguments                              | Description                        |
| --------- | -------------------------------------- | ---------------------------------- |
| `protect` | `<PORT> <INTERNAL_PORT> [USER] [PASS]` | Create nginx proxy with basic auth |
| `update`  | `<PORT> [USER] [PASS]`                 | Update credentials                 |
| `remove`  | `<PORT>`                               | Remove protection                  |
| `list`    | -                                      | List all protected ports           |

## Examples

### Protect a Port

```bash
# Interactive (prompts for credentials)
utix run protect-port protect 5541 5540

# With credentials
utix run protect-port protect 8080 3000 admin secretpass
```

### Update Credentials

```bash
# Interactive
utix run protect-port update 5541

# With new credentials
utix run protect-port update 5541 admin newpass
```

### Remove Protection

```bash
utix run protect-port remove 5541
```

### List Protected Ports

```bash
utix run protect-port list
```

## Scenario: Protect Docker Service

**Problem:** Docker service exposes port publicly, need basic auth protection.

**Example:** RedisInsight running at `0.0.0.0:5540`

> **Note:** iptables INPUT chain doesn't work with Docker (Docker bypasses via DOCKER chain). Simplest solution is binding Docker to localhost.

### Steps

**Step 1:** Modify docker-compose.yml - bind localhost only

```yaml
services:
  redisinsight:
    image: redis/redisinsight:latest
    ports:
      # Before: "5540:5540" (public)
      # After: localhost only
      - "127.0.0.1:5540:5540"
```

**Step 2:** Recreate container

```bash
docker compose up -d redisinsight
```

**Step 3:** Create nginx proxy with basic auth

```bash
utix run protect-port protect 5541 5540
# Enter username and password when prompted
```

**Step 4:** Access via protected port

```bash
curl -u user:pass http://SERVER_IP:5541
```

### Result

| Port | Access         | Auth       |
| ---- | -------------- | ---------- |
| 5540 | Localhost only | None       |
| 5541 | Public         | Basic Auth |

## Files Created

| File                                          | Purpose      |
| --------------------------------------------- | ------------ |
| `/etc/nginx/sites-available/protected_<PORT>` | Nginx config |
| `/etc/nginx/sites-enabled/protected_<PORT>`   | Symlink      |
| `/etc/nginx/.htpasswd_<PORT>`                 | Credentials  |

## Nginx Config Generated

```nginx
server {
    listen 5541;

    location / {
        proxy_pass http://127.0.0.1:5540;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        auth_basic "Restricted Access";
        auth_basic_user_file /etc/nginx/.htpasswd_5541;
    }
}
```

## Troubleshooting

### Permission denied

**Problem:** Cannot create nginx config

**Solution:** Run with sudo:

```bash
sudo utix run protect-port protect 5541 5540
```

### Port already in use

**Problem:** Nginx fails to start on protected port

**Solution:** Check what's using the port:

```bash
utix run port-scan -p 5541 localhost
# or
ss -tlnp | grep 5541
```

### Nginx config test fails

**Problem:** `nginx -t` reports errors

**Solution:** Check existing nginx configs:

```bash
nginx -t 2>&1
cat /etc/nginx/sites-enabled/*
```

## Related Scripts

- `ssl-check` - Check SSL certificate expiry
- `port-scan` - Scan open ports

## Changelog

- **v1.0.0** - Initial release with protect/update/remove/list actions
