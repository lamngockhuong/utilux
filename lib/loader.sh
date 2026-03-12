#!/bin/bash
# @name: loader.sh
# @description: Lazy loading - download, verify, execute scripts
# @version: v1.0.0

# Prevent double sourcing
[[ -n "${_UTILUX_LOADER_LOADED:-}" ]] && return 0
_UTILUX_LOADER_LOADED=1

# Download script from URL
loader_download() {
  local name="$1"
  local url="$2"
  local dest="$UTILUX_CACHE_DIR/${name}.sh.tmp"

  log_debug "Downloading $name from $url"

  if ! curl -sfL "$url" -o "$dest"; then
    rm -f "$dest"
    return 1
  fi

  echo "$dest"
}

# Verify script checksum
loader_verify() {
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
    log_warn "No sha256 tool available, skipping verification"
    return 0
  fi

  if [[ "$actual_sha256" != "$expected_sha256" ]]; then
    log_error "Checksum mismatch for $file"
    log_error "Expected: $expected_sha256"
    log_error "Got: $actual_sha256"
    return 1
  fi

  log_debug "Checksum verified"
  return 0
}

# Full lazy load flow
loader_load() {
  local name="$1"

  # Sanitize name
  name=$(sanitize_name "$name")
  [[ -z "$name" ]] && die "Invalid script name"

  # Dev mode: always use local source (skip cache)
  if [[ "$UTILUX_DEV_MODE" == "1" ]]; then
    registry_fetch
    local script_json
    script_json=$(registry_get_script "$name")
    [[ -z "$script_json" ]] && die "Script not found: $name"

    local file_path
    file_path=$(registry_get_field "$script_json" "file")
    local local_path="$UTILUX_SCRIPT_DIR/registry/${file_path}"

    if [[ -f "$local_path" ]]; then
      log_debug "Dev mode: running $local_path directly"
      echo "$local_path"
      return 0
    else
      die "Dev mode: script not found: $local_path"
    fi
  fi

  # Check cache first
  local cached_path
  if cached_path=$(cache_get "$name"); then
    # Check if we should update
    if [[ "$UTILUX_AUTO_UPDATE" == "1" && "$UTILUX_OFFLINE" != "1" ]]; then
      local script_json
      script_json=$(registry_get_script "$name")

      if [[ -n "$script_json" ]]; then
        local manifest_version
        manifest_version=$(registry_get_field "$script_json" "version")

        if ! cache_is_valid "$name" "$manifest_version"; then
          log_info "Updating $name to $manifest_version..."
          _loader_fetch_and_cache "$name" "$script_json"
          cached_path=$(cache_get "$name")
        fi
      fi
    fi

    echo "$cached_path"
    return 0
  fi

  # Not cached, need to download
  log_info "Loading $name..."

  # Fetch manifest if needed
  registry_fetch

  # Get script metadata
  local script_json
  script_json=$(registry_get_script "$name")

  if [[ -z "$script_json" ]]; then
    die "Script not found: $name"
  fi

  _loader_fetch_and_cache "$name" "$script_json"
  echo "$(cache_get "$name")"
}

# Internal: fetch script and save to cache
_loader_fetch_and_cache() {
  local name="$1"
  local script_json="$2"

  local file_path version sha256
  file_path=$(registry_get_field "$script_json" "file")
  version=$(registry_get_field "$script_json" "version")
  sha256=$(registry_get_field "$script_json" "sha256")

  # Dev mode: use local source files (skip download and verification)
  if [[ "$UTILUX_DEV_MODE" == "1" ]]; then
    local local_path="$UTILUX_SCRIPT_DIR/registry/${file_path}"
    if [[ -f "$local_path" ]]; then
      log_debug "Dev mode: using local $local_path"
      cp "$local_path" "$UTILUX_CACHE_DIR/${name}.sh"
      chmod +x "$UTILUX_CACHE_DIR/${name}.sh"
      cache_set_version "$name" "$version" "$sha256"
      return 0
    else
      die "Dev mode: local script not found: $local_path"
    fi
  fi

  # Production: download from remote
  local base_url url
  base_url=$(registry_base_url)
  url="${base_url}/${file_path}"

  local tmp_file
  tmp_file=$(loader_download "$name" "$url")

  if [[ -z "$tmp_file" || ! -f "$tmp_file" ]]; then
    die "Failed to download script: $name"
  fi

  # Verify checksum
  if ! loader_verify "$tmp_file" "$sha256"; then
    rm -f "$tmp_file"
    die "Script verification failed: $name"
  fi

  # Move to cache
  mv "$tmp_file" "$UTILUX_CACHE_DIR/${name}.sh"
  chmod +x "$UTILUX_CACHE_DIR/${name}.sh"

  # Save metadata
  cache_set_version "$name" "$version" "$sha256"

  log_success "Loaded $name ($version)"
}

# Load and execute script
loader_execute() {
  local name="$1"
  shift
  local args=("$@")

  local script_path
  script_path=$(loader_load "$name")

  if [[ -z "$script_path" || ! -f "$script_path" ]]; then
    die "Failed to load script: $name"
  fi

  log_debug "Executing: $script_path ${args[*]}"

  # Execute script
  # Using bash explicitly for portability
  bash "$script_path" "${args[@]}"
}

# Check if script has required commands
loader_check_requires() {
  local name="$1"

  local script_json
  script_json=$(registry_get_script "$name")

  if [[ -z "$script_json" ]]; then
    return 0  # No metadata, skip check
  fi

  local requires
  if has_cmd jq; then
    requires=$(echo "$script_json" | jq -r '.requires[]? // empty' 2>/dev/null)
  else
    requires=$(echo "$script_json" | grep -o '"requires"[[:space:]]*:[[:space:]]*\[[^]]*\]' | grep -o '"[^"]*"' | tr -d '"')
  fi

  local missing=()
  for cmd in $requires; do
    if ! has_cmd "$cmd"; then
      missing+=("$cmd")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    log_error "Missing required commands: ${missing[*]}"
    return 1
  fi

  return 0
}

# Update specific script or all scripts
loader_update() {
  local name="${1:-}"

  if [[ -n "$name" ]]; then
    # Update specific script
    cache_clear "$name"
    loader_load "$name"
  else
    # Update all cached scripts
    local scripts
    scripts=$(cache_list)

    for script in $scripts; do
      log_info "Updating $script..."
      cache_clear "$script"
      loader_load "$script" || log_warn "Failed to update $script"
    done
  fi
}
