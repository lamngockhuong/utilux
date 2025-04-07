#!/bin/bash

# Alpine-specific package management functions

# Update package lists
update_package_list() {
  log_info "Updating package lists..."
  apk update
}

# Install a package
install_package() {
  local package="$1"
  log_info "Installing $package..."
  apk add "$package"
  if [ $? -eq 0 ]; then
    log_success "Successfully installed $package"
  else
    log_error "Failed to install $package"
    exit 1
  fi
}

# Remove a package
remove_package() {
  local package="$1"
  log_info "Removing $package..."
  apk del "$package"
  if [ $? -eq 0 ]; then
    log_success "Successfully removed $package"
  else
    log_error "Failed to remove $package"
    exit 1
  fi
}

# Ensure we have root privileges
require_root

# Update package lists before any operation
update_package_list
