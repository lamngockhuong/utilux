#!/bin/bash
# @name: ssl-check
# @version: v1.0.0
# @description: Check SSL certificate expiry and details
# @category: network
# @requires: openssl
# @tags: ssl, certificate, security
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

# Check if openssl is available
check_openssl() {
  if ! command -v openssl &>/dev/null; then
    log_error "OpenSSL is not installed"
    exit 1
  fi
}

# Get certificate from host
get_certificate() {
  local host="$1"
  local port="${2:-443}"
  local timeout="${3:-5}"

  echo | timeout "$timeout" openssl s_client -servername "$host" -connect "$host:$port" 2>/dev/null
}

# Parse certificate dates
parse_dates() {
  local cert="$1"

  local not_before not_after
  not_before=$(echo "$cert" | openssl x509 -noout -startdate 2>/dev/null | cut -d= -f2)
  not_after=$(echo "$cert" | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)

  echo "$not_before|$not_after"
}

# Calculate days until expiry
days_until_expiry() {
  local expiry_date="$1"
  local expiry_epoch
  local now_epoch
  local days

  expiry_epoch=$(date -d "$expiry_date" +%s 2>/dev/null || date -j -f "%b %d %T %Y %Z" "$expiry_date" +%s 2>/dev/null)
  now_epoch=$(date +%s)
  days=$(((expiry_epoch - now_epoch) / 86400))

  echo "$days"
}

# Check single host
check_host() {
  local host="$1"
  local port="${2:-443}"
  local warn_days="${3:-30}"

  # Remove protocol if present
  host="${host#https://}"
  host="${host#http://}"
  host="${host%%/*}"

  log_info "Checking SSL certificate for $host:$port"
  echo ""

  # Get certificate
  local cert_output
  cert_output=$(get_certificate "$host" "$port")

  if [[ -z "$cert_output" ]]; then
    log_error "Could not connect to $host:$port"
    return 1
  fi

  # Extract certificate
  local cert
  cert=$(echo "$cert_output" | openssl x509 2>/dev/null)

  if [[ -z "$cert" ]]; then
    log_error "Could not parse certificate"
    return 1
  fi

  # Get certificate details
  local subject issuer dates not_before not_after days san

  subject=$(echo "$cert" | openssl x509 -noout -subject 2>/dev/null | sed 's/subject=//')
  issuer=$(echo "$cert" | openssl x509 -noout -issuer 2>/dev/null | sed 's/issuer=//')

  dates=$(echo "$cert" | openssl x509 -noout -dates 2>/dev/null)
  not_before=$(echo "$dates" | grep notBefore | cut -d= -f2)
  not_after=$(echo "$dates" | grep notAfter | cut -d= -f2)

  days=$(days_until_expiry "$not_after")

  san=$(echo "$cert" | openssl x509 -noout -ext subjectAltName 2>/dev/null | grep -v "X509v3" | tr ',' '\n' | sed 's/^[[:space:]]*//' || echo "N/A")

  # Display results
  echo "Certificate Details:"
  echo "===================="
  echo ""
  echo -e "  ${CYAN}Host:${NC}       $host:$port"
  echo -e "  ${CYAN}Subject:${NC}    $subject"
  echo -e "  ${CYAN}Issuer:${NC}     $issuer"
  echo -e "  ${CYAN}Not Before:${NC} $not_before"
  echo -e "  ${CYAN}Not After:${NC}  $not_after"
  echo ""

  # Expiry status
  if [[ $days -lt 0 ]]; then
    echo -e "  ${RED}Status:${NC}     EXPIRED ($((days * -1)) days ago)"
  elif [[ $days -lt $warn_days ]]; then
    echo -e "  ${YELLOW}Status:${NC}     EXPIRING SOON ($days days remaining)"
  else
    echo -e "  ${GREEN}Status:${NC}     Valid ($days days remaining)"
  fi

  echo ""

  # Subject Alternative Names
  if [[ -n "$san" && "$san" != "N/A" ]]; then
    echo "  Subject Alt Names:"
    echo "$san" | while read -r line; do
      [[ -n "$line" ]] && echo "    - $line"
    done
    echo ""
  fi

  # Return status
  if [[ $days -lt 0 ]]; then
    return 2 # Expired
  elif [[ $days -lt $warn_days ]]; then
    return 1 # Expiring soon
  else
    return 0 # OK
  fi
}

