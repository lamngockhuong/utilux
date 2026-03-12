#!/bin/bash
# @name: cron-helper
# @version: v1.0.0
# @description: Interactively manage cron jobs
# @category: automation
# @requires:
# @tags: cron, schedule, automation
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

# List current cron jobs
list_cron() {
  echo "Current cron jobs for $(whoami):"
  echo ""

  local crontab
  crontab=$(crontab -l 2>/dev/null || echo "")

  if [[ -z "$crontab" ]]; then
    log_warn "No cron jobs found"
    return
  fi

  local i=1
  while IFS= read -r line; do
    # Skip comments and empty lines for numbering
    if [[ -z "$line" || "$line" =~ ^# ]]; then
      echo -e "  ${CYAN}$line${NC}"
    else
      printf "  %2d. %s\n" "$i" "$line"
      ((i++))
    fi
  done <<<"$crontab"
}

# Add a new cron job
add_cron() {
  local schedule="${1:-}"
  local command="${2:-}"

  if [[ -z "$schedule" || -z "$command" ]]; then
    echo "Add a new cron job"
    echo ""
    echo "Common schedules:"
    echo "  @hourly    - Run once every hour"
    echo "  @daily     - Run once every day at midnight"
    echo "  @weekly    - Run once every week"
    echo "  @monthly   - Run once every month"
    echo "  @reboot    - Run at startup"
    echo ""
    echo "Or use cron syntax: MIN HOUR DOM MON DOW"
    echo "  0 * * * *    - Every hour"
    echo "  0 0 * * *    - Every day at midnight"
    echo "  0 0 * * 0    - Every Sunday"
    echo "  */5 * * * *  - Every 5 minutes"
    echo ""

    read -r -p "Schedule: " schedule
    read -r -p "Command: " command
  fi

  if [[ -z "$schedule" || -z "$command" ]]; then
    log_error "Schedule and command are required"
    return 1
  fi

  # Validate schedule format
  if ! validate_schedule "$schedule"; then
    log_error "Invalid schedule format"
    return 1
  fi

  local entry="$schedule $command"

  log_info "Adding cron job: $entry"

  # Add to crontab
  (
    crontab -l 2>/dev/null
    echo "$entry"
  ) | crontab -

  log_success "Cron job added"
}

# Validate cron schedule
validate_schedule() {
  local schedule="$1"

  # Check for special schedules
  if [[ "$schedule" =~ ^@(hourly|daily|weekly|monthly|yearly|annually|reboot)$ ]]; then
    return 0
  fi

  # Check for standard cron format (5 fields)
  local fields
  fields=$(echo "$schedule" | wc -w)
  if [[ $fields -eq 5 ]]; then
    return 0
  fi

  return 1
}

# Remove a cron job
remove_cron() {
  local number="${1:-}"

  if [[ -z "$number" ]]; then
    list_cron
    echo ""
    read -r -p "Enter job number to remove: " number
  fi

  if [[ -z "$number" || ! "$number" =~ ^[0-9]+$ ]]; then
    log_error "Invalid job number"
    return 1
  fi

  local crontab
  crontab=$(crontab -l 2>/dev/null || echo "")

  if [[ -z "$crontab" ]]; then
    log_error "No cron jobs found"
    return 1
  fi

  # Get non-comment lines
  local jobs
  jobs=$(echo "$crontab" | grep -v '^#' | grep -v '^$')
  local total
  total=$(echo "$jobs" | wc -l)

  if [[ $number -lt 1 || $number -gt $total ]]; then
    log_error "Invalid job number (1-$total)"
    return 1
  fi

  # Get the job to remove
  local job_to_remove
  job_to_remove=$(echo "$jobs" | sed -n "${number}p")

  log_info "Removing: $job_to_remove"

  # Remove the job
  echo "$crontab" | grep -vF "$job_to_remove" | crontab -

  log_success "Cron job removed"
}

# Edit crontab directly
edit_cron() {
  log_info "Opening crontab in editor..."
  crontab -e
}

# Clear all cron jobs
clear_cron() {
  log_warn "This will remove ALL cron jobs for $(whoami)"
  read -r -p "Are you sure? [y/N] " confirm

  if [[ ! "$confirm" =~ ^[Yy] ]]; then
    log_warn "Cancelled"
    return
  fi

  crontab -r 2>/dev/null || true
  log_success "All cron jobs removed"
}

# Export cron jobs to file
export_cron() {
  local output="${1:-crontab_backup_$(date +%Y%m%d).txt}"

  crontab -l >"$output" 2>/dev/null

  log_success "Cron jobs exported to: $output"
}

# Import cron jobs from file
import_cron() {
  local input="${1:-}"

  if [[ -z "$input" ]]; then
    read -r -p "Input file: " input
  fi

  if [[ ! -f "$input" ]]; then
    log_error "File not found: $input"
    return 1
  fi

  log_warn "This will replace ALL current cron jobs"
  read -r -p "Continue? [y/N] " confirm

  if [[ ! "$confirm" =~ ^[Yy] ]]; then
    log_warn "Cancelled"
    return
  fi

  crontab "$input"
  log_success "Cron jobs imported from: $input"
}

# Show cron examples
show_examples() {
  cat <<'EOF'
Cron Schedule Examples:

Format: MIN HOUR DOM MON DOW command
  MIN  - Minute (0-59)
  HOUR - Hour (0-23)
  DOM  - Day of Month (1-31)
  MON  - Month (1-12)
  DOW  - Day of Week (0-7, 0 and 7 are Sunday)

Special characters:
  *    - Any value
  ,    - Value list (1,3,5)
  -    - Range (1-5)
  /    - Step values (*/5 = every 5)

Examples:
  0 * * * *        Every hour
  */15 * * * *     Every 15 minutes
  0 0 * * *        Daily at midnight
  0 6 * * *        Daily at 6:00 AM
  0 0 * * 0        Weekly on Sunday
  0 0 1 * *        Monthly on the 1st
  0 0 1 1 *        Yearly on Jan 1st
  0 0 * * 1-5      Weekdays at midnight
  0 9-17 * * *     Every hour 9 AM to 5 PM

Special schedules:
  @reboot          Run once at startup
  @hourly          Same as 0 * * * *
  @daily           Same as 0 0 * * *
  @weekly          Same as 0 0 * * 0
  @monthly         Same as 0 0 1 * *
  @yearly          Same as 0 0 1 1 *
EOF
}

# Interactive menu
interactive_menu() {
  while true; do
    echo ""
    echo "=========================================="
    echo "  Cron Helper"
    echo "=========================================="
    echo ""
    echo "  1. List cron jobs"
    echo "  2. Add cron job"
    echo "  3. Remove cron job"
    echo "  4. Edit crontab"
    echo "  5. Export to file"
    echo "  6. Import from file"
    echo "  7. Clear all jobs"
    echo "  8. Show examples"
    echo "  9. Exit"
    echo ""

    read -r -p "Select option: " choice

    case "$choice" in
      1) list_cron ;;
      2) add_cron ;;
      3) remove_cron ;;
      4) edit_cron ;;
      5) export_cron ;;
      6) import_cron ;;
      7) clear_cron ;;
      8) show_examples ;;
      9) exit 0 ;;
      *) log_error "Invalid option" ;;
    esac
  done
}

