#!/bin/bash
# @name: backup-home
# @version: v1.0.0
# @description: Backup home directory to compressed archive
# @category: automation
# @requires: tar
# @tags: backup, archive, home
# @author: lamngockhuong

set -euo pipefail

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Default settings
BACKUP_DIR="${BACKUP_DIR:-$HOME/backups}"
KEEP_BACKUPS="${KEEP_BACKUPS:-5}"

# Default exclude patterns
DEFAULT_EXCLUDES=(
  ".cache"
  ".local/share/Trash"
  "*.tmp"
  "*.log"
  "node_modules"
  ".npm"
  ".nvm"
  ".cargo"
  ".rustup"
  "go/pkg"
  ".gradle"
  ".m2"
  "snap"
  ".steam"
  "Games"
  "Downloads/*.iso"
  "Downloads/*.zip"
  ".local/share/containers"
)

# Create backup
create_backup() {
  local source_dir="$1"
  local output_dir="$2"
  local excludes=("${@:3}")

  # Create output directory
  mkdir -p "$output_dir"

  # Generate backup filename
  local timestamp
  timestamp=$(date +%Y%m%d_%H%M%S)
  local hostname
  hostname=$(hostname -s)
  local backup_name="home_${hostname}_${timestamp}.tar.gz"
  local backup_path="$output_dir/$backup_name"

  log_info "Creating backup..."
  echo "  Source: $source_dir"
  echo "  Output: $backup_path"
  echo ""

  # Build exclude arguments
  local exclude_args=()
  for pattern in "${excludes[@]}"; do
    exclude_args+=("--exclude=$pattern")
  done

  # Create backup with progress
  if command -v pv &>/dev/null; then
    # With progress bar
    tar "${exclude_args[@]}" -cf - -C "$(dirname "$source_dir")" "$(basename "$source_dir")" | \
      pv -s "$(du -sb "$source_dir" 2>/dev/null | cut -f1)" | \
      gzip > "$backup_path"
  else
    # Without progress bar
    tar "${exclude_args[@]}" -czf "$backup_path" -C "$(dirname "$source_dir")" "$(basename "$source_dir")"
  fi

  # Verify backup
  if [[ -f "$backup_path" ]]; then
    local size
    size=$(du -h "$backup_path" | cut -f1)
    log_success "Backup created: $backup_name ($size)"
    echo "$backup_path"
  else
    log_error "Backup failed"
    return 1
  fi
}

# Cleanup old backups
cleanup_old_backups() {
  local backup_dir="$1"
  local keep="$2"

  log_info "Cleaning up old backups (keeping $keep)..."

  local backups
  backups=$(find "$backup_dir" -name "home_*.tar.gz" -type f | sort -r)
  local count
  count=$(echo "$backups" | wc -l)

  if [[ $count -le $keep ]]; then
    log_success "No old backups to remove"
    return
  fi

  local to_delete
  to_delete=$(echo "$backups" | tail -n +$((keep + 1)))

  for backup in $to_delete; do
    log_info "Removing: $(basename "$backup")"
    rm -f "$backup"
  done

  log_success "Cleaned up $((count - keep)) old backups"
}

# List backups
list_backups() {
  local backup_dir="$1"

  echo "Backups in $backup_dir:"
  echo ""

  if [[ ! -d "$backup_dir" ]]; then
    log_warn "Backup directory does not exist"
    return
  fi

  local backups
  backups=$(find "$backup_dir" -name "home_*.tar.gz" -type f 2>/dev/null | sort -r)

  if [[ -z "$backups" ]]; then
    log_warn "No backups found"
    return
  fi

  local i=1
  for backup in $backups; do
    local name size date
    name=$(basename "$backup")
    size=$(du -h "$backup" | cut -f1)
    date=$(stat -c %y "$backup" 2>/dev/null | cut -d. -f1)
    printf "  %2d. %-40s %8s  %s\n" "$i" "$name" "$size" "$date"
    ((i++))
  done
}