# Check multiple hosts from file
check_hosts_file() {
  local file="$1"
  local warn_days="${2:-30}"

  if [[ ! -f "$file" ]]; then
    log_error "File not found: $file"
    return 1
  fi

  echo "SSL Certificate Report"
  echo "======================"
  echo ""
  printf "  %-30s %-10s %-15s\n" "HOST" "PORT" "DAYS LEFT"
  printf "  %-30s %-10s %-15s\n" "----" "----" "---------"

  local total=0
  local expired=0
  local warning=0
  local ok=0

  while IFS= read -r line; do
    # Skip comments and empty lines
    [[ -z "$line" || "$line" =~ ^# ]] && continue

    # Parse host:port
    local host port
    if [[ "$line" =~ : ]]; then
      host="${line%%:*}"
      port="${line##*:}"
    else
      host="$line"
      port="443"
    fi

    ((total++))

    # Get certificate
    local cert_output cert not_after days status_color

    cert_output=$(get_certificate "$host" "$port" 2>/dev/null || echo "")

    if [[ -z "$cert_output" ]]; then
      printf "  %-30s %-10s ${RED}%-15s${NC}\n" "$host" "$port" "CONNECT FAIL"
      continue
    fi

    cert=$(echo "$cert_output" | openssl x509 2>/dev/null || echo "")

    if [[ -z "$cert" ]]; then
      printf "  %-30s %-10s ${RED}%-15s${NC}\n" "$host" "$port" "PARSE FAIL"
      continue
    fi

    not_after=$(echo "$cert" | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
    days=$(days_until_expiry "$not_after")

    if [[ $days -lt 0 ]]; then
      status_color="$RED"
      ((expired++))
    elif [[ $days -lt $warn_days ]]; then
      status_color="$YELLOW"
      ((warning++))
    else
      status_color="$GREEN"
      ((ok++))
    fi

    printf "  %-30s %-10s ${status_color}%-15s${NC}\n" "$host" "$port" "$days days"

  done <"$file"

  echo ""
  echo "Summary:"
  echo "  Total:    $total"
  echo -e "  ${GREEN}OK:${NC}       $ok"
  echo -e "  ${YELLOW}Warning:${NC}  $warning"
  echo -e "  ${RED}Expired:${NC}  $expired"
}

# Show chain
show_chain() {
  local host="$1"
  local port="${2:-443}"

  host="${host#https://}"
  host="${host#http://}"
  host="${host%%/*}"

  log_info "Certificate chain for $host:$port"
  echo ""

  echo | openssl s_client -servername "$host" -connect "$host:$port" -showcerts 2>/dev/null \
    | awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/ { print }' \
    | while IFS= read -r line; do
      if [[ "$line" == "-----BEGIN CERTIFICATE-----" ]]; then
        echo "---"
        cert=""
      fi
      cert+="$line"$'\n'
      if [[ "$line" == "-----END CERTIFICATE-----" ]]; then
        echo "$cert" | openssl x509 -noout -subject -issuer 2>/dev/null
        echo ""
      fi
    done
}

# Show usage
show_usage() {
  cat <<EOF
SSL Certificate Checker

Usage: $(basename "$0") [OPTIONS] HOST[:PORT]

OPTIONS:
  -p, --port PORT        Port number (default: 443)
  -w, --warn DAYS        Warning threshold in days (default: 30)
  -f, --file FILE        Check hosts from file (one per line)
  -c, --chain            Show certificate chain
  -h, --help             Show this help

EXAMPLES:
  $(basename "$0") example.com              # Check example.com:443
  $(basename "$0") example.com:8443         # Check custom port
  $(basename "$0") -w 60 example.com        # Warn if < 60 days
  $(basename "$0") -f hosts.txt             # Check multiple hosts
  $(basename "$0") -c example.com           # Show cert chain

FILE FORMAT (hosts.txt):
  example.com
  example.org:8443
  # Comments are ignored
EOF
}

# Main
main() {
  check_openssl

  local host=""
  local port="443"
  local warn_days=30
  local mode="single"
  local file=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -p | --port)
        port="$2"
        shift 2
        ;;
      -w | --warn)
        warn_days="$2"
        shift 2
        ;;
      -f | --file)
        mode="file"
        file="$2"
        shift 2
        ;;
      -c | --chain)
        mode="chain"
        shift
        ;;
      -h | --help)
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
        # Check for host:port format
        if [[ "$host" =~ : ]]; then
          port="${host##*:}"
          host="${host%%:*}"
        fi
        shift
        ;;
    esac
  done

  echo "=========================================="
  echo "  SSL Certificate Checker"
  echo "=========================================="
  echo ""

  case "$mode" in
    single)
      if [[ -z "$host" ]]; then
        log_error "Host required"
        show_usage
        exit 1
      fi
      check_host "$host" "$port" "$warn_days"
      ;;
    file)
      check_hosts_file "$file" "$warn_days"
      ;;
    chain)
      if [[ -z "$host" ]]; then
        log_error "Host required"
        show_usage
        exit 1
      fi
      show_chain "$host" "$port"
      ;;
  esac
}

main "$@"
