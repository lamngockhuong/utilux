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

# Check if script is run as root
require_root() {
  if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run as root. Use sudo."
    exit 1
  fi
}

# Detect Linux distribution
detect_distro() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO_ID=$(echo "$ID" | tr '[:upper:]' '[:lower:]')
  else
    log_error "Unable to detect distribution. /etc/os-release not found."
    exit 1
  fi
}

# Install utilux tool
install_utilux() {
  local install_dir="/usr/local/bin"
  local scripts_dir="/usr/local/lib/utilux/scripts"
  local temp_dir="/tmp/utilux_install"
  local repo_owner="lamngockhuong"
  local repo_name="utilux"

  # Create temporary directory
  mkdir -p "$temp_dir"

  # Get latest release URL
  log_info "Getting latest release information..."
  local release_url="https://api.github.com/repos/$repo_owner/$repo_name/releases/latest"
  local download_url=$(curl -s "$release_url" | grep -o '"browser_download_url": ".*\.tar\.gz"' | cut -d'"' -f4)

  if [ -z "$download_url" ]; then
    log_error "No release package found"
    rm -rf "$temp_dir"
    exit 1
  fi

  # Download release package
  log_info "Downloading utilux..."
  if ! curl -s -L "$download_url" -o "$temp_dir/utilux.tar.gz"; then
    log_error "Failed to download utilux"
    rm -rf "$temp_dir"
    exit 1
  fi

  # Extract package
  log_info "Extracting package..."
  if ! tar -xzf "$temp_dir/utilux.tar.gz" -C "$temp_dir"; then
    log_error "Failed to extract package"
    rm -rf "$temp_dir"
    exit 1
  fi

  # Create installation directories
  mkdir -p "$install_dir"
  mkdir -p "$scripts_dir"

  # Install main script
  log_info "Installing utilux..."
  cp "$temp_dir/tool.sh" "$install_dir/utilux"
  chmod +x "$install_dir/utilux"

  # Install core scripts
  cp -r "$temp_dir/scripts/"* "$scripts_dir/"
  chmod +x "$scripts_dir/"*.sh

  # Clean up
  rm -rf "$temp_dir"

  # Create symbolic links for better PATH integration
  ln -sf "$scripts_dir/core.sh" "/usr/local/bin/utilux-core"
  ln -sf "$scripts_dir/distro-detect.sh" "/usr/local/bin/utilux-detect"

  log_success "utilux installed successfully!"
  log_info "You can now use 'utilux' command to manage your utilities."
}

# Install distro-specific scripts
install_distro_scripts() {
  local distro="$1"
  local scripts_dir="/usr/local/lib/utilux/scripts"

  # Check if distro directory exists
  if [ ! -d "$scripts_dir/$distro" ]; then
    log_error "No scripts found for $distro"
    return 1
  fi

  # Install distro-specific scripts
  log_info "Installing $distro specific scripts..."
  cp -r "$scripts_dir/$distro/"* "$scripts_dir/"
  chmod +x "$scripts_dir/"*.sh

  log_success "Installed $distro specific scripts"
  return 0
}

# Main installation process
main() {
  require_root
  detect_distro
  install_utilux

  # Install distro-specific scripts
  log_info "Installing $DISTRO_ID specific scripts..."
  install_distro_scripts "$DISTRO_ID"

  log_success "Installation completed! Try running: utilux install <package>"
}

# Run main installation
main
