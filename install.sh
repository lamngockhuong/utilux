#!/bin/bash

# Load logging functions
source ./scripts/logging.sh

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

# Check and install required packages
ensure_required_packages() {
  local packages=("curl" "tar" "gzip" "whiptail")
  for package in "${packages[@]}"; do
    if ! command -v "$package" &> /dev/null; then
      log_info "Installing $package..."
      if command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y "$package"
      elif command -v yum &> /dev/null; then
        yum install -y "$package"
      elif command -v dnf &> /dev/null; then
        dnf install -y "$package"
      elif command -v apk &> /dev/null; then
        apk add --no-cache "$package"
      else
        log_error "Could not install $package. Please install it manually."
        exit 1
      fi
    fi
  done
}

# Install utilux tool
install_utilux() {
  local app_name="${UTILUX_APP_NAME:-utilux}"
  local install_dir="/usr/local/bin"
  local scripts_dir="/usr/local/lib/$app_name/scripts"
  local temp_dir="/tmp/${app_name}_install"
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
  log_info "Downloading $app_name..."
  if ! curl -s -L "$download_url" -o "$temp_dir/$app_name.tar.gz"; then
    log_error "Failed to download $app_name"
    rm -rf "$temp_dir"
    exit 1
  fi

  # Extract package
  log_info "Extracting package..."
  if ! tar -xzf "$temp_dir/$app_name.tar.gz" -C "$temp_dir"; then
    log_error "Failed to extract package"
    rm -rf "$temp_dir"
    exit 1
  fi

  # Find the extracted directory
  log_info "Checking extracted files..."
  local extracted_dir=$(find "$temp_dir" -maxdepth 1 -type d -name "utilux-*" | head -n 1)

  if [ -z "$extracted_dir" ]; then
    log_error "Could not find extracted directory"
    log_info "Contents of $temp_dir:"
    ls -la "$temp_dir"
    rm -rf "$temp_dir"
    exit 1
  fi

  log_info "Found extracted directory: $extracted_dir"

  # Check extracted files
  if [ ! -f "$extracted_dir/tool.sh" ]; then
    log_error "tool.sh not found in the package"
    log_info "Contents of $extracted_dir:"
    ls -la "$extracted_dir"
    rm -rf "$temp_dir"
    exit 1
  fi

  if [ ! -d "$extracted_dir/scripts" ]; then
    log_error "scripts directory not found in the package"
    log_info "Contents of $extracted_dir:"
    ls -la "$extracted_dir"
    rm -rf "$temp_dir"
    exit 1
  fi

  # Create installation directories
  mkdir -p "$install_dir"
  mkdir -p "$scripts_dir"

  # Install main script
  log_info "Installing $app_name..."
  cp "$extracted_dir/tool.sh" "$install_dir/$app_name"
  chmod +x "$install_dir/$app_name"

  # Install core scripts
  cp -r "$extracted_dir/scripts/"* "$scripts_dir/"
  chmod +x "$scripts_dir/"*.sh 2>/dev/null || true

  # Clean up
  rm -rf "$temp_dir"

  # Create symbolic links for better PATH integration
  ln -sf "$scripts_dir/core.sh" "/usr/local/bin/$app_name-core"
  ln -sf "$scripts_dir/distro-detect.sh" "/usr/local/bin/$app_name-detect"

  log_success "$app_name installed successfully!"
  log_info "You can now use '$app_name' command to manage your utilities."
}

# Install distro-specific scripts
install_distro_scripts() {
  local distro="$1"
  local app_name="${UTILUX_APP_NAME:-utilux}"
  local scripts_dir="/usr/local/lib/$app_name/scripts"

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

# Check for existing installation
check_existing_installation() {
  local app_name="utilux"
  local default_name="utilux"

  if command -v "$app_name" &> /dev/null; then
    log_warn "An application named '$app_name' already exists in your system."

    # Ask user what to do
    local choice=$(whiptail --title "Application Name Conflict" --menu "An application named '$app_name' already exists. What would you like to do?" 15 60 3 \
      "1" "Remove existing application and install as '$app_name'" \
      "2" "Install with a different name" \
      "3" "Cancel installation" 3>&1 1>&2 2>&3)

    case $? in
      0) # User pressed OK
        case $choice in
          1) # Remove existing and install as utilux
            log_info "Removing existing '$app_name'..."
            rm -f "/usr/local/bin/$app_name"
            rm -f "/usr/local/bin/$app_name-core"
            rm -f "/usr/local/bin/$app_name-detect"
            rm -rf "/usr/local/lib/$app_name"
            ;;
          2) # Install with different name
            app_name=$(whiptail --title "Choose Name" --inputbox "Enter a new name for the application:" 10 60 "$default_name" 3>&1 1>&2 2>&3)
            if [ $? -ne 0 ] || [ -z "$app_name" ]; then
              log_info "Installation cancelled by user."
              exit 0
            fi
            # Check if the new name also exists
            if command -v "$app_name" &> /dev/null; then
              log_error "An application named '$app_name' also exists. Please choose a different name."
              exit 1
            fi
            log_info "Will install as '$app_name'"
            ;;
          3) # Cancel installation
            log_info "Installation cancelled by user."
            exit 0
            ;;
        esac
        ;;
      1) # User pressed Cancel
        log_info "Installation cancelled by user."
        exit 0
        ;;
      255) # User pressed ESC
        log_info "Installation cancelled by user."
        exit 0
        ;;
    esac
  fi

  # Export the app name for use in other functions
  export UTILUX_APP_NAME="$app_name"
}

# Uninstall utilux tool
uninstall_utilux() {
  local app_name="$1"
  if [ -z "$app_name" ]; then
    app_name="utilux"
  fi

  log_info "Uninstalling $app_name..."

  # Remove main script and symbolic links
  rm -f "/usr/local/bin/$app_name"
  rm -f "/usr/local/bin/$app_name-core"
  rm -f "/usr/local/bin/$app_name-detect"

  # Remove scripts directory
  rm -rf "/usr/local/lib/$app_name"

  log_success "$app_name has been uninstalled successfully."
}

# Main installation process
main() {
  # Check if uninstall option is provided
  if [ "$1" == "--uninstall" ]; then
    local app_name="$2"
    if [ -z "$app_name" ]; then
      app_name="utilux"
    fi

    # Check if the application exists
    if ! command -v "$app_name" &> /dev/null; then
      log_error "Application '$app_name' is not installed."
      exit 1
    fi

    # Confirm uninstallation
    if ! whiptail --title "Confirm Uninstallation" --yesno "Are you sure you want to uninstall $app_name?" 10 60; then
      log_info "Uninstallation cancelled by user."
      exit 0
    fi

    uninstall_utilux "$app_name"
    exit 0
  fi

  # Normal installation process
  require_root
  ensure_required_packages
  check_existing_installation
  detect_distro
  install_utilux

  # Install distro-specific scripts
  log_info "Installing $DISTRO_ID specific scripts..."
  install_distro_scripts "$DISTRO_ID"

  log_success "Installation completed! Try running: $UTILUX_APP_NAME install <package>"
}

# Run main installation
main "$@"