# Show usage
show_usage() {
  cat <<EOF
Cron Helper - Manage cron jobs interactively

Usage: $(basename "$0") [COMMAND] [OPTIONS]

COMMANDS:
  list              List current cron jobs (default)
  add SCHEDULE CMD  Add a new cron job
  remove [N]        Remove cron job by number
  edit              Open crontab in editor
  export [FILE]     Export cron jobs to file
  import FILE       Import cron jobs from file
  clear             Remove all cron jobs
  examples          Show schedule examples
  menu              Interactive menu

EXAMPLES:
  $(basename "$0")                              # List jobs
  $(basename "$0") add "0 * * * *" "/path/to/script.sh"
  $(basename "$0") add "@daily" "backup.sh"
  $(basename "$0") remove 2                     # Remove job #2
  $(basename "$0") export backup.txt
  $(basename "$0") menu                         # Interactive mode
EOF
}

# Main
main() {
  local command="${1:-list}"
  shift || true

  case "$command" in
    list) list_cron ;;
    add) add_cron "$@" ;;
    remove) remove_cron "$@" ;;
    edit) edit_cron ;;
    export) export_cron "$@" ;;
    import) import_cron "$@" ;;
    clear) clear_cron ;;
    examples) show_examples ;;
    menu) interactive_menu ;;
    -h | --help) show_usage ;;
    *)
      log_error "Unknown command: $command"
      show_usage
      exit 1
      ;;
  esac
}

main "$@"
