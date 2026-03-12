#!/bin/bash
# @name: docker-prune
# @version: v1.0.0
# @description: Clean unused Docker images, containers, volumes, and networks
# @category: dev
# @requires: docker
# @tags: docker, cleanup, containers
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

# Check Docker is available
check_docker() {
  if ! command -v docker &>/dev/null; then
    log_error "Docker is not installed"
    exit 1
  fi

  if ! docker info &>/dev/null; then
    log_error "Docker daemon is not running or you don't have permission"
    log_info "Try: sudo $(basename "$0") or add user to docker group"
    exit 1
  fi
}

# Format bytes
format_bytes() {
  local bytes="$1"
  if [[ $bytes -ge 1073741824 ]]; then
    echo "$(awk "BEGIN {printf \"%.1f\", $bytes/1073741824}")GB"
  elif [[ $bytes -ge 1048576 ]]; then
    echo "$(awk "BEGIN {printf \"%.1f\", $bytes/1048576}")MB"
  elif [[ $bytes -ge 1024 ]]; then
    echo "$(awk "BEGIN {printf \"%.1f\", $bytes/1024}")KB"
  else
    echo "${bytes}B"
  fi
}

# Get Docker disk usage
get_disk_usage() {
  log_info "Analyzing Docker disk usage..."

  local output
  output=$(docker system df 2>/dev/null)

  echo ""
  echo "$output"
  echo ""
}

# Clean stopped containers
clean_containers() {
  local dry_run="${1:-0}"

  log_info "Finding stopped containers..."

  local containers
  containers=$(docker ps -aq --filter "status=exited" --filter "status=created" 2>/dev/null)

  if [[ -z "$containers" ]]; then
    log_success "No stopped containers"
    return
  fi

  local count
  count=$(echo "$containers" | wc -w)
  log_info "Found $count stopped containers"

  if [[ $dry_run -eq 1 ]]; then
    log_warn "DRY RUN - containers not removed"
    docker ps -a --filter "status=exited" --filter "status=created" --format "  {{.Names}} ({{.Image}}) - {{.Status}}" | head -10
    return
  fi

  docker container prune -f
  log_success "Removed $count containers"
}

# Clean dangling images
clean_dangling_images() {
  local dry_run="${1:-0}"

  log_info "Finding dangling images..."

  local images
  images=$(docker images -q --filter "dangling=true" 2>/dev/null)

  if [[ -z "$images" ]]; then
    log_success "No dangling images"
    return
  fi

  local count
  count=$(echo "$images" | wc -w)
  log_info "Found $count dangling images"

  if [[ $dry_run -eq 1 ]]; then
    log_warn "DRY RUN - images not removed"
    return
  fi

  docker image prune -f
  log_success "Removed dangling images"
}

# Clean unused images
clean_unused_images() {
  local dry_run="${1:-0}"

  log_info "Finding unused images..."

  # Get image count
  local before
  before=$(docker images -q 2>/dev/null | wc -l)

  if [[ $dry_run -eq 1 ]]; then
    log_warn "DRY RUN - would remove unused images"
    docker images --format "  {{.Repository}}:{{.Tag}} ({{.Size}})" | head -10
    return
  fi

  docker image prune -af

  local after
  after=$(docker images -q 2>/dev/null | wc -l)
  local removed=$((before - after))

  log_success "Removed $removed unused images"
}

# Clean volumes
clean_volumes() {
  local dry_run="${1:-0}"

  log_info "Finding unused volumes..."

  local volumes
  volumes=$(docker volume ls -q --filter "dangling=true" 2>/dev/null)

  if [[ -z "$volumes" ]]; then
    log_success "No unused volumes"
    return
  fi

  local count
  count=$(echo "$volumes" | wc -w)
  log_info "Found $count unused volumes"

  if [[ $dry_run -eq 1 ]]; then
    log_warn "DRY RUN - volumes not removed"
    echo "$volumes" | head -10 | while read -r vol; do
      echo "  $vol"
    done
    return
  fi

  docker volume prune -f
  log_success "Removed unused volumes"
}

