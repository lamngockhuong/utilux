#!/bin/bash
# @name: cache.sh
# @description: Cache management for downloaded scripts
# @version: v1.0.0

# Prevent double sourcing
[[ -n "${_UTIX_CACHE_LOADED:-}" ]] && return 0
_UTIX_CACHE_LOADED=1

# Initialize cache directory
cache_init() {
  mkdir -p "$UTIX_CACHE_DIR"
}

# Get cached script path (returns empty if not cached)
cache_get() {
  local name="$1"
  local cached_path="$UTIX_CACHE_DIR/${name}.sh"

  if [[ -f "$cached_path" ]]; then
    echo "$cached_path"
    return 0
  fi
  return 1
}

# Save script to cache
cache_set() {
  local name="$1"
  local content="$2"
  local cached_path="$UTIX_CACHE_DIR/${name}.sh"

  echo "$content" > "$cached_path"
  chmod +x "$cached_path"

  log_debug "Cached script: $name"
}

# Save script from file to cache
cache_set_file() {
  local name="$1"
  local source_path="$2"
  local cached_path="$UTIX_CACHE_DIR/${name}.sh"

  cp "$source_path" "$cached_path"
  chmod +x "$cached_path"

  log_debug "Cached script from file: $name"
}

# Get cached script version from metadata file
cache_version() {
  local name="$1"
  local meta_file="$UTIX_CACHE_DIR/${name}.meta"

  if [[ -f "$meta_file" ]]; then
    grep -m1 "^version=" "$meta_file" 2>/dev/null | cut -d= -f2
  fi
}

# Set cached script version
cache_set_version() {
  local name="$1"
  local version="$2"
  local sha256="${3:-}"
  local meta_file="$UTIX_CACHE_DIR/${name}.meta"

  cat > "$meta_file" << EOF
version=$version
sha256=$sha256
cached=$(date -Iseconds)
EOF
}

# Check if cache is valid (exists and version matches)
cache_is_valid() {
  local name="$1"
  local expected_version="$2"

  local cached_version
  cached_version=$(cache_version "$name")

  [[ -n "$cached_version" && "$cached_version" == "$expected_version" ]]
}

# Clear cache for specific script or all
cache_clear() {
  local name="${1:-}"

  if [[ -n "$name" ]]; then
    rm -f "$UTIX_CACHE_DIR/${name}.sh" "$UTIX_CACHE_DIR/${name}.meta"
    log_info "Cleared cache for: $name"
  else
    rm -rf "$UTIX_CACHE_DIR"/*
    log_info "Cleared all cache"
  fi
}

# List cached scripts
cache_list() {
  local scripts=()
  local f

  shopt -s nullglob
  for f in "$UTIX_CACHE_DIR"/*.sh; do
    [[ -f "$f" ]] || continue
    local name
    name=$(basename "$f" .sh)
    scripts+=("$name")
  done
  shopt -u nullglob

  if [[ ${#scripts[@]} -gt 0 ]]; then
    printf '%s\n' "${scripts[@]}"
  fi
}

# Get cache size in bytes
cache_size() {
  du -sb "$UTIX_CACHE_DIR" 2>/dev/null | cut -f1
}

# Get cache size in human readable format
cache_size_human() {
  du -sh "$UTIX_CACHE_DIR" 2>/dev/null | cut -f1
}
