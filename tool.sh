#!/bin/bash

# Load base logic
source ./scripts/core.sh
source ./scripts/distro-detect.sh

load_distro_script

# Ensure whiptail is installed
ensure_whiptail

# Show interactive menu
show_menu() {
  local choice
  choice=$(whiptail --title "UTILUX TOOL" --menu "Choose an option" 15 60 5 \
    "1" "Install packages" \
    "2" "Remove packages" \
    "3" "Install from GitHub Release" \
    "4" "Install from URL" \
    "5" "Exit" 3>&1 1>&2 2>&3)

  case $? in
    0) # User pressed OK
      case $choice in
        1) handle_install ;;
        2) handle_remove ;;
        3) handle_github_install ;;
        4) handle_url_install ;;
        5) exit 0 ;;
      esac
      ;;
    1) # User pressed Cancel
      exit 0
      ;;
    255) # User pressed ESC
      exit 0
      ;;
  esac
}

# Handle package installation from menu
handle_install() {
  local packages
  packages=$(whiptail --title "Install Packages" --inputbox "Enter package name(s) to install (space-separated):" 10 60 3>&1 1>&2 2>&3)

  if [ $? -eq 0 ] && [ -n "$packages" ]; then
    install_utilities $packages
    whiptail --title "Success" --msgbox "Installation completed!" 8 40
  elif [ $? -eq 0 ]; then
    whiptail --title "Error" --msgbox "No packages specified" 8 40
  fi
}

# Handle package removal from menu
handle_remove() {
  local packages
  packages=$(whiptail --title "Remove Packages" --inputbox "Enter package name(s) to remove (space-separated):" 10 60 3>&1 1>&2 2>&3)

  if [ $? -eq 0 ] && [ -n "$packages" ]; then
    remove_utilities $packages
    whiptail --title "Success" --msgbox "Removal completed!" 8 40
  elif [ $? -eq 0 ]; then
    whiptail --title "Error" --msgbox "No packages specified" 8 40
  fi
}

# Handle GitHub release installation
handle_github_install() {
  local repo
  repo=$(whiptail --title "Install from GitHub" --inputbox "Enter GitHub repository (format: owner/repo):" 10 60 3>&1 1>&2 2>&3)

  if [ $? -eq 0 ] && [ -n "$repo" ]; then
    install_utilities "github:$repo"
    whiptail --title "Success" --msgbox "Installation completed!" 8 40
  elif [ $? -eq 0 ]; then
    whiptail --title "Error" --msgbox "No repository specified" 8 40
  fi
}

# Handle URL installation
handle_url_install() {
  local url
  url=$(whiptail --title "Install from URL" --inputbox "Enter package URL:" 10 60 3>&1 1>&2 2>&3)

  if [ $? -eq 0 ] && [ -n "$url" ]; then
    install_utilities "$url"
    whiptail --title "Success" --msgbox "Installation completed!" 8 40
  elif [ $? -eq 0 ]; then
    whiptail --title "Error" --msgbox "No URL specified" 8 40
  fi
}

# Main menu loop
if [ "$#" -eq 0 ]; then
  while true; do
    show_menu
  done
else
  # Handle CLI arguments
  case "$1" in
    install)
      shift
      install_utilities "$@"
      ;;
    remove)
      shift
      remove_utilities "$@"
      ;;
    *)
      whiptail --title "Usage" --msgbox "Usage: $0 {install|remove} [package...]

Examples:
  $0 install git vim                    # Install packages
  $0 install github:user/repo           # Install from GitHub Release
  $0 install https://example.com/pkg.tar.gz  # Install from direct URL
  $0 remove git                         # Remove a package

Package format: All packages must be .tar.gz files containing scripts in the scripts/ directory" 20 70
      ;;
  esac
fi
