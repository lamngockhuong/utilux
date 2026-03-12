# git-clean

Clean merged branches, prune remotes, and tidy git repositories.

## Overview

Removes merged local branches, prunes stale remote-tracking references,
optionally deletes merged remote branches, and runs garbage collection to reduce
repository size.

## Requirements

| Dependency | Description                |
| ---------- | -------------------------- |
| `git`      | Git version control system |

## Usage

```bash
utix run git-clean [OPTIONS]
```

### Options

| Option          | Short | Description                    |
| --------------- | ----- | ------------------------------ |
| `--all`         | `-a`  | Run all cleanup tasks          |
| `--merged`      | `-m`  | Delete merged local branches   |
| `--remote`      | `-r`  | Delete merged remote branches  |
| `--prune`       | `-p`  | Prune remote tracking branches |
| `--gc`          | `-g`  | Run garbage collection         |
| `--dry-run`     | `-n`  | Show what would be done        |
| `--branch NAME` | `-b`  | Use NAME as default branch     |
| `--help`        | `-h`  | Show help                      |

## Examples

### Basic Usage

```bash
# Delete local merged branches (default)
utix run git-clean

# Preview what would be deleted
utix run git-clean -n

# Run all cleanup tasks
utix run git-clean -a
```

### Selective Cleanup

```bash
# Delete merged + prune remotes
utix run git-clean -m -p

# Prune remote tracking only
utix run git-clean -p

# Garbage collection only
utix run git-clean -g
```

### Custom Default Branch

```bash
# Use develop as default branch
utix run git-clean -b develop

# Clean against main branch
utix run git-clean -b main
```

### Remote Branch Cleanup

```bash
# Preview remote branch deletion
utix run git-clean -r -n

# Delete merged remote branches (with confirmation)
utix run git-clean -r
```

## What Gets Cleaned

### Local Merged Branches (`-m`)

- Branches merged into default branch (main/master)
- Excludes: main, master, develop, dev
- Uses `git branch -d` (safe delete)

### Remote Tracking (`-p`)

- Stale remote-tracking references
- Branches deleted on remote but still tracked locally
- Uses `git remote prune origin`

### Remote Branches (`-r`)

- Merged branches on remote (origin)
- Requires confirmation before deletion
- Uses `git push origin --delete`

### Garbage Collection (`-g`)

- Compresses loose objects
- Removes unreachable objects
- Reduces `.git` directory size

## Protected Branches

These branches are never deleted:

- `main`
- `master`
- `develop`
- `dev`

## Troubleshooting

### Branch not fully merged

**Problem:** Cannot delete branch, not fully merged

**Solution:** Branch has unmerged changes. Either merge or force delete:

```bash
git branch -D branch-name  # Force delete (use with caution)
```

### Not a git repository

**Problem:** Error running in non-git directory

**Solution:** Navigate to repository root:

```bash
cd /path/to/repo
utix run git-clean
```

### Permission denied on remote

**Problem:** Cannot delete remote branches

**Solution:** Ensure you have push access:

```bash
git remote -v  # Check remote URL
# May need to re-authenticate
```

### Default branch not detected

**Problem:** Cannot determine default branch

**Solution:** Specify explicitly:

```bash
utix run git-clean -b main
```

## Related Scripts

- `docker-prune` - Similar cleanup for Docker
- `env-setup` - Install and configure Git

## Changelog

- **v1.0.0** - Initial release with local/remote cleanup and GC
