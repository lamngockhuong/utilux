#!/bin/bash

# Load logging functions
source ./scripts/logging.sh

# Display help information
show_help() {
  echo "Utilux Installation Script"
  echo ""
  echo "Description:"
  echo "  This script installs or uninstalls the Utilux utility management tool."
  echo "  Utilux allows you to easily install and manage utilities across different Linux distributions."
  echo ""
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  --help              Show this help message"
  echo "  --uninstall [name]  Uninstall utilux or a custom-named installation"
  echo "  --source <path>     Install from local source code"
  echo "  --develop           Install from develop branch of the repository"
  echo "  --release           Install from GitHub release (default)"
  echo ""
  echo "Installation Examples:"
  echo "  $0                  Install utilux from GitHub release (default)"
  echo "  $0 --source /path/to/source  Install from local source code"
  echo "  $0 --develop        Install from develop branch"
  echo "  $0 --help           Show this help message"
  echo ""
  echo "Uninstallation Examples:"
  echo "  $0 --uninstall      Uninstall utilux (default name)"
  echo "  $0 --uninstall myutilux  Uninstall a custom-named installation"
  echo ""
  echo "Post-Installation Usage:"
  echo "  After installation, you can use the following commands:"
  echo "    utilux install <package>              # Install a package"
  echo "    utilux install github:owner/repo      # Install from GitHub Release"
  echo "    utilux install https://example.com/pkg.tar.gz  # Install from URL"
  echo "    utilux remove <package>               # Remove a package"
  echo ""
  echo "Custom Installation:"
  echo "  If an application named 'utilux' already exists, you will be prompted to:"
  echo "  1. Remove the existing application and install as 'utilux'"
  echo "  2. Install with a different name (e.g., 'myutilux')"
  echo "  3. Cancel the installation"
  echo ""
  echo "Requirements:"
  echo "  - Linux distribution (Ubuntu, Fedora, Alpine, etc.)"
  echo "  - Root privileges (sudo)"
  echo "  - Internet connection for downloading packages"
  echo ""
  echo "Note: This script requires root privileges. Use sudo when running."
  exit 0
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

# Check and install required packages
ensure_required_packages() {
  local packages=("curl" "tar" "gzip" "whiptail" "git")
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

# Install core scripts
install_core_scripts() {
  local source_dir="$1"
  local app_name="${UTILUX_APP_NAME:-utilux}"
  local install_dir="/usr/local/bin"
  local scripts_dir="/usr/local/lib/$app_name/scripts"

  # Create installation directories
  mkdir -p "$install_dir"
  mkdir -p "$scripts_dir"

  # Install main script
  log_info "Installing $app_name..."
  cp "$source_dir/tool.sh" "$install_dir/$app_name"
  chmod +x "$install_dir/$app_name"

  # Install core scripts (excluding distro-specific directories)
  log_info "Installing core scripts..."
  log_info "Source directory: $source_dir/scripts/"
  log_info "Target directory: $scripts_dir/"

  # First, copy only .sh files directly in the scripts directory (not in subdirectories)
  if [ -d "$source_dir/scripts" ]; then
    for file in "$source_dir/scripts/"*.sh; do
      if [ -f "$file" ]; then
        cp "$file" "$scripts_dir/"
        log_info "Copied core script: $(basename "$file")"
      fi
    done
  fi

  # Make all scripts executable
  chmod +x "$scripts_dir/"*.sh 2>/dev/null || true

  # Create symbolic links for better PATH integration
  ln -sf "$scripts_dir/core.sh" "/usr/local/bin/$app_name-core"
  ln -sf "$scripts_dir/distro-detect.sh" "/usr/local/bin/$app_name-detect"

  # Install distro-specific scripts
  install_distro_scripts "$DISTRO_ID" "$source_dir"
}

# Install from GitHub release
install_from_release() {
  local app_name="${UTILUX_APP_NAME:-utilux}"
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
  log_info "Downloading $app_name from GitHub release..."
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

  # Install core scripts
  install_core_scripts "$extracted_dir"

  # Clean up
  rm -rf "$temp_dir"

  log_success "$app_name installed successfully from GitHub release!"
  log_info "You can now use '$app_name' command to manage your utilities."
}

# Install from develop branch
install_from_develop() {
  local app_name="${UTILUX_APP_NAME:-utilux}"
  local temp_dir="/tmp/${app_name}_install"
  local repo_owner="lamngockhuong"
  local repo_name="utilux"

  # Create temporary directory
  mkdir -p "$temp_dir"

  # Clone develop branch
  log_info "Cloning develop branch from repository..."
  if ! git clone -b develop "https://github.com/$repo_owner/$repo_name.git" "$temp_dir/$repo_name"; then
    log_error "Failed to clone repository"
    rm -rf "$temp_dir"
    exit 1
  fi

  # Check if tool.sh exists
  if [ ! -f "$temp_dir/$repo_name/tool.sh" ]; then
    log_error "tool.sh not found in the repository"
    log_info "Contents of $temp_dir/$repo_name:"
    ls -la "$temp_dir/$repo_name"
    rm -rf "$temp_dir"
    exit 1
  fi

  # Check if scripts directory exists
  if [ ! -d "$temp_dir/$repo_name/scripts" ]; then
    log_error "scripts directory not found in the repository"
    log_info "Contents of $temp_dir/$repo_name:"
    ls -la "$temp_dir/$repo_name"
    rm -rf "$temp_dir"
    exit 1
  fi

  # Install core scripts
  install_core_scripts "$temp_dir/$repo_name"

  # Clean up
  rm -rf "$temp_dir"

  log_success "$app_name installed successfully from develop branch!"
  log_info "You can now use '$app_name' command to manage your utilities."
}

# Install from local source
install_from_local() {
  local source_path="$1"
  local app_name="${UTILUX_APP_NAME:-utilux}"

  # Check if source path is provided
  if [ -z "$source_path" ]; then
    log_error "Source path not provided. Use --source <path>"
    exit 1
  fi

  # Check if source path exists
  if [ ! -d "$source_path" ]; then
    log_error "Source path does not exist: $source_path"
    exit 1
  fi

  # Check if tool.sh exists
  if [ ! -f "$source_path/tool.sh" ]; then
    log_error "tool.sh not found in the source path"
    log_info "Contents of $source_path:"
    ls -la "$source_path"
    exit 1
  fi

  # Check if scripts directory exists
  if [ ! -d "$source_path/scripts" ]; then
    log_error "scripts directory not found in the source path"
    log_info "Contents of $source_path:"
    ls -la "$source_path"
    exit 1
  fi

  # Install core scripts
  install_core_scripts "$source_path"

  log_success "$app_name installed successfully from local source!"
  log_info "You can now use '$app_name' command to manage your utilities."
}

# Install distro-specific scripts
install_distro_scripts() {
  local distro="$1"
  local app_name="${UTILUX_APP_NAME:-utilux}"
  local scripts_dir="/usr/local/lib/$app_name/scripts"
  local source_dir="$2"  # Add source directory parameter

  # Check if source directory is provided
  if [ -z "$source_dir" ]; then
    log_error "Source directory not provided for distro scripts"
    return 1
  fi

  # Check if distro directory exists in source
  log_info "Checking for $distro specific scripts in $source_dir/scripts/$distro"
  if [ ! -d "$source_dir/scripts/$distro" ]; then
    log_warn "No scripts directory found for $distro at $source_dir/scripts/$distro"
    log_info "Creating empty $distro directory for future use"
    mkdir -p "$scripts_dir/$distro"
    return 0
  fi

  # Create distro-specific directory if it doesn't exist
  mkdir -p "$scripts_dir/$distro"

  # Copy only .sh files from source to destination
  log_info "Copying $distro specific scripts from $source_dir/scripts/$distro to $scripts_dir/$distro"
  for file in "$source_dir/scripts/$distro/"*.sh; do
    if [ -f "$file" ]; then
      cp "$file" "$scripts_dir/$distro/"
      log_info "Copied $distro script: $(basename "$file")"
    fi
  done

  chmod +x "$scripts_dir/$distro/"*.sh 2>/dev/null || true

  # Create symbolic links for distro-specific scripts
  for script in "$scripts_dir/$distro/"*.sh; do
    if [ -f "$script" ]; then
      local script_name=$(basename "$script")
      ln -sf "$script" "$scripts_dir/$script_name"
      log_info "Created symbolic link for $script_name"
    fi
  done

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
  # Check for help option
  if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    show_help
  fi

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

  # Determine installation source
  local install_source="release"
  local source_path=""

  # Parse command line arguments
  if [ "$1" == "--source" ] && [ -n "$2" ]; then
    install_source="local"
    source_path="$2"
  elif [ "$1" == "--develop" ]; then
    install_source="develop"
  elif [ "$1" == "--release" ]; then
    install_source="release"
  fi

  # Install based on source
  case "$install_source" in
    "release")
      install_from_release
      ;;
    "develop")
      install_from_develop
      ;;
    "local")
      install_from_local "$source_path"
      ;;
  esac

  log_success "Installation completed! Try running: $UTILUX_APP_NAME install <package>"
  log_info "To uninstall later, run: sudo $0 --uninstall $UTILUX_APP_NAME"
}

# Run main installation
main "$@"
