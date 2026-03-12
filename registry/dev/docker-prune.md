# docker-prune

Clean unused Docker images, containers, volumes, and networks.

## Overview

Reclaim disk space by removing unused Docker resources. Supports selective
cleanup of containers, images, volumes, networks, and build cache with dry-run
preview mode.

## Requirements

| Dependency | Description                                 |
| ---------- | ------------------------------------------- |
| `docker`   | Docker Engine must be installed and running |

## Usage

```bash
utix run docker-prune [OPTIONS]
```

### Options

| Option         | Short | Description                   |
| -------------- | ----- | ----------------------------- |
| `--all`        | `-a`  | Prune everything              |
| `--containers` | `-c`  | Remove stopped containers     |
| `--images`     | `-i`  | Remove unused images          |
| `--dangling`   | `-d`  | Remove only dangling images   |
| `--volumes`    | `-v`  | Remove unused volumes         |
| `--networks`   | `-n`  | Remove unused networks        |
| `--builder`    | `-b`  | Remove build cache            |
| `--system`     | `-s`  | Run docker system prune       |
| `--dry-run`    |       | Preview what would be removed |
| `--help`       | `-h`  | Show help                     |

## Examples

### Basic Usage

```bash
# Show Docker disk usage
utix run docker-prune

# Remove everything unused
utix run docker-prune -a

# Preview what would be removed
utix run docker-prune -a --dry-run
```

### Selective Cleanup

```bash
# Remove stopped containers only
utix run docker-prune -c

# Remove dangling images (no tag)
utix run docker-prune -d

# Remove all unused images
utix run docker-prune -i

# Remove containers and images
utix run docker-prune -c -i

# Remove unused volumes (data loss warning!)
utix run docker-prune -v
```

### System Prune

```bash
# Docker system prune (no volumes)
utix run docker-prune -s

# System prune including volumes
utix run docker-prune -s -v
```

## What Gets Removed

### Containers (`-c`)

- Stopped containers (exited, created status)
- Does NOT remove running containers

### Dangling Images (`-d`)

- Images with `<none>` tag
- Leftover from builds

### Unused Images (`-i`)

- All images not used by any container
- Includes tagged images!

### Volumes (`-v`)

- Volumes not attached to any container
- **Warning:** May contain important data!

### Networks (`-n`)

- Custom networks not used by containers
- Does NOT remove default networks

### Build Cache (`-b`)

- Docker build layer cache
- Safe to remove

## Troubleshooting

### Permission denied

**Problem:** Cannot connect to Docker daemon

**Solution:** Add user to docker group or use sudo:

```bash
sudo usermod -aG docker $USER
# Then log out and back in
```

### Docker daemon not running

**Problem:** Error connecting to Docker

**Solution:** Start Docker service:

```bash
sudo systemctl start docker
```

### Images still taking space after prune

**Problem:** Disk space not freed

**Solution:** Some images may be in use. Check with:

```bash
docker images
docker ps -a
```

### Lost important data

**Problem:** Accidentally removed volumes with data

**Solution:** Always use `--dry-run` first, and backup important volumes:

```bash
docker run --rm -v myvolume:/data -v $(pwd):/backup alpine tar czf /backup/volume-backup.tar.gz /data
```

## Related Scripts

- `disk-cleanup` - General system disk cleanup
- `env-setup` - Install Docker and other dev tools

## Changelog

- **v1.0.0** - Initial release with selective and full cleanup options