# Clean networks
clean_networks() {
  local dry_run="${1:-0}"

  log_info "Finding unused networks..."

  # Count before
  local before
  before=$(docker network ls -q 2>/dev/null | wc -l)

  if [[ $dry_run -eq 1 ]]; then
    log_warn "DRY RUN - networks not removed"
    return
  fi

  docker network prune -f

  local after
  after=$(docker network ls -q 2>/dev/null | wc -l)
  local removed=$((before - after))

  log_success "Removed $removed unused networks"
}

# Clean build cache
clean_build_cache() {
  local dry_run="${1:-0}"

  log_info "Finding build cache..."

  if [[ $dry_run -eq 1 ]]; then
    log_warn "DRY RUN - build cache not removed"
    docker builder du 2>/dev/null | head -10 || true
    return
  fi

  docker builder prune -af 2>/dev/null || true
  log_success "Build cache cleared"
}

# Full system prune
system_prune() {
  local dry_run="${1:-0}"
  local include_volumes="${2:-0}"

  log_info "Running full system prune..."

  if [[ $dry_run -eq 1 ]]; then
    log_warn "DRY RUN - nothing removed"
    docker system df
    return
  fi

  if [[ $include_volumes -eq 1 ]]; then
    docker system prune -af --volumes
    log_success "System pruned (including volumes)"
  else
    docker system prune -af
    log_success "System pruned (volumes preserved)"
  fi
}

# Show usage
show_usage() {
  cat << EOF
Docker Prune Utility

Usage: $(basename "$0") [OPTIONS]

OPTIONS:
  -a, --all          Prune everything (containers, images, volumes, networks)
  -c, --containers   Remove stopped containers
  -i, --images       Remove unused images
  -d, --dangling     Remove only dangling images
  -v, --volumes      Remove unused volumes
  -n, --networks     Remove unused networks
  -b, --builder      Remove build cache
  -s, --system       Run docker system prune
  --dry-run          Show what would be removed
  -h, --help         Show this help

EXAMPLES:
  $(basename "$0")              # Show disk usage
  $(basename "$0") -a           # Prune everything
  $(basename "$0") -c -i        # Containers and images
  $(basename "$0") -s           # System prune
  $(basename "$0") -a --dry-run # Preview what would be removed
EOF
}

# Main
main() {
  check_docker

  local do_containers=0
  local do_images=0
  local do_dangling=0
  local do_volumes=0
  local do_networks=0
  local do_builder=0
  local do_system=0
  local dry_run=0

  # If no args, just show usage
  if [[ $# -eq 0 ]]; then
    get_disk_usage
    echo "Run with -h for options"
    exit 0
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -a|--all)
        do_containers=1
        do_images=1
        do_volumes=1
        do_networks=1
        do_builder=1
        shift
        ;;
      -c|--containers)
        do_containers=1
        shift
        ;;
      -i|--images)
        do_images=1
        shift
        ;;
      -d|--dangling)
        do_dangling=1
        shift
        ;;
      -v|--volumes)
        do_volumes=1
        shift
        ;;
      -n|--networks)
        do_networks=1
        shift
        ;;
      -b|--builder)
        do_builder=1
        shift
        ;;
      -s|--system)
        do_system=1
        shift
        ;;
      --dry-run)
        dry_run=1
        shift
        ;;
      -h|--help)
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

  echo "=========================================="
  echo "  Docker Prune Utility"
  echo "=========================================="
  echo ""

  get_disk_usage

  if [[ $do_system -eq 1 ]]; then
    system_prune "$dry_run" "$do_volumes"
  else
    [[ $do_containers -eq 1 ]] && clean_containers "$dry_run"
    [[ $do_dangling -eq 1 ]] && clean_dangling_images "$dry_run"
    [[ $do_images -eq 1 ]] && clean_unused_images "$dry_run"
    [[ $do_volumes -eq 1 ]] && clean_volumes "$dry_run"
    [[ $do_networks -eq 1 ]] && clean_networks "$dry_run"
    [[ $do_builder -eq 1 ]] && clean_build_cache "$dry_run"
  fi

  echo ""
  get_disk_usage

  log_success "Docker cleanup complete!"
}

main "$@"
