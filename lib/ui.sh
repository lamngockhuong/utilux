#!/bin/bash
# @name: ui.sh
# @description: UI utilities - colors, prompts, spinners
# @version: v1.0.0

# Prevent double sourcing
[[ -n "${_UTIX_UI_LOADED:-}" ]] && return 0
_UTIX_UI_LOADED=1

# Check if gum is available (modern TUI)
_has_gum() {
  has_cmd gum
}

# Check if whiptail is available (legacy fallback)
_has_whiptail() {
  has_cmd whiptail
}

# Show spinner while process is running
ui_spinner() {
  local pid="$1"
  local msg="${2:-Loading...}"
  local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local i=0

  while kill -0 "$pid" 2>/dev/null; do
    printf "\r${UTIX_CYAN}%s${UTIX_NC} %s" "${spin:i++%${#spin}:1}" "$msg"
    sleep 0.1
  done

  printf "\r\033[K"  # Clear line
}

# Confirm prompt (gum > simple)
ui_confirm() {
  local msg="$1"
  local default="${2:-n}"

  if _has_gum && [[ -t 0 ]]; then
    if [[ "$default" == "y" ]]; then
      gum confirm "$msg" --default=true
    else
      gum confirm "$msg" --default=false
    fi
  else
    local prompt
    if [[ "$default" == "y" ]]; then
      prompt="[Y/n]"
    else
      prompt="[y/N]"
    fi

    read -r -p "$msg $prompt " response
    response="${response:-$default}"

    [[ "$response" =~ ^[Yy] ]]
  fi
}

# Simple selection menu (fallback)
_ui_select_simple() {
  local title="$1"
  shift
  local options=("$@")
  local i=1

  echo "$title" >&2
  echo "---" >&2

  for opt in "${options[@]}"; do
    echo "  $i) $opt" >&2
    ((i++))
  done

  echo "" >&2
  read -r -p "Select (1-${#options[@]}): " choice

  if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le ${#options[@]} ]]; then
    echo "${options[$((choice-1))]}"
    return 0
  fi

  return 1
}

# Selection menu (gum > whiptail > simple)
ui_select() {
  local title="$1"
  shift
  local options=("$@")

  if _has_gum && [[ -t 0 ]]; then
    echo "$title" >&2
    gum choose "${options[@]}"
  elif _has_whiptail && [[ -t 0 ]]; then
    local menu_options=()
    local i=1
    for opt in "${options[@]}"; do
      menu_options+=("$i" "$opt")
      ((i++))
    done

    local choice
    choice=$(whiptail --title "Utix" --menu "$title" 20 60 10 "${menu_options[@]}" 3>&1 1>&2 2>&3)

    if [[ $? -eq 0 && -n "$choice" ]]; then
      echo "${options[$((choice-1))]}"
      return 0
    fi
    return 1
  else
    _ui_select_simple "$title" "${options[@]}"
  fi
}

# Input prompt (gum > whiptail > simple)
ui_input() {
  local msg="$1"
  local default="${2:-}"

  if _has_gum && [[ -t 0 ]]; then
    gum input --placeholder "$msg" --value "$default"
  elif _has_whiptail && [[ -t 0 ]]; then
    whiptail --title "Utix" --inputbox "$msg" 10 60 "$default" 3>&1 1>&2 2>&3
  else
    local input
    if [[ -n "$default" ]]; then
      read -r -p "$msg [$default]: " input
      echo "${input:-$default}"
    else
      read -r -p "$msg: " input
      echo "$input"
    fi
  fi
}

# Message box (gum > whiptail > simple)
ui_message() {
  local title="$1"
  local msg="$2"
  # Strip ANSI codes for TUI display
  msg=$(echo -e "$msg" | sed 's/\x1b\[[0-9;]*m//g')

  if _has_gum && [[ -t 0 ]]; then
    echo -e "[$title]\n\n$msg" | gum style --border rounded --padding "1 2" --border-foreground 212
  elif _has_whiptail && [[ -t 0 ]]; then
    whiptail --title "$title" --msgbox "$msg" 10 60
  else
    echo "=== $title ===" >&2
    echo "$msg" >&2
    echo "" >&2
  fi
}

# Progress display
ui_progress() {
  local current="$1"
  local total="$2"
  local msg="${3:-Progress}"
  local width=40
  local percent=$((current * 100 / total))
  local filled=$((current * width / total))
  local empty=$((width - filled))

  printf "\r%s: [" "$msg"
  printf "%0.s#" $(seq 1 $filled)
  printf "%0.s-" $(seq 1 $empty)
  printf "] %3d%%" "$percent"

  [[ $current -eq $total ]] && echo ""
}

# Print formatted table
ui_table() {
  local -n headers_ref=$1
  local -n rows_ref=$2

  # Calculate column widths
  local widths=()
  for h in "${headers_ref[@]}"; do
    widths+=("${#h}")
  done

  for row in "${rows_ref[@]}"; do
    IFS='|' read -ra cols <<< "$row"
    for i in "${!cols[@]}"; do
      local len=${#cols[$i]}
      [[ $len -gt ${widths[$i]:-0} ]] && widths[$i]=$len
    done
  done

  # Print header
  local format=""
  for w in "${widths[@]}"; do
    format+="%-$((w+2))s "
  done

  printf "$format\n" "${headers_ref[@]}"

  # Print separator
  local sep=""
  for w in "${widths[@]}"; do
    sep+=$(printf '%*s' "$((w+2))" '' | tr ' ' '-')
    sep+=" "
  done
  echo "$sep"

  # Print rows
  for row in "${rows_ref[@]}"; do
    IFS='|' read -ra cols <<< "$row"
    printf "$format\n" "${cols[@]}"
  done
}
