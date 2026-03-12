#!/bin/bash
# @name: log-rotate
# @version: v1.0.0
# @description: Rotate, compress, and manage log files
# @category: system
# @requires: gzip
# @tags: logs, rotate, maintenance
# @author: lamngockhuong
# @draft

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
LOG_DIR="${LOG_DIR:-/var/log}"
MAX_SIZE="${MAX_SIZE:-10M}"
KEEP_DAYS="${KEEP_DAYS:-30}"
COMPRESS="${COMPRESS:-1}"

# Parse size to bytes
parse_size() {
  local size="$1"
  local num="${size%[KMG]}"
  local unit="${size: -1}"

  case "$unit" in
    K | k) echo $((num * 1024)) ;;
    M | m) echo $((num * 1024 * 1024)) ;;
    G | g) echo $((num * 1024 * 1024 * 1024)) ;;
    *) echo "$size" ;;
  esac
}

# Get file size in bytes
get_file_size() {
  stat -c%s "$1" 2>/dev/null || echo 0
}

# Rotate a single log file
rotate_file() {
  local file="$1"
  local max_bytes
  max_bytes=$(parse_size "$MAX_SIZE")

  local size
  size=$(get_file_size "$file")

  if [[ $size -lt $max_bytes ]]; then
    return 0
  fi

  log_info "Rotating: $file ($(numfmt --to=iec $size))"

  # Rotate existing backups
  for i in $(seq 9 -1 1); do
    if [[ -f "${file}.$i" ]]; then
      mv "${file}.$i" "${file}.$((i + 1))"
    fi
    if [[ -f "${file}.$i.gz" ]]; then
      mv "${file}.$i.gz" "${file}.$((i + 1)).gz"
    fi
  done

  # Move current to .1
  cp "$file" "${file}.1"
  truncate -s 0 "$file"

  # Compress if enabled
  if [[ "$COMPRESS" == "1" ]] && command -v gzip &>/dev/null; then
    gzip -f "${file}.1"
  fi

  log_success "Rotated: $file"
}

# Remove old log files
cleanup_old() {
  local dir="$1"

  log_info "Cleaning logs older than $KEEP_DAYS days in $dir"

  local count=0
  while IFS= read -r -d '' file; do
    rm -f "$file"
    ((count++))
  done < <(find "$dir" -type f \( -name "*.log.*" -o -name "*.gz" \) -mtime +"$KEEP_DAYS" -print0 2>/dev/null)

  if [[ $count -gt 0 ]]; then
    log_success "Removed $count old files"
  fi
}

# Process a directory
process_directory() {
  local dir="$1"

  if [[ ! -d "$dir" ]]; then
    log_error "Directory not found: $dir"
    return 1
  fi

  log_info "Processing: $dir"

  # Find and rotate large log files
  while IFS= read -r -d '' file; do
    rotate_file "$file"
  done < <(find "$dir" -maxdepth 2 -type f -name "*.log" -print0 2>/dev/null)

  # Cleanup old files
  cleanup_old "$dir"
}

# Show usage
show_usage() {
  cat <<EOF
Log Rotate Utility

Usage: $(basename "$0") [OPTIONS] [DIRECTORY]

OPTIONS:
  -s, --size SIZE     Max file size before rotation (default: 10M)
  -k, --keep DAYS     Keep logs for N days (default: 30)
  -n, --no-compress   Don't compress rotated logs
  -d, --dry-run       Show what would be done
  -h, --help          Show this help

EXAMPLES:
  $(basename "$0")                      # Rotate /var/log
  $(basename "$0") /home/user/logs      # Rotate custom directory
  $(basename "$0") -s 50M -k 7          # 50MB max, keep 7 days
  $(basename "$0") --dry-run            # Preview changes

ENVIRONMENT:
  LOG_DIR       Default log directory
  MAX_SIZE      Default max size
  KEEP_DAYS     Default retention days
EOF
}

# Main
main() {
  local dry_run=0
  local target_dir="$LOG_DIR"

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -s | --size)
        MAX_SIZE="$2"
        shift 2
        ;;
      -k | --keep)
        KEEP_DAYS="$2"
        shift 2
        ;;
      -n | --no-compress)
        COMPRESS=0
        shift
        ;;
      -d | --dry-run)
        dry_run=1
        shift
        ;;
      -h | --help)
        show_usage
        exit 0
        ;;
      -*)
        log_error "Unknown option: $1"
        show_usage
        exit 1
        ;;
      *)
        target_dir="$1"
        shift
        ;;
    esac
  done

  echo "=========================================="
  echo "  Log Rotate Utility"
  echo "=========================================="
  echo ""
  echo "  Directory: $target_dir"
  echo "  Max Size:  $MAX_SIZE"
  echo "  Keep Days: $KEEP_DAYS"
  echo "  Compress:  $([ "$COMPRESS" == "1" ] && echo "Yes" || echo "No")"
  echo ""

  if [[ $dry_run -eq 1 ]]; then
    log_warn "DRY RUN - no changes will be made"
    echo ""

    log_info "Would rotate files larger than $(parse_size "$MAX_SIZE" | numfmt --to=iec)"
    find "$target_dir" -maxdepth 2 -type f -name "*.log" -size +"$MAX_SIZE" 2>/dev/null | head -10

    echo ""
    log_info "Would remove files older than $KEEP_DAYS days"
    find "$target_dir" -type f \( -name "*.log.*" -o -name "*.gz" \) -mtime +"$KEEP_DAYS" 2>/dev/null | head -10
  else
    # Check permissions
    if [[ ! -w "$target_dir" ]]; then
      log_error "No write permission to $target_dir"
      log_info "Try running with sudo"
      exit 1
    fi

    process_directory "$target_dir"
  fi

  echo ""
  log_success "Done!"
}

main "$@"
