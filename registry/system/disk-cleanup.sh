#!/bin/bash
# @name: disk-cleanup
# @version: v1.0.0
# @description: Clean temporary files, old logs, and package cache
# @category: system
# @requires:
# @tags: cleanup, disk, storage
# @author: lamngockhuong
# @draft

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }

# Check if running as root
is_root() {
  [[ $EUID -eq 0 ]]
}

# Get directory size
get_size() {
  du -sh "$1" 2>/dev/null | cut -f1 || echo "0"
}

# Clean temp files
clean_temp() {
  log_info "Cleaning temporary files..."
  local before after
  before=$(get_size /tmp)

  if is_root; then
    rm -rf /tmp/* 2>/dev/null || true
    rm -rf /var/tmp/* 2>/dev/null || true
  else
    rm -rf /tmp/"$USER"* 2>/dev/null || true
    rm -rf "$HOME"/.cache/thumbnails/* 2>/dev/null || true
  fi

  after=$(get_size /tmp)
  log_success "Temp cleaned: $before -> $after"
}

# Clean user cache
clean_user_cache() {
  log_info "Cleaning user cache..."
  local cache_dir="$HOME/.cache"
  local before
  before=$(get_size "$cache_dir")

  # Safe cache directories to clean
  local dirs=(
    "thumbnails"
    "pip"
    "npm"
    "yarn"
    "pnpm"
    "go-build"
    "fontconfig"
    "mesa_shader_cache"
  )

  for dir in "${dirs[@]}"; do
    rm -rf "${cache_dir:?}/$dir"/* 2>/dev/null || true
  done

  local after
  after=$(get_size "$cache_dir")
  log_success "User cache cleaned: $before -> $after"
}

# Clean package cache (requires root)
clean_package_cache() {
  if ! is_root; then
    log_warn "Skipping package cache (requires root)"
    return
  fi

  log_info "Cleaning package cache..."

  if command -v apt-get &>/dev/null; then
    apt-get clean
    apt-get autoclean
    apt-get autoremove -y 2>/dev/null || true
  elif command -v dnf &>/dev/null; then
    dnf clean all
  elif command -v yum &>/dev/null; then
    yum clean all
  elif command -v apk &>/dev/null; then
    rm -rf /var/cache/apk/*
  fi

  log_success "Package cache cleaned"
}

# Clean old logs (requires root)
clean_old_logs() {
  if ! is_root; then
    log_warn "Skipping old logs (requires root)"
    return
  fi

  log_info "Cleaning old logs..."
  local before
  before=$(get_size /var/log)

  # Remove logs older than 7 days
  find /var/log -type f -name "*.log" -mtime +7 -delete 2>/dev/null || true
  find /var/log -type f -name "*.gz" -mtime +7 -delete 2>/dev/null || true
  find /var/log -type f -name "*.old" -delete 2>/dev/null || true

  # Truncate large logs
  find /var/log -type f -name "*.log" -size +100M -exec truncate -s 0 {} \; 2>/dev/null || true

  local after
  after=$(get_size /var/log)
  log_success "Logs cleaned: $before -> $after"
}

# Clean journal logs (requires root)
clean_journal() {
  if ! is_root; then
    return
  fi

  if command -v journalctl &>/dev/null; then
    log_info "Cleaning journal logs..."
    journalctl --vacuum-time=7d --quiet
    log_success "Journal cleaned"
  fi
}

# Show disk usage summary
show_summary() {
  echo ""
  log_info "Disk usage summary:"
  df -h / | tail -1 | awk '{print "  Root: " $3 " used / " $2 " total (" $5 " used)"}'

  if [[ -d "$HOME" ]]; then
    df -h "$HOME" 2>/dev/null | tail -1 | awk '{print "  Home: " $3 " used / " $2 " total (" $5 " used)"}'
  fi
}

# Main
main() {
  echo "=========================================="
  echo "  Disk Cleanup Utility"
  echo "=========================================="
  echo ""

  local dry_run=0
  if [[ "${1:-}" == "--dry-run" || "${1:-}" == "-n" ]]; then
    dry_run=1
    log_warn "Dry run mode - no files will be deleted"
    echo ""
  fi

  if [[ $dry_run -eq 1 ]]; then
    log_info "Would clean:"
    echo "  - Temporary files (/tmp, /var/tmp)"
    echo "  - User cache (~/.cache)"
    is_root && echo "  - Package cache"
    is_root && echo "  - Old logs (/var/log)"
    is_root && echo "  - Journal logs"
  else
    clean_temp
    clean_user_cache
    clean_package_cache
    clean_old_logs
    clean_journal
  fi

  show_summary
  echo ""
  log_success "Cleanup complete!"
}

main "$@"
