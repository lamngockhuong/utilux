#!/bin/bash
# @name: env-setup
# @version: v1.0.0
# @description: Setup development environment with common tools
# @category: dev
# @requires: curl
# @tags: dev, setup, tools
# @author: lamngockhuong
# @draft

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

# Detect package manager
detect_pkg_manager() {
  if command -v apt-get &>/dev/null; then
    echo "apt"
  elif command -v dnf &>/dev/null; then
    echo "dnf"
  elif command -v yum &>/dev/null; then
    echo "yum"
  elif command -v apk &>/dev/null; then
    echo "apk"
  elif command -v pacman &>/dev/null; then
    echo "pacman"
  elif command -v brew &>/dev/null; then
    echo "brew"
  else
    echo "unknown"
  fi
}

# Install package
install_pkg() {
  local pkg="$1"
  local pkg_mgr
  pkg_mgr=$(detect_pkg_manager)

  case "$pkg_mgr" in
    apt)
      sudo apt-get install -y "$pkg"
      ;;
    dnf | yum)
      sudo "$pkg_mgr" install -y "$pkg"
      ;;
    apk)
      sudo apk add --no-cache "$pkg"
      ;;
    pacman)
      sudo pacman -S --noconfirm "$pkg"
      ;;
    brew)
      brew install "$pkg"
      ;;
    *)
      log_error "Unknown package manager"
      return 1
      ;;
  esac
}

# Check if command exists
has_cmd() {
  command -v "$1" &>/dev/null
}

# Update package lists
update_packages() {
  log_info "Updating package lists..."
  local pkg_mgr
  pkg_mgr=$(detect_pkg_manager)

  case "$pkg_mgr" in
    apt)
      sudo apt-get update
      ;;
    dnf | yum)
      sudo "$pkg_mgr" check-update || true
      ;;
    apk)
      sudo apk update
      ;;
    pacman)
      sudo pacman -Sy
      ;;
    brew)
      brew update
      ;;
  esac
}

# Install basic tools
install_basic_tools() {
  log_info "Installing basic development tools..."

  local tools=(
    git
    curl
    wget
    vim
    htop
    tree
    jq
    unzip
    tar
    gzip
  )

  for tool in "${tools[@]}"; do
    if has_cmd "$tool"; then
      log_success "$tool already installed"
    else
      log_info "Installing $tool..."
      install_pkg "$tool" || log_warn "Failed to install $tool"
    fi
  done
}

# Install build essentials
install_build_tools() {
  log_info "Installing build tools..."

  local pkg_mgr
  pkg_mgr=$(detect_pkg_manager)

  case "$pkg_mgr" in
    apt)
      sudo apt-get install -y build-essential
      ;;
    dnf | yum)
      sudo "$pkg_mgr" groupinstall -y "Development Tools"
      ;;
    apk)
      sudo apk add --no-cache build-base
      ;;
    pacman)
      sudo pacman -S --noconfirm base-devel
      ;;
    brew)
      xcode-select --install 2>/dev/null || true
      ;;
  esac

  log_success "Build tools installed"
}

# Install Node.js via nvm
install_node() {
  if has_cmd node; then
    log_success "Node.js already installed: $(node --version)"
    return
  fi

  log_info "Installing Node.js via nvm..."

  if [[ ! -d "$HOME/.nvm" ]]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  fi

  export NVM_DIR="$HOME/.nvm"
  # shellcheck source=/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

  nvm install --lts
  nvm use --lts

  log_success "Node.js installed: $(node --version)"
}

# Install Python tools
install_python() {
  if has_cmd python3; then
    log_success "Python3 already installed: $(python3 --version)"
  else
    log_info "Installing Python3..."
    install_pkg python3 || install_pkg python
  fi

  if ! has_cmd pip3 && ! has_cmd pip; then
    log_info "Installing pip..."
    install_pkg python3-pip || install_pkg python-pip || true
  fi

  log_success "Python setup complete"
}

# Install Go
install_go() {
  if has_cmd go; then
    log_success "Go already installed: $(go version)"
    return
  fi

  log_info "Installing Go..."

  local go_version="1.22.0"
  local arch
  arch=$(uname -m)
  case "$arch" in
    x86_64) arch="amd64" ;;
    aarch64) arch="arm64" ;;
    armv*) arch="arm" ;;
  esac

  curl -sLO "https://go.dev/dl/go${go_version}.linux-${arch}.tar.gz"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "go${go_version}.linux-${arch}.tar.gz"
  rm "go${go_version}.linux-${arch}.tar.gz"

  # Add to PATH
  if ! grep -q '/usr/local/go/bin' ~/.bashrc; then
    echo 'export PATH=$PATH:/usr/local/go/bin' >>~/.bashrc
  fi

  export PATH=$PATH:/usr/local/go/bin
  log_success "Go installed: $(go version)"
}

# Install Rust
install_rust() {
  if has_cmd rustc; then
    log_success "Rust already installed: $(rustc --version)"
    return
  fi

  log_info "Installing Rust via rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

  # shellcheck source=/dev/null
  source "$HOME/.cargo/env"

  log_success "Rust installed: $(rustc --version)"
}

