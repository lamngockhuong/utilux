#!/bin/bash
# @name: system-info
# @version: v1.0.0
# @description: Display comprehensive system information
# @category: system
# @requires:
# @tags: system, info, hardware
# @author: lamngockhuong
# @draft

set -euo pipefail

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

section() { echo -e "\n${CYAN}=== $1 ===${NC}"; }
item() { printf "  %-16s: %s\n" "$1" "$2"; }

# OS Information
show_os() {
  section "Operating System"

  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    item "OS" "${PRETTY_NAME:-$NAME $VERSION}"
    item "ID" "$ID"
  fi

  item "Kernel" "$(uname -r)"
  item "Arch" "$(uname -m)"
  item "Hostname" "$(hostname)"
  item "Uptime" "$(uptime -p 2>/dev/null || uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')"
}

# CPU Information
show_cpu() {
  section "CPU"

  if [[ -f /proc/cpuinfo ]]; then
    local model cores freq
    model=$(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | xargs)
    cores=$(grep -c "^processor" /proc/cpuinfo)
    freq=$(grep -m1 "cpu MHz" /proc/cpuinfo | cut -d: -f2 | xargs)

    item "Model" "${model:-Unknown}"
    item "Cores" "$cores"
    [[ -n "$freq" ]] && item "Frequency" "${freq} MHz"
  fi

  # CPU usage
  if command -v top &>/dev/null; then
    local usage
    usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d. -f1 2>/dev/null || echo "N/A")
    item "Usage" "${usage}%"
  fi

  # Load average
  if [[ -f /proc/loadavg ]]; then
    item "Load Avg" "$(cut -d' ' -f1-3 /proc/loadavg)"
  fi
}

# Memory Information
show_memory() {
  section "Memory"

  if command -v free &>/dev/null; then
    local total used free available
    read -r total used free _ _ available <<<"$(free -m | awk '/^Mem:/ {print $2, $3, $4, $6, $7}')"

    item "Total" "${total} MB"
    item "Used" "${used} MB"
    item "Free" "${free} MB"
    item "Available" "${available:-N/A} MB"

    # Calculate percentage
    local pct=$((used * 100 / total))
    item "Usage" "${pct}%"
  fi

  # Swap
  local swap_total swap_used
  read -r swap_total swap_used <<<"$(free -m | awk '/^Swap:/ {print $2, $3}')"
  if [[ "$swap_total" -gt 0 ]]; then
    item "Swap Total" "${swap_total} MB"
    item "Swap Used" "${swap_used} MB"
  fi
}

# Disk Information
show_disk() {
  section "Disk"

  df -h --output=source,size,used,avail,pcent,target 2>/dev/null \
    | grep -E "^/dev/" \
    | while read -r source size used avail pcent target; do
      printf "  %-15s %6s / %6s (%s) → %s\n" "$source" "$used" "$size" "$pcent" "$target"
    done
}

# Network Information
show_network() {
  section "Network"

  # Hostname and IPs
  item "Hostname" "$(hostname -f 2>/dev/null || hostname)"

  # Get local IPs
  if command -v ip &>/dev/null; then
    local ips
    ips=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v "127.0.0.1" | head -3 | tr '\n' ', ' | sed 's/,$//')
    item "Local IPs" "${ips:-None}"
  fi

  # Get public IP (optional)
  if command -v curl &>/dev/null; then
    local public_ip
    public_ip=$(curl -s --connect-timeout 2 ifconfig.me 2>/dev/null || echo "N/A")
    item "Public IP" "$public_ip"
  fi

  # DNS servers
  if [[ -f /etc/resolv.conf ]]; then
    local dns
    dns=$(grep "^nameserver" /etc/resolv.conf | head -2 | awk '{print $2}' | tr '\n' ', ' | sed 's/,$//')
    item "DNS" "${dns:-N/A}"
  fi
}

# User Information
show_users() {
  section "Users"

  item "Current User" "$(whoami)"
  item "Home" "$HOME"
  item "Shell" "$SHELL"

  local logged_in
  logged_in=$(who | wc -l)
  item "Logged In" "$logged_in users"
}

# Process Information
show_processes() {
  section "Processes"

  local total running sleeping
  total=$(ps aux | wc -l)
  running=$(ps aux | awk '$8 ~ /R/ {count++} END {print count+0}')
  sleeping=$(ps aux | awk '$8 ~ /S/ {count++} END {print count+0}')

  item "Total" "$total"
  item "Running" "$running"
  item "Sleeping" "$sleeping"

  echo ""
  echo "  Top 5 by CPU:"
  ps aux --sort=-%cpu | head -6 | tail -5 | awk '{printf "    %-8s %5s%% %s\n", $1, $3, $11}'
}

# Services (systemd)
show_services() {
  if ! command -v systemctl &>/dev/null; then
    return
  fi

  section "Services (systemd)"

  local running failed
  running=$(systemctl list-units --type=service --state=running --no-pager --no-legend 2>/dev/null | wc -l)
  failed=$(systemctl list-units --type=service --state=failed --no-pager --no-legend 2>/dev/null | wc -l)

  item "Running" "$running"
  item "Failed" "$failed"

  if [[ "$failed" -gt 0 ]]; then
    echo ""
    echo -e "  ${YELLOW}Failed services:${NC}"
    systemctl list-units --type=service --state=failed --no-pager --no-legend 2>/dev/null \
      | awk '{print "    - " $1}' | head -5
  fi
}

# Main
main() {
  echo -e "${GREEN}System Information Report${NC}"
  echo "Generated: $(date)"

  local section="${1:-all}"

  case "$section" in
    os) show_os ;;
    cpu) show_cpu ;;
    memory) show_memory ;;
    disk) show_disk ;;
    network) show_network ;;
    users) show_users ;;
    process) show_processes ;;
    services) show_services ;;
    all | *)
      show_os
      show_cpu
      show_memory
      show_disk
      show_network
      show_users
      show_processes
      show_services
      ;;
  esac

  echo ""
}

main "$@"
