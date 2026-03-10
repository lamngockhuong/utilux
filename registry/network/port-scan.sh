#!/bin/bash
# @name: port-scan
# @version: v1.0.0
# @description: Scan open ports on a host
# @category: network
# @requires:
# @tags: network, ports, security
# @author: lamngockhuong

set -euo pipefail

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Common service ports
declare -A SERVICES=(
  [21]="FTP"
  [22]="SSH"
  [23]="Telnet"
  [25]="SMTP"
  [53]="DNS"
  [80]="HTTP"
  [110]="POP3"
  [143]="IMAP"
  [443]="HTTPS"
  [465]="SMTPS"
  [587]="SMTP-TLS"
  [993]="IMAPS"
  [995]="POP3S"
  [3306]="MySQL"
  [5432]="PostgreSQL"
  [6379]="Redis"
  [8080]="HTTP-Alt"
  [8443]="HTTPS-Alt"
  [27017]="MongoDB"
)

# Check if port is open using bash /dev/tcp
check_port_bash() {
  local host="$1"
  local port="$2"
  local timeout="${3:-1}"

  (timeout "$timeout" bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null) && return 0
  return 1
}

# Check if port is open using nc
check_port_nc() {
  local host="$1"
  local port="$2"
  local timeout="${3:-1}"

  nc -z -w "$timeout" "$host" "$port" 2>/dev/null
}

# Check single port
check_port() {
  local host="$1"
  local port="$2"
  local timeout="${3:-1}"

  if command -v nc &>/dev/null; then
    check_port_nc "$host" "$port" "$timeout"
  else
    check_port_bash "$host" "$port" "$timeout"
  fi
}

