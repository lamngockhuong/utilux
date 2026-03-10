#!/bin/bash
# @name: generate-manifest
# @description: Generate manifest.json from script headers
# @version: v1.0.0

set -euo pipefail

REGISTRY_DIR="${1:-registry}"
OUTPUT="${2:-$REGISTRY_DIR/manifest.json}"
BASE_URL="${BASE_URL:-https://raw.githubusercontent.com/lamngockhuong/utilux/main/registry}"

# Extract metadata from script header
extract_metadata() {
  local file="$1"
  local field="$2"
  grep -m1 "^# @${field}:" "$file" 2>/dev/null | sed "s/^# @${field}:[[:space:]]*//"
}

# Calculate SHA256
calc_sha256() {
  local file="$1"
  if command -v sha256sum &>/dev/null; then
    sha256sum "$file" | cut -d' ' -f1
  elif command -v shasum &>/dev/null; then
    shasum -a 256 "$file" | cut -d' ' -f1
  else
    echo ""
  fi
}

# Generate manifest
generate() {
  local scripts=()
  local first=1

  # Start JSON
  cat << EOF
{
  "version": "1.0.0",
  "updated": "$(date -I)",
  "base_url": "$BASE_URL",
  "scripts": [
EOF

  # Find all scripts
  while IFS= read -r -d '' file; do
    local name version desc category requires tags author relpath sha256

    name=$(extract_metadata "$file" "name")
    [[ -z "$name" ]] && continue

    version=$(extract_metadata "$file" "version")
    desc=$(extract_metadata "$file" "description")
    category=$(extract_metadata "$file" "category")
    requires=$(extract_metadata "$file" "requires")
    tags=$(extract_metadata "$file" "tags")
    author=$(extract_metadata "$file" "author")

    relpath="${file#$REGISTRY_DIR/}"
    sha256=$(calc_sha256 "$file")

    # Convert requires to JSON array
    local requires_json="[]"
    if [[ -n "$requires" ]]; then
      requires_json="[$(echo "$requires" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$' | sed 's/.*/"&"/' | tr '\n' ',' | sed 's/,$//')]"
    fi

    # Convert tags to JSON array
    local tags_json="[]"
    if [[ -n "$tags" ]]; then
      tags_json="[$(echo "$tags" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$' | sed 's/.*/"&"/' | tr '\n' ',' | sed 's/,$//')]"
    fi

    # Add comma for previous entry
    if [[ $first -eq 0 ]]; then
      printf ","
    fi
    first=0

    # Output script entry
    cat << EOF

    {
      "name": "$name",
      "category": "${category:-uncategorized}",
      "description": "${desc:-No description}",
      "version": "${version:-v1.0.0}",
      "file": "$relpath",
      "sha256": "$sha256",
      "tags": $tags_json,
      "requires": $requires_json,
      "author": "${author:-unknown}"
    }
EOF

  done < <(find "$REGISTRY_DIR" -name "*.sh" -type f -print0 | sort -z)

  # Close JSON
  cat << EOF

  ]
}
EOF
}

# Main
if [[ ! -d "$REGISTRY_DIR" ]]; then
  echo "Error: Registry directory not found: $REGISTRY_DIR" >&2
  exit 1
fi

if [[ "$OUTPUT" == "-" ]]; then
  generate
else
  generate > "$OUTPUT"
  echo "Generated: $OUTPUT"
  echo "Scripts: $(grep -c '"name":' "$OUTPUT")"
fi
