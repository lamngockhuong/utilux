#!/bin/bash
# @name: config.sh
# @description: Configuration management
# @version: v1.0.0

# Prevent double sourcing
[[ -n "${_UTIX_CONFIG_LOADED:-}" ]] && return 0
_UTIX_CONFIG_LOADED=1

# Default configuration
UTIX_HOME="${UTIX_HOME:-$HOME/.utix}"
UTIX_CACHE_DIR="${UTIX_CACHE_DIR:-$UTIX_HOME/cache}"
UTIX_CONFIG_FILE="${UTIX_CONFIG_FILE:-$UTIX_HOME/config}"
UTIX_MANIFEST_FILE="${UTIX_MANIFEST_FILE:-$UTIX_HOME/manifest.json}"
UTIX_REGISTRY_URL="${UTIX_REGISTRY_URL:-https://raw.githubusercontent.com/lamngockhuong/utix/main/registry/manifest.json}"
UTIX_OFFLINE="${UTIX_OFFLINE:-0}"
UTIX_AUTO_UPDATE="${UTIX_AUTO_UPDATE:-1}"
UTIX_DEV_MODE="${UTIX_DEV_MODE:-0}"

# Initialize utix directories
config_init() {
  mkdir -p "$UTIX_HOME" "$UTIX_CACHE_DIR"

  # Create default config if not exists
  if [[ ! -f "$UTIX_CONFIG_FILE" ]]; then
    config_save
  fi
}

# Load configuration from file
config_load() {
  if [[ -f "$UTIX_CONFIG_FILE" ]]; then
    local key value
    # Source config file (simple key=value format)
    while IFS='=' read -r key value || [[ -n "$key" ]]; do
      # Skip comments and empty lines
      [[ -z "$key" || "$key" =~ ^# ]] && continue
      # Trim whitespace
      key="${key// /}"
      value="${value// /}"
      # Only set if not already set via environment (env vars take precedence)
      case "$key" in
        UTIX_REGISTRY_URL|UTIX_OFFLINE|UTIX_AUTO_UPDATE|UTIX_CACHE_DIR)
          local current_val
          eval "current_val=\${$key:-}"
          [[ -z "$current_val" ]] && export "$key=$value"
          ;;
      esac
    done < "$UTIX_CONFIG_FILE" || true
  fi
}

# Save configuration to file
config_save() {
  cat > "$UTIX_CONFIG_FILE" << EOF
# Utix Configuration
# Generated on $(date -Iseconds)

# Registry URL for manifest.json
UTIX_REGISTRY_URL=$UTIX_REGISTRY_URL

# Enable offline mode (0=disabled, 1=enabled)
UTIX_OFFLINE=$UTIX_OFFLINE

# Auto-update scripts (0=disabled, 1=enabled)
UTIX_AUTO_UPDATE=$UTIX_AUTO_UPDATE

# Cache directory
UTIX_CACHE_DIR=$UTIX_CACHE_DIR
EOF
}

# Get config value
config_get() {
  local key="$1"
  local default="$2"
  local value

  # Check env var first
  value="${!key:-}"

  # Return value or default
  echo "${value:-$default}"
}

# Set config value
config_set() {
  local key="$1"
  local value="$2"

  # Update env var
  export "$key=$value"

  # Save to file
  config_save
}
