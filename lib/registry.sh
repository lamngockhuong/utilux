#!/bin/bash
# @name: registry.sh
# @description: Registry/manifest management with jq/grep fallback
# @version: v1.0.0

# Prevent double sourcing
[[ -n "${_UTILUX_REGISTRY_LOADED:-}" ]] && return 0
_UTILUX_REGISTRY_LOADED=1

# Fetch manifest from registry URL
registry_fetch() {
  local force="${1:-0}"

  # Skip if offline mode
  if [[ "$UTILUX_OFFLINE" == "1" ]]; then
    if [[ -f "$UTILUX_MANIFEST_FILE" ]]; then
      log_debug "Offline mode, using cached manifest"
      return 0
    else
      die "Offline mode enabled but no cached manifest found"
    fi
  fi

  # Check if manifest exists and is fresh (< 1 hour old)
  if [[ "$force" != "1" && -f "$UTILUX_MANIFEST_FILE" ]]; then
    local age
    age=$(( $(date +%s) - $(stat -c %Y "$UTILUX_MANIFEST_FILE" 2>/dev/null || echo 0) ))
    if [[ $age -lt 3600 ]]; then
      log_debug "Using cached manifest (age: ${age}s)"
      return 0
    fi
  fi

  log_info "Fetching manifest..."

  if ! curl -sfL "$UTILUX_REGISTRY_URL" -o "$UTILUX_MANIFEST_FILE.tmp"; then
    if [[ -f "$UTILUX_MANIFEST_FILE" ]]; then
      log_warn "Failed to fetch manifest, using cached version"
      return 0
    fi
    die "Failed to fetch manifest from $UTILUX_REGISTRY_URL"
  fi

  mv "$UTILUX_MANIFEST_FILE.tmp" "$UTILUX_MANIFEST_FILE"
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

  [[ -f "$UTILUX_MANIFEST_FILE" ]] || registry_fetch
  manifest=$(cat "$UTILUX_MANIFEST_FILE")

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
  done <<< "$manifest"

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

# List all scripts from manifest
registry_list() {
  local category="${1:-}"
  local manifest

  [[ -f "$UTILUX_MANIFEST_FILE" ]] || registry_fetch
  manifest=$(cat "$UTILUX_MANIFEST_FILE")

  if has_cmd jq; then
    if [[ -n "$category" ]]; then
      echo "$manifest" | jq -r ".scripts[] | select(.category == \"$category\") | .name" 2>/dev/null
    else
      echo "$manifest" | jq -r '.scripts[].name' 2>/dev/null
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
        [[ "$cat" == "$category" ]] && echo "$name"
      done
    else
      echo "$names"
    fi
  fi
}

# Search scripts by query (name, description, tags)
registry_search() {
  local query="$1"
  local manifest

  [[ -f "$UTILUX_MANIFEST_FILE" ]] || registry_fetch
  manifest=$(cat "$UTILUX_MANIFEST_FILE")

  if has_cmd jq; then
    echo "$manifest" | jq -r ".scripts[] | select(.name | test(\"$query\"; \"i\")) | .name" 2>/dev/null
    echo "$manifest" | jq -r ".scripts[] | select(.description | test(\"$query\"; \"i\")) | .name" 2>/dev/null
    echo "$manifest" | jq -r ".scripts[] | select(.tags[]? | test(\"$query\"; \"i\")) | .name" 2>/dev/null
  else
    # Grep fallback - simple text search
    echo "$manifest" | grep -i "$query" | grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4
  fi | sort -u
}

# Get manifest version
registry_version() {
  local manifest
  [[ -f "$UTILUX_MANIFEST_FILE" ]] || return 1
  manifest=$(cat "$UTILUX_MANIFEST_FILE")
  _parse_json "$manifest" '.version'
}

# Get base URL from manifest
registry_base_url() {
  local manifest
  [[ -f "$UTILUX_MANIFEST_FILE" ]] || return 1
  manifest=$(cat "$UTILUX_MANIFEST_FILE")
  _parse_json "$manifest" '.base_url'
}

# List categories
registry_categories() {
  local manifest
  [[ -f "$UTILUX_MANIFEST_FILE" ]] || registry_fetch
  manifest=$(cat "$UTILUX_MANIFEST_FILE")

  if has_cmd jq; then
    echo "$manifest" | jq -r '.scripts[].category' 2>/dev/null | sort -u
  else
    echo "$manifest" | grep -o '"category"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4 | sort -u
  fi
}