# Restore backup
restore_backup() {
  local backup_path="$1"
  local target_dir="${2:-$HOME}"

  if [[ ! -f "$backup_path" ]]; then
    log_error "Backup file not found: $backup_path"
    return 1
  fi

  log_warn "This will restore files to: $target_dir"
  read -r -p "Continue? [y/N] " confirm

  if [[ ! "$confirm" =~ ^[Yy] ]]; then
    log_warn "Restore cancelled"
    return 0
  fi

  log_info "Restoring backup..."

  tar -xzf "$backup_path" -C "$(dirname "$target_dir")"

  log_success "Backup restored to $target_dir"
}

# Show backup info
show_backup_info() {
  local backup_path="$1"

  if [[ ! -f "$backup_path" ]]; then
    log_error "Backup file not found: $backup_path"
    return 1
  fi

  echo "Backup Information:"
  echo ""
  echo "  File: $(basename "$backup_path")"
  echo "  Size: $(du -h "$backup_path" | cut -f1)"
  echo "  Date: $(stat -c %y "$backup_path" | cut -d. -f1)"
  echo ""
  echo "Contents (top-level):"
  tar -tzf "$backup_path" | head -20 | while read -r line; do
    echo "  $line"
  done
  echo "  ..."
}

# Show usage
show_usage() {
  cat << EOF
Home Directory Backup Utility

Usage: $(basename "$0") [COMMAND] [OPTIONS]

COMMANDS:
  create              Create a new backup (default)
  list                List existing backups
  restore <file>      Restore from backup
  info <file>         Show backup information
  clean               Remove old backups

OPTIONS:
  -d, --dir DIR       Backup directory (default: ~/backups)
  -k, --keep N        Keep N most recent backups (default: 5)
  -e, --exclude PAT   Exclude pattern (can be repeated)
  -s, --source DIR    Source directory (default: ~)
  -h, --help          Show this help

EXAMPLES:
  $(basename "$0")                    # Create backup with defaults
  $(basename "$0") -d /mnt/backup     # Backup to external drive
  $(basename "$0") list               # List existing backups
  $(basename "$0") restore ~/backups/home_*.tar.gz
  $(basename "$0") clean -k 3         # Keep only 3 backups

ENVIRONMENT:
  BACKUP_DIR          Default backup directory
  KEEP_BACKUPS        Default number of backups to keep
EOF
}

# Main
main() {
  local command="create"
  local source_dir="$HOME"
  local excludes=("${DEFAULT_EXCLUDES[@]}")

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      create|list|clean)
        command="$1"
        shift
        ;;
      restore|info)
        command="$1"
        if [[ -n "${2:-}" && ! "$2" =~ ^- ]]; then
          local target="$2"
          shift
        fi
        shift
        ;;
      -d|--dir)
        BACKUP_DIR="$2"
        shift 2
        ;;
      -k|--keep)
        KEEP_BACKUPS="$2"
        shift 2
        ;;
      -e|--exclude)
        excludes+=("$2")
        shift 2
        ;;
      -s|--source)
        source_dir="$2"
        shift 2
        ;;
      -h|--help)
        show_usage
        exit 0
        ;;
      *)
        if [[ -f "$1" || -d "$1" ]]; then
          target="$1"
        else
          log_error "Unknown option: $1"
          show_usage
          exit 1
        fi
        shift
        ;;
    esac
  done

  echo "=========================================="
  echo "  Home Backup Utility"
  echo "=========================================="
  echo ""

  case "$command" in
    create)
      create_backup "$source_dir" "$BACKUP_DIR" "${excludes[@]}"
      cleanup_old_backups "$BACKUP_DIR" "$KEEP_BACKUPS"
      ;;
    list)
      list_backups "$BACKUP_DIR"
      ;;
    restore)
      if [[ -z "${target:-}" ]]; then
        log_error "No backup file specified"
        exit 1
      fi
      restore_backup "$target"
      ;;
    info)
      if [[ -z "${target:-}" ]]; then
        log_error "No backup file specified"
        exit 1
      fi
      show_backup_info "$target"
      ;;
    clean)
      cleanup_old_backups "$BACKUP_DIR" "$KEEP_BACKUPS"
      ;;
  esac
}

main "$@"