# Install Docker
install_docker() {
  if has_cmd docker; then
    log_success "Docker already installed: $(docker --version)"
    return
  fi

  log_info "Installing Docker..."

  local pkg_mgr
  pkg_mgr=$(detect_pkg_manager)

  case "$pkg_mgr" in
    apt)
      # Add Docker's official GPG key
      sudo apt-get install -y ca-certificates curl gnupg
      sudo install -m 0755 -d /etc/apt/keyrings
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
      sudo chmod a+r /etc/apt/keyrings/docker.gpg

      # Add repository
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

      sudo apt-get update
      sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
      ;;
    dnf)
      sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
      sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
      ;;
    *)
      log_warn "Docker installation not automated for this system"
      log_info "Visit: https://docs.docker.com/engine/install/"
      return
      ;;
  esac

  sudo systemctl start docker
  sudo systemctl enable docker
  sudo usermod -aG docker "$USER"

  log_success "Docker installed. Log out and back in to use without sudo."
}

# Setup git config
setup_git() {
  log_info "Setting up Git configuration..."

  local name email

  if ! git config --global user.name &>/dev/null; then
    read -r -p "Enter your Git name: " name
    git config --global user.name "$name"
  fi

  if ! git config --global user.email &>/dev/null; then
    read -r -p "Enter your Git email: " email
    git config --global user.email "$email"
  fi

  # Useful defaults
  git config --global init.defaultBranch main
  git config --global pull.rebase false
  git config --global core.editor vim

  log_success "Git configured"
}

# Show summary
show_summary() {
  echo ""
  log_info "Environment Summary:"
  echo ""

  has_cmd git && echo "  Git:     $(git --version | cut -d' ' -f3)"
  has_cmd node && echo "  Node:    $(node --version)"
  has_cmd npm && echo "  npm:     $(npm --version)"
  has_cmd python3 && echo "  Python:  $(python3 --version | cut -d' ' -f2)"
  has_cmd go && echo "  Go:      $(go version | cut -d' ' -f3)"
  has_cmd rustc && echo "  Rust:    $(rustc --version | cut -d' ' -f2)"
  has_cmd docker && echo "  Docker:  $(docker --version | cut -d' ' -f3 | tr -d ',')"

  echo ""
}

# Show usage
show_usage() {
  cat <<EOF
Development Environment Setup

Usage: $(basename "$0") [OPTIONS]

OPTIONS:
  -a, --all          Install everything
  -b, --basic        Basic tools (git, curl, vim, etc.)
  -B, --build        Build tools (gcc, make, etc.)
  -n, --node         Node.js via nvm
  -p, --python       Python3 and pip
  -g, --go           Go programming language
  -r, --rust         Rust via rustup
  -d, --docker       Docker and Docker Compose
  -G, --git          Configure Git
  -h, --help         Show this help

EXAMPLES:
  $(basename "$0") -b           # Install basic tools
  $(basename "$0") -a           # Install everything
  $(basename "$0") -n -d        # Node and Docker
  $(basename "$0") -G           # Just configure Git
EOF
}

# Main
main() {
  local do_basic=0
  local do_build=0
  local do_node=0
  local do_python=0
  local do_go=0
  local do_rust=0
  local do_docker=0
  local do_git=0

  if [[ $# -eq 0 ]]; then
    show_usage
    exit 0
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -a | --all)
        do_basic=1
        do_build=1
        do_node=1
        do_python=1
        do_go=1
        do_rust=1
        do_docker=1
        do_git=1
        shift
        ;;
      -b | --basic)
        do_basic=1
        shift
        ;;
      -B | --build)
        do_build=1
        shift
        ;;
      -n | --node)
        do_node=1
        shift
        ;;
      -p | --python)
        do_python=1
        shift
        ;;
      -g | --go)
        do_go=1
        shift
        ;;
      -r | --rust)
        do_rust=1
        shift
        ;;
      -d | --docker)
        do_docker=1
        shift
        ;;
      -G | --git)
        do_git=1
        shift
        ;;
      -h | --help)
        show_usage
        exit 0
        ;;
      *)
        log_error "Unknown option: $1"
        show_usage
        exit 1
        ;;
    esac
  done

  echo "=========================================="
  echo "  Development Environment Setup"
  echo "=========================================="
  echo ""

  update_packages

  [[ $do_basic -eq 1 ]] && install_basic_tools
  [[ $do_build -eq 1 ]] && install_build_tools
  [[ $do_node -eq 1 ]] && install_node
  [[ $do_python -eq 1 ]] && install_python
  [[ $do_go -eq 1 ]] && install_go
  [[ $do_rust -eq 1 ]] && install_rust
  [[ $do_docker -eq 1 ]] && install_docker
  [[ $do_git -eq 1 ]] && setup_git

  show_summary

  log_success "Environment setup complete!"
}

main "$@"
