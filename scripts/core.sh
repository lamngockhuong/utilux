#!/bin/bash

# Load logging functions
source ./scripts/logging.sh

# Logging helpers
log_info() {
  echo -e "\033[1;34m[INFO]\033[0m $1"
}

log_success() {
  echo -e "\033[1;32m[SUCCESS]\033[0m $1"
}

log_error() {
  echo -e "\033[1;31m[ERROR]\033[0m $1" >&2
}

# Check if the script is run as root or via sudo
require_root() {
  if [ "$EUID" -ne 0 ]; then
    log_error "This action requires root privileges. Use sudo."
    exit 1
  fi
}

# Download and install script package
install_script_package() {
  local source="$1"
  local temp_dir="/tmp/utilux_scripts"

  # Create temp directory
  mkdir -p "$temp_dir"

  # Determine download URL based on source type
  local download_url=""

  if [[ "$source" == "github:"* ]]; then
    # GitHub Release
    local repo_url="${source#github:}"
    local release_url="https://api.github.com/repos/$repo_url/releases/latest"
    download_url=$(curl -s "$release_url" | grep -o '"browser_download_url": ".*\.tar\.gz"' | cut -d'"' -f4)

    if [ -z "$download_url" ]; then
      log_error "No release package found in repository"
      rm -rf "$temp_dir"
      exit 1
    fi
  elif [[ "$source" == "http://"* ]] || [[ "$source" == "https://"* ]]; then
    # Direct URL
    download_url="$source"
  else
    # Custom server with API key
    local api_url="https://your-server.com/api/scripts"
    download_url="$api_url/$source"
  fi

  # Download package
  log_info "Downloading package from $download_url..."

  # Add API key header if provided
  local curl_opts=""
  if [ -n "$UTILUX_API_KEY" ]; then
    curl_opts="-H 'Authorization: Bearer $UTILUX_API_KEY'"
  fi

  if ! eval "curl -s -L $curl_opts '$download_url' -o '$temp_dir/package.tar.gz'"; then
    log_error "Failed to download package"
    rm -rf "$temp_dir"
    exit 1
  fi

  # Extract package
  log_info "Extracting package..."
  if ! tar -xzf "$temp_dir/package.tar.gz" -C "$temp_dir"; then
    log_error "Failed to extract package"
    rm -rf "$temp_dir"
    exit 1
  fi

  # Copy distro-specific scripts
  if [ -d "$temp_dir/scripts" ]; then
    for script in "$temp_dir/scripts"/*.sh; do
      if [ -f "$script" ]; then
        local script_name=$(basename "$script")
        log_info "Installing $script_name..."
        cp "$script" "$(dirname "$0")/$script_name"
        chmod +x "$(dirname "$0")/$script_name"
      fi
    done
  fi

  # Clean up
  rm -rf "$temp_dir"
  log_success "Script package installed successfully"
}

# Check and install whiptail if not present
ensure_whiptail() {
  if ! command -v whiptail &> /dev/null; then
    log_info "Installing whiptail..."
    install_package whiptail
  fi
}

# Install utilities
install_utilities() {
  local packages=("$@")
  for package in "${packages[@]}"; do
    if [[ $package == github:* ]]; then
      # Handle GitHub release
      local repo=${package#github:}
      install_script_package "$repo"
    elif [[ $package == http://* || $package == https://* ]]; then
      # Handle direct URL
      install_script_package "$package"
    else
      # Handle local package
      install_package "$package"
    fi
  done
}

# Remove utilities
remove_utilities() {
  local packages=("$@")
  for package in "${packages[@]}"; do
    remove_package "$package"
  done
}
