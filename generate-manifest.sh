#!/bin/bash
# @name: generate-manifest.sh
# @description: Generate manifest.json from registry scripts
# @version: v1.0.0

set -euo pipefail

REGISTRY_DIR="registry"
MANIFEST_FILE="$REGISTRY_DIR/manifest.json"
BASE_URL="https://raw.githubusercontent.com/lamngockhuong/utilux/main/registry"

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }

# Extract metadata from script header
extract_field() {
  local file="$1"
  local field="$2"
  grep -m1 "^# @$field:" "$file" 2>/dev/null | sed "s/^# @$field:[[:space:]]*//" || echo ""
}

# Generate manifest.json
generate_manifest() {
  log_info "Scanning $REGISTRY_DIR for scripts..."

  local scripts=()
  local categories=("automation" "dev" "network" "system")

  for category in "${categories[@]}"; do
    local cat_dir="$REGISTRY_DIR/$category"
    [[ -d "$cat_dir" ]] || continue

    for script in "$cat_dir"/*.sh; do
      [[ -f "$script" ]] || continue

      local name=$(basename "$script" .sh)
      local version=$(extract_field "$script" "version")
      local desc=$(extract_field "$script" "description")
      local requires=$(extract_field "$script" "requires")
      local tags=$(extract_field "$script" "tags")
      local author=$(extract_field "$script" "author")
      local sha256=$(sha256sum "$script" | cut -d' ' -f1)
      local path="$category/$name.sh"

      # Default values
      [[ -z "$version" ]] && version="v1.0.0"
      [[ -z "$author" ]] && author="lamngockhuong"

      # Build requires array
      local requires_json="[]"
      if [[ -n "$requires" ]]; then
        requires_json=$(echo "$requires" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | jq -R . | jq -s .)
      fi

      # Build tags array
      local tags_json="[]"
      if [[ -n "$tags" ]]; then
        tags_json=$(echo "$tags" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | jq -R . | jq -s .)
      fi

      scripts+=("{
        \"name\": \"$name\",
        \"description\": \"$desc\",
        \"version\": \"$version\",
        \"category\": \"$category\",
        \"path\": \"$path\",
        \"sha256\": \"$sha256\",
        \"tags\": $tags_json,
        \"requires\": $requires_json,
        \"author\": \"$author\"
      }")

      log_info "  Found: $name ($category)"
    done
  done

  # Build final JSON
  local updated=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local scripts_json=$(printf '%s\n' "${scripts[@]}" | jq -s '.')

  jq -n \
    --arg version "1.0.0" \
    --arg updated "$updated" \
    --arg base_url "$BASE_URL" \
    --argjson scripts "$scripts_json" \
    '{
      version: $version,
      updated: $updated,
      base_url: $base_url,
      scripts: $scripts
    }' > "$MANIFEST_FILE"

  log_success "Generated $MANIFEST_FILE with ${#scripts[@]} scripts"
}

# Check dependencies
command -v jq &>/dev/null || { echo "Error: jq required"; exit 1; }
command -v sha256sum &>/dev/null || { echo "Error: sha256sum required"; exit 1; }

generate_manifest
