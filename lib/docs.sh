#!/bin/bash
# @name: docs.sh
# @description: Documentation loading, caching, and rendering
# @version: v1.0.0

# Prevent double sourcing
[[ -n "${_UTILUX_DOCS_LOADED:-}" ]] && return 0
_UTILUX_DOCS_LOADED=1

# Docs cache directory
UTILUX_DOCS_CACHE_DIR="${UTILUX_CACHE_DIR}/docs"

# Initialize docs cache directory
docs_init() {
  mkdir -p "$UTILUX_DOCS_CACHE_DIR"
}

# Get docs cache path for a script
docs_cache_path() {
  local name="$1"
  echo "$UTILUX_DOCS_CACHE_DIR/${name}.md"
}

# Get docs version file path
docs_version_path() {
  local name="$1"
  echo "$UTILUX_DOCS_CACHE_DIR/${name}.version"
}

# Check if docs are cached
docs_is_cached() {
  local name="$1"
  [[ -f "$(docs_cache_path "$name")" ]]
}

# Get cached docs version
docs_version() {
  local name="$1"
  local version_file
  version_file=$(docs_version_path "$name")

  if [[ -f "$version_file" ]]; then
    cat "$version_file"
  fi
}

# Save docs to cache
docs_cache_set() {
  local name="$1"
  local content="$2"
  local version="$3"

  docs_init

  echo "$content" > "$(docs_cache_path "$name")"
  echo "$version" > "$(docs_version_path "$name")"

  log_debug "Cached docs for: $name"
}

# Get docs from cache
docs_cache_get() {
  local name="$1"
  local cached_path
  cached_path=$(docs_cache_path "$name")

  if [[ -f "$cached_path" ]]; then
    cat "$cached_path"
  fi
}

# Download docs from registry
docs_download() {
  local name="$1"
  local url="$2"
  local dest="$UTILUX_DOCS_CACHE_DIR/${name}.md.tmp"

  docs_init

  log_debug "Downloading docs for $name from $url"

  if ! curl -sfL "$url" -o "$dest"; then
    rm -f "$dest"
    return 1
  fi

  echo "$dest"
}

# Verify docs checksum
docs_verify() {
  local file="$1"
  local expected_sha256="$2"

  # Skip verification if no checksum provided
  [[ -z "$expected_sha256" ]] && return 0

  local actual_sha256
  if has_cmd sha256sum; then
    actual_sha256=$(sha256sum "$file" | cut -d' ' -f1)
  elif has_cmd shasum; then
    actual_sha256=$(shasum -a 256 "$file" | cut -d' ' -f1)
  else
    log_warn "No sha256 tool available, skipping docs verification"
    return 0
  fi

  if [[ "$actual_sha256" != "$expected_sha256" ]]; then
    log_debug "Docs checksum mismatch for $file"
    return 1
  fi

  log_debug "Docs checksum verified"
  return 0
}

# Load docs (download if needed, use cache)
docs_load() {
  local name="$1"

  # Sanitize name
  name=$(sanitize_name "$name")
  [[ -z "$name" ]] && return 1

  # Check cache first
  if docs_is_cached "$name"; then
    docs_cache_get "$name"
    return 0
  fi

  # Need to fetch from remote
  if [[ "$UTILUX_OFFLINE" == "1" ]]; then
    log_warn "Offline mode: docs not available for $name"
    return 1
  fi

  # Fetch manifest if needed
  registry_fetch

  # Get script metadata
  local script_json
  script_json=$(registry_get_script "$name")

  if [[ -z "$script_json" ]]; then
    log_error "Script not found: $name"
    return 1
  fi

  # Get docs path
  local docs_path docs_sha256 version base_url
  docs_path=$(registry_get_field "$script_json" "docs")
  docs_sha256=$(registry_get_field "$script_json" "docs_sha256")
  version=$(registry_get_field "$script_json" "version")
  base_url=$(registry_base_url)

  if [[ -z "$docs_path" ]]; then
    log_debug "No docs available for $name"
    return 1
  fi

  # Build URL and download
  local url="${base_url}/${docs_path}"
  local tmp_file
  tmp_file=$(docs_download "$name" "$url")

  if [[ -z "$tmp_file" || ! -f "$tmp_file" ]]; then
    log_debug "Failed to download docs for $name"
    return 1
  fi

  # Verify if hash provided
  if [[ -n "$docs_sha256" ]]; then
    if ! docs_verify "$tmp_file" "$docs_sha256"; then
      rm -f "$tmp_file"
      log_warn "Docs verification failed for $name"
      return 1
    fi
  fi

  # Move to cache
  local cached_path
  cached_path=$(docs_cache_path "$name")
  mv "$tmp_file" "$cached_path"
  echo "$version" > "$(docs_version_path "$name")"

  log_debug "Loaded docs for $name"

  # Return content
  cat "$cached_path"
}

# Detect best markdown renderer
docs_detect_renderer() {
  if has_cmd glow; then
    echo "glow"
  elif has_cmd bat; then
    echo "bat"
  elif has_cmd mdcat; then
    echo "mdcat"
  else
    echo "cat"
  fi
}

# Render markdown content to terminal
docs_render() {
  local content="$1"
  local renderer
  renderer=$(docs_detect_renderer)

  case "$renderer" in
    glow)
      echo "$content" | glow -s dark -
      ;;
    bat)
      echo "$content" | bat --language=md --style=plain --paging=never
      ;;
    mdcat)
      echo "$content" | mdcat
      ;;
    *)
      # Plain text fallback with basic formatting
      echo "$content"
      ;;
  esac
}

# Main entry: load and show docs
docs_show() {
  local name="$1"

  if [[ -z "$name" ]]; then
    log_error "Usage: docs_show <script-name>"
    return 1
  fi

  local content
  content=$(docs_load "$name")

  if [[ -z "$content" ]]; then
    echo ""
    echo "No documentation available for '$name'"
    echo ""
    echo "Documentation may not exist yet or failed to download."
    echo "Try running 'utilux info $name' for basic script information."
    return 1
  fi

  docs_render "$content"
}

# Clear docs cache
docs_cache_clear() {
  local name="${1:-}"

  if [[ -n "$name" ]]; then
    rm -f "$(docs_cache_path "$name")" "$(docs_version_path "$name")"
    log_info "Cleared docs cache for: $name"
  else
    rm -rf "$UTILUX_DOCS_CACHE_DIR"/*
    log_info "Cleared all docs cache"
  fi
}

# List cached docs
docs_cache_list() {
  local docs=()
  local f

  shopt -s nullglob
  for f in "$UTILUX_DOCS_CACHE_DIR"/*.md; do
    [[ -f "$f" ]] || continue
    local name
    name=$(basename "$f" .md)
    docs+=("$name")
  done
  shopt -u nullglob

  if [[ ${#docs[@]} -gt 0 ]]; then
    printf '%s\n' "${docs[@]}"
  fi
}
