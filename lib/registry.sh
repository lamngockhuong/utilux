#!/bin/bash
# @name: registry.sh
# @description: Registry/manifest management with jq/grep fallback
# @version: v1.0.0

# Prevent double sourcing
[[ -n "${_UTIX_REGISTRY_LOADED:-}" ]] && return 0
_UTIX_REGISTRY_LOADED=1

# Fetch manifest from registry URL
registry_fetch() {
  local force="${1:-0}"

  # Dev mode: use local manifest from source
  if [[ "$UTIX_DEV_MODE" == "1" ]]; then
    local local_manifest="$UTIX_SCRIPT_DIR/registry/manifest.json"
    if [[ -f "$local_manifest" ]]; then
      log_debug "Dev mode: using local manifest"
      cp "$local_manifest" "$UTIX_MANIFEST_FILE"
      return 0
    else
      die "Dev mode: local manifest not found: $local_manifest"
    fi
  fi

  # Skip if offline mode
  if [[ "$UTIX_OFFLINE" == "1" ]]; then
    if [[ -f "$UTIX_MANIFEST_FILE" ]]; then
      log_debug "Offline mode, using cached manifest"
      return 0
    else
      die "Offline mode enabled but no cached manifest found"
    fi
  fi

  # Check if manifest exists and is fresh (< 1 hour old)
  if [[ "$force" != "1" && -f "$UTIX_MANIFEST_FILE" ]]; then
    local age
    age=$(($(date +%s) - $(stat -c %Y "$UTIX_MANIFEST_FILE" 2>/dev/null || echo 0)))
    if [[ $age -lt 3600 ]]; then
      log_debug "Using cached manifest (age: ${age}s)"
      return 0
    fi
  fi

  log_info "Fetching manifest..."

  if ! curl -sfL "$UTIX_REGISTRY_URL" -o "$UTIX_MANIFEST_FILE.tmp"; then
    if [[ -f "$UTIX_MANIFEST_FILE" ]]; then
      log_warn "Failed to fetch manifest, using cached version"
      return 0
    fi
    die "Failed to fetch manifest from $UTIX_REGISTRY_URL"
  fi

  mv "$UTIX_MANIFEST_FILE.tmp" "$UTIX_MANIFEST_FILE"
  log_debug "Manifest updated"
}

# Parse JSON with jq if available, otherwise use grep/awk
_parse_json() {
  local json="$1"
  local query="$2"

  if has_cmd jq; then
    echo "$json" | jq -r "$query" 2>/dev/null
  else
    _parse_json_grep "$json" "$query"
  fi
}

# Fallback JSON parser using grep/awk (limited but works for simple queries)
_parse_json_grep() {
  local json="$1"
  local query="$2"

  case "$query" in
    '.version')
      echo "$json" | grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | cut -d'"' -f4
      ;;
    '.base_url')
      echo "$json" | grep -o '"base_url"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | cut -d'"' -f4
      ;;
    '.scripts[]|.name')
      echo "$json" | grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4
      ;;
    *)
      # For complex queries, return empty
      echo ""
      ;;
  esac
}

# Get script entry from manifest by name
registry_get_script() {
  local name="$1"
  local manifest

  [[ -f "$UTIX_MANIFEST_FILE" ]] || registry_fetch
  manifest=$(cat "$UTIX_MANIFEST_FILE")

  if has_cmd jq; then
    echo "$manifest" | jq -r ".scripts[] | select(.name == \"$name\")" 2>/dev/null
  else
    _registry_get_script_grep "$manifest" "$name"
  fi
}

