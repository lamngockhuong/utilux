#!/bin/bash
# @name: protect-port
# @version: v1.0.0
# @description: Add basic auth to any port via nginx reverse proxy
# @category: network
# @requires: nginx
# @tags: nginx, auth, proxy, security
# @author: lamngockhuong
# @draft

set -euo pipefail

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Install dependencies
install_deps() {
  if ! command -v nginx &>/dev/null; then
    log_info "Installing nginx..."
    if command -v apt &>/dev/null; then
      apt update -y && apt install -y nginx
    elif command -v apk &>/dev/null; then
      apk add --no-cache nginx
    elif command -v dnf &>/dev/null; then
      dnf install -y nginx
    else
      log_error "Unsupported package manager"
      exit 1
    fi
  fi

  if ! command -v htpasswd &>/dev/null; then
    log_info "Installing htpasswd..."
    if command -v apt &>/dev/null; then
      apt install -y apache2-utils
    elif command -v apk &>/dev/null; then
      apk add --no-cache apache2-utils
    elif command -v dnf &>/dev/null; then
      dnf install -y httpd-tools
    fi
  fi
}

# Ask for credentials
ask_credentials() {
  local username_var="$1"
  local password_var="$2"

  if [[ -z "${!username_var:-}" ]]; then
    read -rp "Username: " "$username_var"
  fi

  if [[ -z "${!password_var:-}" ]]; then
    read -rs -p "Password: " "$password_var"
    echo
    local confirm
    read -rs -p "Confirm Password: " confirm
    echo
    if [[ "${!password_var}" != "$confirm" ]]; then
      log_error "Passwords do not match"
      exit 1
    fi
  fi
}

# Protect port
do_protect() {
  local port="$1"
  local internal_port="$2"
  local username="${3:-}"
  local password="${4:-}"

  local conf_name="protected_${port}"
  local htpasswd_file="/etc/nginx/.htpasswd_${port}"
  local nginx_conf="/etc/nginx/sites-available/${conf_name}"
  local nginx_enabled="/etc/nginx/sites-enabled/${conf_name}"

  install_deps
  ask_credentials username password

  log_info "Creating htpasswd file..."
  htpasswd -cb "$htpasswd_file" "$username" "$password"

  log_info "Creating nginx config..."
  cat >"$nginx_conf" <<EOF
server {
    listen $port;

    location / {
        proxy_pass http://127.0.0.1:$internal_port;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

        auth_basic "Restricted Access";
        auth_basic_user_file $htpasswd_file;
    }
}
EOF

  # Ensure sites-enabled exists
  mkdir -p /etc/nginx/sites-enabled

  ln -sf "$nginx_conf" "$nginx_enabled"

  log_info "Testing nginx config..."
  nginx -t

  log_info "Reloading nginx..."
  systemctl reload nginx || nginx -s reload

  local server_ip
  server_ip=$(hostname -I | awk '{print $1}')

  echo ""
  log_success "Protected at http://${server_ip}:${port}"
  echo -e "  ${CYAN}Service:${NC}   127.0.0.1:${internal_port}"
  echo -e "  ${CYAN}Public:${NC}    ${server_ip}:${port} (with basic auth)"
}

# Update credentials
do_update() {
  local port="$1"
  local username="${2:-}"
  local password="${3:-}"

  local htpasswd_file="/etc/nginx/.htpasswd_${port}"

  if [[ ! -f "$htpasswd_file" ]]; then
    log_error "No existing protection found on port $port"
    exit 1
  fi

  ask_credentials username password

  log_info "Updating htpasswd..."
  htpasswd -cb "$htpasswd_file" "$username" "$password"

  log_info "Testing nginx config..."
  nginx -t

  log_info "Reloading nginx..."
  systemctl reload nginx || nginx -s reload

  log_success "Credentials updated for port $port"
}

