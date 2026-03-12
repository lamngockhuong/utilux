#!/bin/bash
# @name: core.sh
# @description: Core utilities - logging, helpers, error handling
# @version: v1.0.0

# Prevent double sourcing
[[ -n "${_UTIX_CORE_LOADED:-}" ]] && return 0
_UTIX_CORE_LOADED=1

# Color codes
readonly UTIX_RED='\033[0;31m'
readonly UTIX_GREEN='\033[0;32m'
readonly UTIX_YELLOW='\033[0;33m'
readonly UTIX_BLUE='\033[0;34m'
readonly UTIX_CYAN='\033[0;36m'
readonly UTIX_NC='\033[0m'

# Log levels (lower = more verbose)
readonly UTIX_LOG_DEBUG=0
readonly UTIX_LOG_INFO=1
readonly UTIX_LOG_WARN=2
readonly UTIX_LOG_ERROR=3

# Current log level (default: INFO)
UTIX_CURRENT_LOG_LEVEL=${UTIX_LOG_LEVEL:-$UTIX_LOG_INFO}

# Set log level from env
case "${UTIX_LOG_LEVEL:-info}" in
  debug) UTIX_CURRENT_LOG_LEVEL=$UTIX_LOG_DEBUG ;;
  info) UTIX_CURRENT_LOG_LEVEL=$UTIX_LOG_INFO ;;
  warn) UTIX_CURRENT_LOG_LEVEL=$UTIX_LOG_WARN ;;
  error) UTIX_CURRENT_LOG_LEVEL=$UTIX_LOG_ERROR ;;
esac

# Logging functions
log_debug() {
  if [[ $UTIX_CURRENT_LOG_LEVEL -le $UTIX_LOG_DEBUG ]]; then
    echo -e "${UTIX_CYAN}[DEBUG]${UTIX_NC} $*" >&2
  fi
}

log_info() {
  if [[ $UTIX_CURRENT_LOG_LEVEL -le $UTIX_LOG_INFO ]]; then
    echo -e "${UTIX_BLUE}[INFO]${UTIX_NC} $*" >&2
  fi
}

log_success() {
  if [[ $UTIX_CURRENT_LOG_LEVEL -le $UTIX_LOG_INFO ]]; then
    echo -e "${UTIX_GREEN}[OK]${UTIX_NC} $*" >&2
  fi
}

log_warn() {
  if [[ $UTIX_CURRENT_LOG_LEVEL -le $UTIX_LOG_WARN ]]; then
    echo -e "${UTIX_YELLOW}[WARN]${UTIX_NC} $*" >&2
  fi
}

log_error() {
  if [[ $UTIX_CURRENT_LOG_LEVEL -le $UTIX_LOG_ERROR ]]; then
    echo -e "${UTIX_RED}[ERROR]${UTIX_NC} $*" >&2
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

# Get utix version
utix_version() {
  echo "1.0.0"
}