# Scan port range
scan_ports() {
  local host="$1"
  local start_port="${2:-1}"
  local end_port="${3:-1024}"
  local timeout="${4:-1}"

  log_info "Scanning $host ports $start_port-$end_port..."
  echo ""

  local open_ports=()
  local total=$((end_port - start_port + 1))
  local count=0

  for ((port=start_port; port<=end_port; port++)); do
    ((count++))

    # Progress indicator
    if [[ $((count % 100)) -eq 0 ]]; then
      printf "\rProgress: %d/%d (%d%%)" "$count" "$total" "$((count * 100 / total))"
    fi

    if check_port "$host" "$port" "$timeout"; then
      open_ports+=("$port")
    fi
  done

  printf "\r\033[K"  # Clear progress line

  if [[ ${#open_ports[@]} -eq 0 ]]; then
    log_warn "No open ports found"
    return
  fi

  echo "Open ports on $host:"
  echo ""
  printf "  %-8s %-15s %s\n" "PORT" "STATE" "SERVICE"
  printf "  %-8s %-15s %s\n" "----" "-----" "-------"

  for port in "${open_ports[@]}"; do
    local service="${SERVICES[$port]:-unknown}"
    printf "  %-8s ${GREEN}%-15s${NC} %s\n" "$port" "open" "$service"
  done

  echo ""
  log_success "Found ${#open_ports[@]} open ports"
}

# Scan common ports
scan_common() {
  local host="$1"
  local timeout="${2:-1}"

  local common_ports=(21 22 23 25 53 80 110 143 443 465 587 993 995 3306 5432 6379 8080 8443 27017)

  log_info "Scanning common ports on $host..."
  echo ""

  local open_ports=()

  for port in "${common_ports[@]}"; do
    if check_port "$host" "$port" "$timeout"; then
      open_ports+=("$port")
    fi
  done

  if [[ ${#open_ports[@]} -eq 0 ]]; then
    log_warn "No common ports open"
    return
  fi

  echo "Open ports on $host:"
  echo ""
  printf "  %-8s %-15s %s\n" "PORT" "STATE" "SERVICE"
  printf "  %-8s %-15s %s\n" "----" "-----" "-------"

  for port in "${open_ports[@]}"; do
    local service="${SERVICES[$port]:-unknown}"
    printf "  %-8s ${GREEN}%-15s${NC} %s\n" "$port" "open" "$service"
  done

  echo ""
  log_success "Found ${#open_ports[@]} open ports"
}

# Scan specific ports
scan_specific() {
  local host="$1"
  shift
  local ports=("$@")
  local timeout=1

  log_info "Scanning specified ports on $host..."
  echo ""

  local open_ports=()

  for port in "${ports[@]}"; do
    if check_port "$host" "$port" "$timeout"; then
      open_ports+=("$port")
    fi
  done

  if [[ ${#open_ports[@]} -eq 0 ]]; then
    log_warn "No specified ports open"
    return
  fi

  echo "Open ports on $host:"
  echo ""
  printf "  %-8s %-15s %s\n" "PORT" "STATE" "SERVICE"
  printf "  %-8s %-15s %s\n" "----" "-----" "-------"

  for port in "${open_ports[@]}"; do
    local service="${SERVICES[$port]:-unknown}"
    printf "  %-8s ${GREEN}%-15s${NC} %s\n" "$port" "open" "$service"
  done

  echo ""
  log_success "Found ${#open_ports[@]} open ports"
}

# Show listening ports on local machine
show_listening() {
  log_info "Listening ports on this machine:"
  echo ""

  if command -v ss &>/dev/null; then
    ss -tuln | grep LISTEN | awk '{print $5}' | \
      sed 's/.*://' | sort -n | uniq | \
      while read -r port; do
        local service="${SERVICES[$port]:-unknown}"
        printf "  %-8s %s\n" "$port" "$service"
      done
  elif command -v netstat &>/dev/null; then
    netstat -tuln | grep LISTEN | awk '{print $4}' | \
      sed 's/.*://' | sort -n | uniq | \
      while read -r port; do
        local service="${SERVICES[$port]:-unknown}"
        printf "  %-8s %s\n" "$port" "$service"
      done
  else
    log_error "Neither ss nor netstat available"
    return 1
  fi
}

# Show usage
show_usage() {
  cat << EOF
Port Scanner

Usage: $(basename "$0") [OPTIONS] HOST [PORTS]

OPTIONS:
  -r, --range START END   Scan port range (default: 1-1024)
  -c, --common            Scan common ports only
  -p, --ports PORTS       Scan specific ports (comma-separated)
  -l, --listen            Show listening ports on this machine
  -t, --timeout SEC       Connection timeout (default: 1)
  -h, --help              Show this help

EXAMPLES:
  $(basename "$0") localhost             # Scan common ports
  $(basename "$0") -r 1 100 192.168.1.1  # Scan ports 1-100
  $(basename "$0") -p 22,80,443 host.com # Scan specific ports
  $(basename "$0") -l                    # Show local listening ports

NOTES:
  - This is a simple TCP connect scanner
  - For comprehensive scanning, consider using nmap
  - Running without root may have limitations
EOF
}

# Main
main() {
  local host=""
  local mode="common"
  local start_port=1
  local end_port=1024
  local specific_ports=()
  local timeout=1

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -r|--range)
        mode="range"
        start_port="$2"
        end_port="$3"
        shift 3
        ;;
      -c|--common)
        mode="common"
        shift
        ;;
      -p|--ports)
        mode="specific"
        IFS=',' read -ra specific_ports <<< "$2"
        shift 2
        ;;
      -l|--listen)
        mode="listen"
        shift
        ;;
      -t|--timeout)
        timeout="$2"
        shift 2
        ;;
      -h|--help)
        show_usage
        exit 0
        ;;
      -*)
        log_error "Unknown option: $1"
        show_usage
        exit 1
        ;;
      *)
        host="$1"
        shift
        ;;
    esac
  done

  echo "=========================================="
  echo "  Port Scanner"
  echo "=========================================="
  echo ""

  case "$mode" in
    listen)
      show_listening
      ;;
    common)
      if [[ -z "$host" ]]; then
        log_error "Host required"
        show_usage
        exit 1
      fi
      scan_common "$host" "$timeout"
      ;;
    range)
      if [[ -z "$host" ]]; then
        log_error "Host required"
        show_usage
        exit 1
      fi
      scan_ports "$host" "$start_port" "$end_port" "$timeout"
      ;;
    specific)
      if [[ -z "$host" ]]; then
        log_error "Host required"
        show_usage
        exit 1
      fi
      scan_specific "$host" "${specific_ports[@]}"
      ;;
  esac
}

main "$@"