# Remove protection
do_remove() {
  local port="$1"

  local conf_name="protected_${port}"
  local htpasswd_file="/etc/nginx/.htpasswd_${port}"
  local nginx_conf="/etc/nginx/sites-available/${conf_name}"
  local nginx_enabled="/etc/nginx/sites-enabled/${conf_name}"

  local removed=0

  if [[ -f "$nginx_enabled" ]]; then
    rm -f "$nginx_enabled"
    ((removed++))
  fi

  if [[ -f "$nginx_conf" ]]; then
    rm -f "$nginx_conf"
    ((removed++))
  fi

  if [[ -f "$htpasswd_file" ]]; then
    rm -f "$htpasswd_file"
    ((removed++))
  fi

  if [[ $removed -eq 0 ]]; then
    log_warn "No protection found for port $port"
    return 0
  fi

  log_info "Testing nginx config..."
  nginx -t

  log_info "Reloading nginx..."
  systemctl reload nginx || nginx -s reload

  log_success "Protection removed for port $port"
}

# List protected ports
do_list() {
  echo "Protected Ports:"
  echo "================"
  echo ""

  local found=0
  for conf in /etc/nginx/sites-available/protected_*; do
    [[ ! -f "$conf" ]] && continue
    ((found++))

    local port
    port=$(basename "$conf" | sed 's/protected_//')
    local internal_port
    internal_port=$(grep -oP 'proxy_pass http://127\.0\.0\.1:\K[0-9]+' "$conf" 2>/dev/null || echo "?")

    local enabled=""
    if [[ -L "/etc/nginx/sites-enabled/$(basename "$conf")" ]]; then
      enabled="${GREEN}[enabled]${NC}"
    else
      enabled="${YELLOW}[disabled]${NC}"
    fi

    echo -e "  Port ${CYAN}$port${NC} -> 127.0.0.1:$internal_port $enabled"
  done

  if [[ $found -eq 0 ]]; then
    echo "  No protected ports found"
  fi
}

# Show usage
show_usage() {
  cat <<EOF
Port Protection with Basic Auth

Usage: $(basename "$0") <ACTION> [OPTIONS]

ACTIONS:
  protect <PORT> <INTERNAL_PORT> [USER] [PASS]
      Create nginx proxy with basic auth

  update <PORT> [USER] [PASS]
      Update credentials for existing protection

  remove <PORT>
      Remove protection from port

  list
      List all protected ports

EXAMPLES:
  $(basename "$0") protect 5541 5540
      Protect port 5541, proxy to localhost:5540

  $(basename "$0") protect 8080 3000 admin secretpass
      Protect with specified credentials

  $(basename "$0") update 5541 admin newpass
      Update credentials

  $(basename "$0") remove 5541
      Remove protection

  $(basename "$0") list
      Show all protected ports

SCENARIO:
  Docker service at 0.0.0.0:5540 -> Change to 127.0.0.1:5540
  Then: $(basename "$0") protect 5541 5540
  Access via: http://SERVER:5541 (with basic auth)
EOF
}

# Main
main() {
  if [[ $# -lt 1 ]]; then
    show_usage
    exit 1
  fi

  local action="$1"
  shift

  echo "=========================================="
  echo "  Port Protection"
  echo "=========================================="
  echo ""

  case "$action" in
    protect)
      if [[ $# -lt 2 ]]; then
        log_error "Usage: protect <PORT> <INTERNAL_PORT> [USER] [PASS]"
        exit 1
      fi
      do_protect "$@"
      ;;
    update)
      if [[ $# -lt 1 ]]; then
        log_error "Usage: update <PORT> [USER] [PASS]"
        exit 1
      fi
      do_update "$@"
      ;;
    remove)
      if [[ $# -lt 1 ]]; then
        log_error "Usage: remove <PORT>"
        exit 1
      fi
      do_remove "$1"
      ;;
    list)
      do_list
      ;;
    -h | --help | help)
      show_usage
      ;;
    *)
      log_error "Unknown action: $action"
      show_usage
      exit 1
      ;;
  esac
}

main "$@"
