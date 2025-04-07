#!/bin/bash

# Detect and normalize the distribution ID
detect_distro() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO_ID=$(echo "$ID" | tr '[:upper:]' '[:lower:]')
  else
    echo "Unable to detect distribution. /etc/os-release not found."
    exit 1
  fi
}

# Load distro-specific logic based on detected distro
load_distro_script() {
  detect_distro

  # Get the absolute path to the scripts directory
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  case "$DISTRO_ID" in
    ubuntu|debian)
      source "${SCRIPT_DIR}/ubuntu/ubuntu.sh"
      ;;
    alpine)
      source "${SCRIPT_DIR}/alpine/alpine.sh"
      ;;
    fedora)
      source "${SCRIPT_DIR}/fedora/fedora.sh"
      ;;
    *)
      echo "Unsupported distro: $DISTRO_ID"
      exit 1
      ;;
  esac
}
