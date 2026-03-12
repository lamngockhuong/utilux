#!/bin/bash
# @name: generate-website-docs.sh
# @description: Generate Astro content pages from registry script documentation
# @version: v1.0.0

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

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Paths
REGISTRY_DIR="$PROJECT_ROOT/registry"
MANIFEST_FILE="$REGISTRY_DIR/manifest.json"
WEBSITE_CONTENT_DIR="$PROJECT_ROOT/website/src/content/scripts"

# Check dependencies
check_deps() {
  if ! command -v jq &>/dev/null; then
    log_error "jq is required but not installed"
    log_info "Install with: apt install jq (Ubuntu) or brew install jq (macOS)"
    exit 1
  fi
}

# Generate frontmatter from script metadata
generate_frontmatter() {
  local name="$1"
  local category="$2"
  local description="$3"
  local version="$4"
  local tags="$5"
  local requires="$6"
  local author="$7"

  cat <<EOF
---
title: "$name"
description: "$description"
category: "$category"
version: "$version"
tags: $tags
requires: $requires
author: "$author"
---

EOF
}

# Process a single script
process_script() {
  local script_json="$1"

  local name category description version file docs tags requires author draft

  name=$(echo "$script_json" | jq -r '.name')
  category=$(echo "$script_json" | jq -r '.category')
  description=$(echo "$script_json" | jq -r '.description')
  version=$(echo "$script_json" | jq -r '.version')
  docs=$(echo "$script_json" | jq -r '.docs // empty')
  tags=$(echo "$script_json" | jq -c '.tags // []')
  requires=$(echo "$script_json" | jq -c '.requires // []')
  author=$(echo "$script_json" | jq -r '.author // "unknown"')
  draft=$(echo "$script_json" | jq -r '.draft // false')

  # Skip draft scripts
  if [[ "$draft" == "true" ]]; then
    log_info "Skipping $name: draft script"
    return 0
  fi

  # Skip if no docs
  if [[ -z "$docs" ]]; then
    log_warn "Skipping $name: no docs field"
    return 0
  fi

  local docs_path="$REGISTRY_DIR/$docs"

  # Check if docs file exists
  if [[ ! -f "$docs_path" ]]; then
    log_warn "Skipping $name: docs file not found ($docs)"
    return 0
  fi

  local output_file="$WEBSITE_CONTENT_DIR/${name}.md"

  log_info "Processing $name..."

  # Generate frontmatter
  generate_frontmatter "$name" "$category" "$description" "$version" "$tags" "$requires" "$author" >"$output_file"

  # Append docs content (skip any existing frontmatter in source)
  local content
  content=$(cat "$docs_path")

  # Remove frontmatter if present in source
  if [[ "$content" == ---* ]]; then
    content=$(echo "$content" | sed '1,/^---$/d' | sed '1,/^---$/d')
  fi

  # Skip first h1 and following description paragraph (already shown in page header)
  content=$(echo "$content" | awk '
    BEGIN { state=0 }
    state==0 && /^# / { state=1; next }
    state==1 && /^$/ { state=2; next }
    state==2 && /^[^#]/ && !/^$/ { state=3; next }
    state==2 && /^$/ { state=3 }
    { print }
  ')

  echo "$content" >>"$output_file"

  log_success "Generated: $output_file"
}

# Main function
main() {
  log_info "Generating website documentation..."
  echo ""

  check_deps

  # Check manifest exists
  if [[ ! -f "$MANIFEST_FILE" ]]; then
    log_error "Manifest not found: $MANIFEST_FILE"
    exit 1
  fi

  # Create output directory
  mkdir -p "$WEBSITE_CONTENT_DIR"

  # Process each script
  local scripts_count=0
  local generated_count=0

  while IFS= read -r script_json; do
    ((scripts_count++)) || true
    if process_script "$script_json"; then
      ((generated_count++)) || true
    fi
  done < <(jq -c '.scripts[]' "$MANIFEST_FILE")

  echo ""
  log_success "Done! Processed $scripts_count scripts"
  log_info "Output directory: $WEBSITE_CONTENT_DIR"

  # List generated files
  echo ""
  log_info "Generated files:"
  ls -la "$WEBSITE_CONTENT_DIR"/*.md 2>/dev/null | while read -r line; do
    echo "  $line"
  done
}

# Show usage
show_usage() {
  cat <<EOF
Generate Website Documentation

Usage: $(basename "$0") [OPTIONS]

This script reads the registry manifest and generates Astro content
pages from script documentation files.

OPTIONS:
  -h, --help    Show this help message
  -c, --clean   Clean output directory before generating

PATHS:
  Registry:   $REGISTRY_DIR
  Manifest:   $MANIFEST_FILE
  Output:     $WEBSITE_CONTENT_DIR

REQUIREMENTS:
  - jq (JSON processor)

EXAMPLE:
  $(basename "$0")           # Generate docs
  $(basename "$0") --clean   # Clean and regenerate
EOF
}

# Parse arguments
case "${1:-}" in
  -h | --help)
    show_usage
    exit 0
    ;;
  -c | --clean)
    log_info "Cleaning output directory..."
    rm -rf "$WEBSITE_CONTENT_DIR"
    main
    ;;
  "")
    main
    ;;
  *)
    log_error "Unknown option: $1"
    show_usage
    exit 1
    ;;
esac