# Fallback: get script using grep
_registry_get_script_grep() {
  local manifest="$1"
  local name="$2"

  # Extract script block containing the name
  # This is a simplified parser - works for well-formatted JSON
  local in_script=0
  local brace_count=0
  local script_block=""
  local found=0

  while IFS= read -r line; do
    if [[ $in_script -eq 1 ]]; then
      script_block+="$line"
      brace_count=$((brace_count + $(echo "$line" | tr -cd '{' | wc -c)))
      brace_count=$((brace_count - $(echo "$line" | tr -cd '}' | wc -c)))
      if [[ $brace_count -eq 0 ]]; then
        if echo "$script_block" | grep -q "\"name\"[[:space:]]*:[[:space:]]*\"$name\""; then
          echo "$script_block"
          return 0
        fi
        in_script=0
        script_block=""
      fi
    elif [[ "$line" =~ ^\{.*\"name\" ]] || [[ "$line" =~ ^[[:space:]]*\{ ]]; then
      in_script=1
      brace_count=1
      script_block="$line"
    fi
  done <<<"$manifest"

  return 1
}

# Get script field value
registry_get_field() {
  local script_json="$1"
  local field="$2"

  if has_cmd jq; then
    echo "$script_json" | jq -r ".$field // empty" 2>/dev/null
  else
    echo "$script_json" | grep -o "\"$field\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 | cut -d'"' -f4
  fi
}

# List all scripts from manifest (excludes drafts)
registry_list() {
  local category="${1:-}"
  local manifest

  [[ -f "$UTIX_MANIFEST_FILE" ]] || registry_fetch
  manifest=$(cat "$UTIX_MANIFEST_FILE")

  if has_cmd jq; then
    if [[ -n "$category" ]]; then
      echo "$manifest" | jq -r ".scripts[] | select(.category == \"$category\") | select(.draft | not) | .name" 2>/dev/null
    else
      echo "$manifest" | jq -r '.scripts[] | select(.draft | not) | .name' 2>/dev/null
    fi
  else
    # Grep fallback
    local names
    names=$(echo "$manifest" | grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)

    if [[ -n "$category" ]]; then
      # Filter by category (simplified)
      for name in $names; do
        local script_json
        script_json=$(registry_get_script "$name")
        local cat
        cat=$(registry_get_field "$script_json" "category")
        local draft
        draft=$(registry_get_field "$script_json" "draft")
        [[ "$cat" == "$category" && "$draft" != "true" ]] && echo "$name"
      done
    else
      # Filter out drafts
      for name in $names; do
        local script_json
        script_json=$(registry_get_script "$name")
        local draft
        draft=$(registry_get_field "$script_json" "draft")
        [[ "$draft" != "true" ]] && echo "$name"
      done
    fi
  fi
}

# Search scripts by query (name, description, tags) - excludes drafts
registry_search() {
  local query="$1"
  local manifest

  [[ -f "$UTIX_MANIFEST_FILE" ]] || registry_fetch
  manifest=$(cat "$UTIX_MANIFEST_FILE")

  if has_cmd jq; then
    # Single jq call: filter drafts, then match name OR description OR tags
    echo "$manifest" | jq -r --arg q "$query" '
      .scripts[] | select(.draft | not) |
      select(
        (.name | test($q; "i")) or
        (.description | test($q; "i")) or
        ((.tags // [])[] | test($q; "i"))
      ) | .name
    ' 2>/dev/null
  else
    # Grep fallback - filter drafts by excluding scripts with "draft": true
    local names
    names=$(echo "$manifest" | grep -i "$query" | grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
    for name in $names; do
      local script_json
      script_json=$(registry_get_script "$name")
      local draft
      draft=$(registry_get_field "$script_json" "draft")
      [[ "$draft" != "true" ]] && echo "$name"
    done
  fi | sort -u
}

# Get manifest version
registry_version() {
  local manifest
  [[ -f "$UTIX_MANIFEST_FILE" ]] || return 1
  manifest=$(cat "$UTIX_MANIFEST_FILE")
  _parse_json "$manifest" '.version'
}

# Get base URL from manifest
registry_base_url() {
  local manifest
  [[ -f "$UTIX_MANIFEST_FILE" ]] || return 1
  manifest=$(cat "$UTIX_MANIFEST_FILE")
  _parse_json "$manifest" '.base_url'
}

# List categories (only from non-draft scripts)
registry_categories() {
  local manifest
  [[ -f "$UTIX_MANIFEST_FILE" ]] || registry_fetch
  manifest=$(cat "$UTIX_MANIFEST_FILE")

  if has_cmd jq; then
    echo "$manifest" | jq -r '.scripts[] | select(.draft | not) | .category' 2>/dev/null | sort -u
  else
    # Grep fallback - get unique categories from non-draft scripts
    local names categories=""
    names=$(echo "$manifest" | grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
    for name in $names; do
      local script_json
      script_json=$(registry_get_script "$name")
      local draft
      draft=$(registry_get_field "$script_json" "draft")
      if [[ "$draft" != "true" ]]; then
        local cat
        cat=$(registry_get_field "$script_json" "category")
        categories+="$cat"$'\n'
      fi
    done
    echo "$categories" | sort -u | grep -v '^$'
  fi
}
