#!/bin/bash
# @name: core.sh
# @description: Core utilities - logging, helpers, error handling
# @version: v1.0.0

# Prevent double sourcing
[[ -n "${_UTILUX_CORE_LOADED:-}" ]] && return 0
_UTILUX_CORE_LOADED=1

# Color codes
readonly UTILUX_RED='\033[0;31m'
readonly UTILUX_GREEN='\033[0;32m'
readonly UTILUX_YELLOW='\033[0;33m'
readonly UTILUX_BLUE='\033[0;34m'
readonly UTILUX_CYAN='\033[0;36m'
readonly UTILUX_NC='\033[0m'

# Log levels (lower = more verbose)
readonly UTILUX_LOG_DEBUG=0
readonly UTILUX_LOG_INFO=1
readonly UTILUX_LOG_WARN=2
readonly UTILUX_LOG_ERROR=3

# Current log level (default: INFO)
UTILUX_CURRENT_LOG_LEVEL=${UTILUX_LOG_LEVEL:-$UTILUX_LOG_INFO}

# Set log level from env
case "${UTILUX_LOG_LEVEL:-info}" in
  debug) UTILUX_CURRENT_LOG_LEVEL=$UTILUX_LOG_DEBUG ;;
  info)  UTILUX_CURRENT_LOG_LEVEL=$UTILUX_LOG_INFO ;;
  warn)  UTILUX_CURRENT_LOG_LEVEL=$UTILUX_LOG_WARN ;;
  error) UTILUX_CURRENT_LOG_LEVEL=$UTILUX_LOG_ERROR ;;
esac

# Logging functions
log_debug() {
  if [[ $UTILUX_CURRENT_LOG_LEVEL -le $UTILUX_LOG_DEBUG ]]; then
    echo -e "${UTILUX_CYAN}[DEBUG]${UTILUX_NC} $*" >&2
  fi
}

log_info() {
  if [[ $UTILUX_CURRENT_LOG_LEVEL -le $UTILUX_LOG_INFO ]]; then
    echo -e "${UTILUX_BLUE}[INFO]${UTILUX_NC} $*"
  fi
}

log_success() {
  if [[ $UTILUX_CURRENT_LOG_LEVEL -le $UTILUX_LOG_INFO ]]; then
    echo -e "${UTILUX_GREEN}[OK]${UTILUX_NC} $*"
  fi
}

log_warn() {
  if [[ $UTILUX_CURRENT_LOG_LEVEL -le $UTILUX_LOG_WARN ]]; then
    echo -e "${UTILUX_YELLOW}[WARN]${UTILUX_NC} $*" >&2
  fi
}

log_error() {
  if [[ $UTILUX_CURRENT_LOG_LEVEL -le $UTILUX_LOG_ERROR ]]; then
    echo -e "${UTILUX_RED}[ERROR]${UTILUX_NC} $*" >&2
  fi
}

# Exit with error
die() {
  log_error "$*"
  exit 1
}

# Check if command exists
require_cmd() {
  local cmd="$1"
  local msg="${2:-Required command '$cmd' not found}"
  command -v "$cmd" &>/dev/null || die "$msg"
}

# Check if running as root
require_root() {
  [[ $EUID -eq 0 ]] || die "This operation requires root privileges"
}

# Check optional command (returns 0/1, no exit)
has_cmd() {
  command -v "$1" &>/dev/null
}

# Sanitize string (alphanumeric, dash, underscore only)
sanitize_name() {
  local name="$1"
  echo "${name//[^a-zA-Z0-9_-]/}"
}

# Validate URL
is_valid_url() {
  local url="$1"
  [[ "$url" =~ ^https?:// ]]
}

# Get utilux version
utilux_version() {
  echo "1.0.0"
}
