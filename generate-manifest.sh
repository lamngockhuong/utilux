#!/bin/bash
# @name: generate-manifest.sh
# @description: Generate manifest.json from registry scripts
# @version: v1.0.0

set -euo pipefail

REGISTRY_DIR="registry"
MANIFEST_FILE="$REGISTRY_DIR/manifest.json"
BASE_URL="https://raw.githubusercontent.com/lamngockhuong/utix/main/registry"

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

      # Check for @draft flag (any value or empty = true)
      local is_draft="false"
      if grep -q "^# @draft" "$script" 2>/dev/null; then
        is_draft="true"
      fi

      # Check for docs file
      local docs_path="$category/$name.md"
      local docs_file="$REGISTRY_DIR/$docs_path"
      local docs_sha256=""
      if [[ -f "$docs_file" ]]; then
        docs_sha256=$(sha256sum "$docs_file" | cut -d' ' -f1)
      fi

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

      # Build optional fields
      local draft_field=""
      [[ "$is_draft" == "true" ]] && draft_field="\"draft\": true,"

      local docs_fields=""
      if [[ -n "$docs_sha256" ]]; then
        docs_fields="\"docs\": \"$docs_path\", \"docs_sha256\": \"$docs_sha256\","
      fi

      scripts+=("{
        \"name\": \"$name\",
        \"category\": \"$category\",
        \"description\": \"$desc\",
        \"version\": \"$version\",
        \"file\": \"$path\",
        \"sha256\": \"$sha256\",
        ${docs_fields}
        ${draft_field}
        \"tags\": $tags_json,
        \"requires\": $requires_json,
        \"author\": \"$author\"
      }")

      local draft_label=""
      [[ "$is_draft" == "true" ]] && draft_label=" [DRAFT]"
      log_info "  Found: $name ($category)$draft_label"
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
    }' >"$MANIFEST_FILE"

  log_success "Generated $MANIFEST_FILE with ${#scripts[@]} scripts"
}

# Check dependencies
command -v jq &>/dev/null || {
  echo "Error: jq required"
  exit 1
}
command -v sha256sum &>/dev/null || {
  echo "Error: sha256sum required"
  exit 1
}

generate_manifest
