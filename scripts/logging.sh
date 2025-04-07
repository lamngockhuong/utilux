#!/bin/bash

# Color codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log levels
LOG_LEVEL_INFO=0
LOG_LEVEL_WARN=1
LOG_LEVEL_ERROR=2
LOG_LEVEL_DEBUG=3

# Default log level
LOG_LEVEL=${LOG_LEVEL:-$LOG_LEVEL_INFO}

# Logging functions
log_info() {
  if [ $LOG_LEVEL -le $LOG_LEVEL_INFO ]; then
    echo -e "${BLUE}[INFO]${NC} $1"
  fi
}

log_success() {
  if [ $LOG_LEVEL -le $LOG_LEVEL_INFO ]; then
    echo -e "${GREEN}[SUCCESS]${NC} $1"
  fi
}

log_warn() {
  if [ $LOG_LEVEL -le $LOG_LEVEL_WARN ]; then
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
  fi
}

log_error() {
  if [ $LOG_LEVEL -le $LOG_LEVEL_ERROR ]; then
    echo -e "${RED}[ERROR]${NC} $1" >&2
  fi
}

log_debug() {
  if [ $LOG_LEVEL -le $LOG_LEVEL_DEBUG ]; then
    echo -e "${YELLOW}[DEBUG]${NC} $1" >&2
  fi
}

# Set log level from environment variable
if [ -n "$UTILUX_LOG_LEVEL" ]; then
  case "$UTILUX_LOG_LEVEL" in
    "info") LOG_LEVEL=$LOG_LEVEL_INFO ;;
    "warn") LOG_LEVEL=$LOG_LEVEL_WARN ;;
    "error") LOG_LEVEL=$LOG_LEVEL_ERROR ;;
    "debug") LOG_LEVEL=$LOG_LEVEL_DEBUG ;;
    *) log_warn "Invalid log level: $UTILUX_LOG_LEVEL. Using default level." ;;
  esac
fi
