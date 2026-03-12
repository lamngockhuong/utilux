#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging helpers
log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Package utix for release
package_utix() {
  local version="$1"
  local temp_dir="build"
  local package_name="utix-${version}"

  # Check if version is provided
  if [ -z "$version" ]; then
    log_error "Version number is required. Usage: $0 <version>"
    exit 1
  fi

  # Create build directory
  log_info "Creating build directory..."
  rm -rf "$temp_dir"
  mkdir -p "$temp_dir/$package_name"

  # Copy files
  log_info "Copying files..."
  cp tool.sh "$temp_dir/$package_name/"
  cp -r scripts "$temp_dir/$package_name/"
  cp install.sh "$temp_dir/$package_name/"
  cp package.sh "$temp_dir/$package_name/"
  cp README.md "$temp_dir/$package_name/" 2>/dev/null || true

  # Create release package
  log_info "Creating release package..."
  (cd "$temp_dir" && tar -czf "${package_name}.tar.gz" "$package_name")

  log_success "Package created: $temp_dir/${package_name}.tar.gz"
  log_info "You can now create a new release on GitHub and upload this file."
}

# Main packaging process
main() {
  if [ "$#" -ne 1 ]; then
    log_error "Version number is required. Usage: $0 <version>"
    exit 1
  fi

  package_utix "$1"
}

# Run main packaging process
main "$@"
