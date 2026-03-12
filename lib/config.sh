#!/bin/bash
# @name: config.sh
# @description: Configuration management
# @version: v1.0.0

# Prevent double sourcing
[[ -n "${_UTILUX_CONFIG_LOADED:-}" ]] && return 0
_UTILUX_CONFIG_LOADED=1

# Default configuration
UTILUX_HOME="${UTILUX_HOME:-$HOME/.utilux}"
UTILUX_CACHE_DIR="${UTILUX_CACHE_DIR:-$UTILUX_HOME/cache}"
UTILUX_CONFIG_FILE="${UTILUX_CONFIG_FILE:-$UTILUX_HOME/config}"
UTILUX_MANIFEST_FILE="${UTILUX_MANIFEST_FILE:-$UTILUX_HOME/manifest.json}"
UTILUX_REGISTRY_URL="${UTILUX_REGISTRY_URL:-https://raw.githubusercontent.com/lamngockhuong/utilux/main/registry/manifest.json}"
UTILUX_OFFLINE="${UTILUX_OFFLINE:-0}"
UTILUX_AUTO_UPDATE="${UTILUX_AUTO_UPDATE:-1}"
UTILUX_DEV_MODE="${UTILUX_DEV_MODE:-0}"

# Initialize utilux directories
config_init() {
  mkdir -p "$UTILUX_HOME" "$UTILUX_CACHE_DIR"

  # Create default config if not exists
  if [[ ! -f "$UTILUX_CONFIG_FILE" ]]; then
    config_save
  fi
}

# Load configuration from file
config_load() {
  if [[ -f "$UTILUX_CONFIG_FILE" ]]; then
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
        UTILUX_REGISTRY_URL|UTILUX_OFFLINE|UTILUX_AUTO_UPDATE|UTILUX_CACHE_DIR)
          local current_val
          eval "current_val=\${$key:-}"
          [[ -z "$current_val" ]] && export "$key=$value"
          ;;
      esac
    done < "$UTILUX_CONFIG_FILE" || true
  fi
}

# Save configuration to file
config_save() {
  cat > "$UTILUX_CONFIG_FILE" << EOF
# Utilux Configuration
# Generated on $(date -Iseconds)

# Registry URL for manifest.json
UTILUX_REGISTRY_URL=$UTILUX_REGISTRY_URL

# Enable offline mode (0=disabled, 1=enabled)
UTILUX_OFFLINE=$UTILUX_OFFLINE

# Auto-update scripts (0=disabled, 1=enabled)
UTILUX_AUTO_UPDATE=$UTILUX_AUTO_UPDATE

# Cache directory
UTILUX_CACHE_DIR=$UTILUX_CACHE_DIR
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
