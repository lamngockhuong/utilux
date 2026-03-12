#!/bin/bash
# @name: git-clean
# @version: v1.0.0
# @description: Clean merged branches, prune remotes, and tidy git repos
# @category: dev
# @requires: git
# @tags: git, cleanup, branches
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

# Check if in git repo
check_git_repo() {
  if ! git rev-parse --git-dir &>/dev/null; then
    log_error "Not a git repository"
    exit 1
  fi
}

# Get default branch (main or master)
get_default_branch() {
  local default
  default=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')

  if [[ -z "$default" ]]; then
    # Fallback: check if main or master exists
    if git show-ref --verify --quiet refs/heads/main 2>/dev/null; then
      default="main"
    elif git show-ref --verify --quiet refs/heads/master 2>/dev/null; then
      default="master"
    fi
  fi

  echo "${default:-main}"
}

# List merged branches
list_merged_branches() {
  local default_branch="$1"
  local branches

  branches=$(git branch --merged "$default_branch" 2>/dev/null \
    | grep -vE "^\*|^\s*(main|master|develop|dev)$" \
    | sed 's/^[ *]*//')

  echo "$branches"
}

# Delete merged branches
delete_merged_branches() {
  local default_branch="$1"
  local dry_run="${2:-0}"

  log_info "Finding branches merged into $default_branch..."

  local branches
  branches=$(list_merged_branches "$default_branch")

  if [[ -z "$branches" ]]; then
    log_success "No merged branches to delete"
    return
  fi

  echo ""
  echo "Merged branches:"
  echo "$branches" | while read -r branch; do
    echo "  - $branch"
  done
  echo ""

  if [[ $dry_run -eq 1 ]]; then
    log_warn "DRY RUN - no branches deleted"
    return
  fi

  local count=0
  while read -r branch; do
    [[ -z "$branch" ]] && continue
    if git branch -d "$branch" 2>/dev/null; then
      log_success "Deleted: $branch"
      ((count++))
    else
      log_warn "Could not delete: $branch"
    fi
  done <<<"$branches"

  log_success "Deleted $count merged branches"
}

# Prune remote tracking branches
prune_remotes() {
  log_info "Pruning remote tracking branches..."

  local remotes
  remotes=$(git remote)

  for remote in $remotes; do
    log_info "Pruning $remote..."
    git remote prune "$remote"
  done

  log_success "Remote branches pruned"
}

# Delete remote merged branches
delete_remote_merged() {
  local default_branch="$1"
  local dry_run="${2:-0}"

  log_info "Finding remote branches merged into origin/$default_branch..."

  local branches
  branches=$(git branch -r --merged "origin/$default_branch" 2>/dev/null \
    | grep "origin/" \
    | grep -vE "origin/(main|master|develop|dev|HEAD)" \
    | sed 's/origin\///')

  if [[ -z "$branches" ]]; then
    log_success "No remote merged branches to delete"
    return
  fi

  echo ""
  echo "Remote merged branches:"
  echo "$branches" | while read -r branch; do
    echo "  - origin/$branch"
  done
  echo ""

  if [[ $dry_run -eq 1 ]]; then
    log_warn "DRY RUN - no remote branches deleted"
    return
  fi

  read -r -p "Delete these remote branches? [y/N] " confirm
  if [[ ! "$confirm" =~ ^[Yy] ]]; then
    log_warn "Skipped remote branch deletion"
    return
  fi

  local count=0
  while read -r branch; do
    [[ -z "$branch" ]] && continue
    if git push origin --delete "$branch" 2>/dev/null; then
      log_success "Deleted remote: $branch"
      ((count++))
    else
      log_warn "Could not delete remote: $branch"
    fi
  done <<<"$branches"

  log_success "Deleted $count remote branches"
}

# Clean git garbage
clean_garbage() {
  log_info "Running git garbage collection..."

  git gc --prune=now --aggressive 2>/dev/null || git gc --prune=now

  log_success "Garbage collection complete"
}

# Show repo stats
show_stats() {
  echo ""
  log_info "Repository Statistics:"
  echo ""

  local local_branches remote_branches
  local_branches=$(git branch | wc -l)
  remote_branches=$(git branch -r | wc -l)

  echo "  Local branches:  $local_branches"
  echo "  Remote branches: $remote_branches"

  local size
  size=$(du -sh "$(git rev-parse --git-dir)" 2>/dev/null | cut -f1)
  echo "  Repository size: $size"
}

# Show usage
show_usage() {
  cat <<EOF
Git Clean Utility

Usage: $(basename "$0") [OPTIONS]

OPTIONS:
  -a, --all          Run all cleanup tasks
  -m, --merged       Delete merged local branches
  -r, --remote       Delete merged remote branches
  -p, --prune        Prune remote tracking branches
  -g, --gc           Run garbage collection
  -n, --dry-run      Show what would be done
  -b, --branch NAME  Use NAME as default branch (auto-detected)
  -h, --help         Show this help

EXAMPLES:
  $(basename "$0")              # Delete local merged branches
  $(basename "$0") -a           # Run all cleanup tasks
  $(basename "$0") -m -p        # Delete merged + prune
  $(basename "$0") -r -n        # Dry run remote deletion
  $(basename "$0") -b develop   # Use develop as default branch
EOF
}

# Main
main() {
  check_git_repo

  local do_merged=0
  local do_remote=0
  local do_prune=0
  local do_gc=0
  local dry_run=0
  local default_branch=""

  # Default: delete merged if no options
  [[ $# -eq 0 ]] && do_merged=1

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -a | --all)
        do_merged=1
        do_remote=1
        do_prune=1
        do_gc=1
        shift
        ;;
      -m | --merged)
        do_merged=1
        shift
        ;;
      -r | --remote)
        do_remote=1
        shift
        ;;
      -p | --prune)
        do_prune=1
        shift
        ;;
      -g | --gc)
        do_gc=1
        shift
        ;;
      -n | --dry-run)
        dry_run=1
        shift
        ;;
      -b | --branch)
        default_branch="$2"
        shift 2
        ;;
      -h | --help)
        show_usage
        exit 0
        ;;
      *)
        log_error "Unknown option: $1"
        show_usage
        exit 1
        ;;
    esac
  done

  # Auto-detect default branch if not specified
  [[ -z "$default_branch" ]] && default_branch=$(get_default_branch)

  echo "=========================================="
  echo "  Git Clean Utility"
  echo "=========================================="
  echo ""
  echo "  Repository: $(basename "$(git rev-parse --show-toplevel)")"
  echo "  Default branch: $default_branch"
  echo ""

  [[ $do_merged -eq 1 ]] && delete_merged_branches "$default_branch" "$dry_run"
  [[ $do_prune -eq 1 ]] && prune_remotes
  [[ $do_remote -eq 1 ]] && delete_remote_merged "$default_branch" "$dry_run"
  [[ $do_gc -eq 1 ]] && clean_garbage

  show_stats

  echo ""
  log_success "Git cleanup complete!"
}

main "$@"
