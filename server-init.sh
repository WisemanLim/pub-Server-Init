#!/usr/bin/env bash
# =============================================================================
# server-init.sh — Server Initialization Script
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/WisemanLim/pub-Server-Init/refs/heads/main/server-init.sh)
# =============================================================================

set -euo pipefail

# ─── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Logging ─────────────────────────────────────────────────────────────────
log()     { echo -e "${BLUE}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }
header()  { echo -e "\n${BOLD}${CYAN}══════════════════════════════════════${NC}"; echo -e "${BOLD}${CYAN}  $*${NC}"; echo -e "${BOLD}${CYAN}══════════════════════════════════════${NC}"; }
step()    { echo -e "\n${BOLD}▶ $*${NC}"; }

# ─── Ask helpers ─────────────────────────────────────────────────────────────
ask_yes_no() {
  local prompt="$1" default="${2:-y}"
  local yn_hint
  [[ "$default" == "y" ]] && yn_hint="[Y/n]" || yn_hint="[y/N]"
  while true; do
    read -r -p "$(echo -e "${YELLOW}?${NC} ${prompt} ${yn_hint}: ")" answer
    answer="${answer:-$default}"
    case "${answer,,}" in
      y|yes) return 0 ;;
      n|no)  return 1 ;;
      *)     echo "  Please enter y or n." ;;
    esac
  done
}

ask_input() {
  local prompt="$1" default="${2:-}"
  local hint=""
  [[ -n "$default" ]] && hint=" (default: ${default})"
  read -r -p "$(echo -e "${YELLOW}?${NC} ${prompt}${hint}: ")" value
  echo "${value:-$default}"
}

# ─── OS Detection ────────────────────────────────────────────────────────────
detect_os() {
  if [[ -f /etc/os-release ]]; then
    # shellcheck source=/dev/null
    source /etc/os-release
    OS_ID="${ID:-unknown}"
    OS_VERSION="${VERSION_ID:-}"
    OS_NAME="${PRETTY_NAME:-$ID}"
  elif command -v lsb_release &>/dev/null; then
    OS_ID=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
    OS_VERSION=$(lsb_release -sr)
    OS_NAME="$OS_ID $OS_VERSION"
  else
    error "Cannot detect OS. /etc/os-release not found."
    exit 1
  fi

  # Determine package manager
  if command -v apt-get &>/dev/null; then
    PKG_MGR="apt"
  elif command -v dnf &>/dev/null; then
    PKG_MGR="dnf"
  elif command -v yum &>/dev/null; then
    PKG_MGR="yum"
  elif command -v pacman &>/dev/null; then
    PKG_MGR="pacman"
  elif command -v zypper &>/dev/null; then
    PKG_MGR="zypper"
  else
    error "No supported package manager found (apt/dnf/yum/pacman/zypper)."
    exit 1
  fi

  success "OS: ${OS_NAME} | Package manager: ${PKG_MGR}"
}

# ─── Privilege check ─────────────────────────────────────────────────────────
check_sudo() {
  if [[ $EUID -eq 0 ]]; then
    SUDO=""
  elif command -v sudo &>/dev/null; then
    SUDO="sudo"
    # Validate sudo access
    if ! sudo -v 2>/dev/null; then
      error "sudo access required but not available."
      exit 1
    fi
  else
    error "This script requires root or sudo access."
    exit 1
  fi
}

# ─── Package install wrapper ──────────────────────────────────────────────────
pkg_install() {
  case "$PKG_MGR" in
    apt)    $SUDO apt-get install -y "$@" ;;
    dnf)    $SUDO dnf install -y "$@" ;;
    yum)    $SUDO yum install -y "$@" ;;
    pacman) $SUDO pacman -S --noconfirm "$@" ;;
    zypper) $SUDO zypper install -y "$@" ;;
  esac
}

pkg_update() {
  case "$PKG_MGR" in
    apt)    $SUDO apt-get update && $SUDO apt-get upgrade -y ;;
    dnf)    $SUDO dnf upgrade -y ;;
    yum)    $SUDO yum update -y ;;
    pacman) $SUDO pacman -Syu --noconfirm ;;
    zypper) $SUDO zypper update -y ;;
  esac
}

# ─── Version check ────────────────────────────────────────────────────────────
cmd_version() {
  local cmd="$1" flag="${2:---version}"
  if command -v "$cmd" &>/dev/null; then
    "$cmd" "$flag" 2>/dev/null | head -1 || echo "installed"
  else
    echo ""
  fi
}

is_installed() {
  command -v "$1" &>/dev/null
}

# ─── Step 1: System Update ────────────────────────────────────────────────────
run_system_update() {
  header "1. System Package Update"
  if ask_yes_no "Run system package update?"; then
    log "Updating system packages..."
    pkg_update
    success "System updated."
  else
    log "Skipped system update."
  fi
}

# ─── Step 2: Base Packages ────────────────────────────────────────────────────
install_base_packages() {
  header "2. Base Packages"

  local base_pkgs=()
  case "$PKG_MGR" in
    apt)
      base_pkgs=(git curl wget unzip jq make build-essential ca-certificates gnupg lsb-release software-properties-common)
      ;;
    dnf|yum)
      base_pkgs=(git curl wget unzip jq make gcc gcc-c++ kernel-devel ca-certificates gnupg2)
      ;;
    pacman)
      base_pkgs=(git curl wget unzip jq make base-devel ca-certificates gnupg)
      ;;
    zypper)
      base_pkgs=(git curl wget unzip jq make gcc gcc-c++ ca-certificates gpg2)
      ;;
  esac

  local missing=()
  for pkg in "${base_pkgs[@]}"; do
    if ! is_installed "$pkg" && ! dpkg -l "$pkg" &>/dev/null 2>&1 && ! rpm -q "$pkg" &>/dev/null 2>&1; then
      missing+=("$pkg")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    log "Installing base packages: ${missing[*]}"
    pkg_install "${missing[@]}" || true
  fi
  success "Base packages ready."
}

# ─── Step 3: Docker ──────────────────────────────────────────────────────────
install_docker() {
  header "3. Docker & Docker Compose"

  local docker_ver
  docker_ver=$(cmd_version docker)

  if [[ -n "$docker_ver" ]]; then
    success "Docker already installed: $docker_ver"
    if ask_yes_no "Update Docker?" "n"; then
      _do_install_docker
    fi
  else
    log "Docker not found."
    if ask_yes_no "Install Docker?"; then
      _do_install_docker
    fi
  fi

  # Docker Compose (v2 plugin)
  local compose_ver
  compose_ver=$(docker compose version 2>/dev/null || echo "")
  if [[ -z "$compose_ver" ]]; then
    log "Docker Compose plugin not found, installing..."
    case "$PKG_MGR" in
      apt)    pkg_install docker-compose-plugin ;;
      dnf|yum) pkg_install docker-compose-plugin 2>/dev/null || _install_compose_binary ;;
      *)      _install_compose_binary ;;
    esac
  else
    success "Docker Compose: $compose_ver"
  fi

  # Add user to docker group
  if [[ -n "${SUDO_USER:-}" ]] || [[ $EUID -ne 0 ]]; then
    local target_user="${SUDO_USER:-$USER}"
    if ! groups "$target_user" | grep -q docker; then
      $SUDO usermod -aG docker "$target_user" 2>/dev/null || true
      warn "Added '$target_user' to docker group. Re-login required for group to take effect."
    fi
  fi
}

_do_install_docker() {
  case "$PKG_MGR" in
    apt) _install_docker_apt ;;
    dnf) _install_docker_dnf ;;
    yum) _install_docker_yum ;;
    pacman) pkg_install docker ;;
    zypper) pkg_install docker ;;
  esac
  $SUDO systemctl enable --now docker 2>/dev/null || true
  success "Docker installed."
}

_install_docker_apt() {
  $SUDO install -m 0755 -d /etc/apt/keyrings
  local distro_id distro_codename
  distro_id=$(. /etc/os-release; echo "$ID")
  distro_codename=$(. /etc/os-release; echo "$VERSION_CODENAME")
  curl -fsSL "https://download.docker.com/linux/${distro_id}/gpg" \
    | $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  $SUDO chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/${distro_id} \
    ${distro_codename} stable" \
    | $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null
  $SUDO apt-get update
  pkg_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

_install_docker_dnf() {
  $SUDO dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo 2>/dev/null \
    || $SUDO dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  pkg_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

_install_docker_yum() {
  $SUDO yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo 2>/dev/null || true
  pkg_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

_install_compose_binary() {
  local compose_url
  compose_url="https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)"
  $SUDO mkdir -p /usr/local/lib/docker/cli-plugins
  $SUDO curl -fsSL "$compose_url" -o /usr/local/lib/docker/cli-plugins/docker-compose
  $SUDO chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
}

# ─── Step 4: GitHub CLI ──────────────────────────────────────────────────────
install_gh() {
  header "4. GitHub CLI (gh)"

  local gh_ver
  gh_ver=$(cmd_version gh)

  if [[ -n "$gh_ver" ]]; then
    success "gh already installed: $gh_ver"
    if ask_yes_no "Update gh?" "n"; then
      _do_install_gh
    fi
  else
    log "gh not found."
    if ask_yes_no "Install GitHub CLI (gh)?"; then
      _do_install_gh
    fi
  fi
}

_do_install_gh() {
  case "$PKG_MGR" in
    apt)
      curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | $SUDO dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
      $SUDO chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
        https://cli.github.com/packages stable main" \
        | $SUDO tee /etc/apt/sources.list.d/github-cli.list > /dev/null
      $SUDO apt-get update
      pkg_install gh
      ;;
    dnf|yum)
      $SUDO "$PKG_MGR" config-manager --add-repo \
        https://cli.github.com/packages/rpm/gh-cli.repo 2>/dev/null || true
      pkg_install gh
      ;;
    pacman)
      pkg_install github-cli
      ;;
    zypper)
      $SUDO zypper addrepo https://cli.github.com/packages/rpm/gh-cli.repo gh-cli || true
      $SUDO zypper ref
      pkg_install gh
      ;;
  esac
  success "gh installed: $(gh --version | head -1)"
}

# ─── Step 5: Git & GitHub Setup ──────────────────────────────────────────────
setup_git_github() {
  header "5. Git & GitHub Configuration"

  # Git global config
  local current_name current_email
  current_name=$(git config --global user.name 2>/dev/null || echo "")
  current_email=$(git config --global user.email 2>/dev/null || echo "")

  if [[ -n "$current_name" && -n "$current_email" ]]; then
    success "Git already configured: $current_name <$current_email>"
    if ! ask_yes_no "Update git config?" "n"; then
      _skip_git_config=true
    fi
  fi

  if [[ "${_skip_git_config:-false}" != "true" ]]; then
    local git_name git_email
    git_name=$(ask_input "Git user.name" "$current_name")
    git_email=$(ask_input "Git user.email" "$current_email")
    if [[ -n "$git_name" ]]; then git config --global user.name "$git_name"; fi
    if [[ -n "$git_email" ]]; then git config --global user.email "$git_email"; fi
    success "Git config updated."
  fi

  # gh auth
  if is_installed gh; then
    local gh_status
    gh_status=$(gh auth status 2>&1 || true)
    if echo "$gh_status" | grep -q "Logged in"; then
      success "gh: already authenticated."
      if ask_yes_no "Re-authenticate with GitHub?" "n"; then
        gh auth login
      fi
    else
      if ask_yes_no "Authenticate with GitHub via gh?"; then
        gh auth login
      fi
    fi
  else
    warn "gh not installed, skipping auth."
  fi
}

# ─── Step 6: Dev Environments ────────────────────────────────────────────────
install_dev_envs() {
  header "6. Developer Environment Setup"

  echo ""
  echo -e "  Select environments to install/check:"
  echo -e "  ${BOLD}1)${NC} Python  (uv, uvicorn)"
  echo -e "  ${BOLD}2)${NC} Node.js (nvm, pnpm, optional: Next.js / Nest.js CLI)"
  echo -e "  ${BOLD}3)${NC} Go"
  echo -e "  ${BOLD}4)${NC} Rust"
  echo -e "  ${BOLD}5)${NC} All of the above"
  echo -e "  ${BOLD}0)${NC} Skip"
  echo ""

  local choice
  choice=$(ask_input "Enter numbers (e.g. 1 3) or 5 for all, 0 to skip" "0")

  local do_python=false do_node=false do_go=false do_rust=false

  if [[ "$choice" == "0" ]]; then
    log "Skipping dev environment setup."
    return
  fi

  for c in $choice; do
    case "$c" in
      1) do_python=true ;;
      2) do_node=true ;;
      3) do_go=true ;;
      4) do_rust=true ;;
      5) do_python=true; do_node=true; do_go=true; do_rust=true ;;
    esac
  done

  $do_python && install_python
  $do_node   && install_node
  $do_go     && install_go
  $do_rust   && install_rust
}

# Python (uv)
install_python() {
  step "Python — uv + uvicorn"

  # uv
  local uv_ver
  uv_ver=$(cmd_version uv)
  if [[ -n "$uv_ver" ]]; then
    success "uv already installed: $uv_ver"
    if ask_yes_no "Update uv?" "n"; then
      uv self update 2>/dev/null || curl -LsSf https://astral.sh/uv/install.sh | sh
    fi
  else
    log "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    # shellcheck source=/dev/null
    export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
    success "uv installed: $(uv --version 2>/dev/null || echo 'see new shell')"
  fi

  # uvicorn via uv tool
  if uv tool list 2>/dev/null | grep -q uvicorn; then
    success "uvicorn already installed."
    if ask_yes_no "Update uvicorn?" "n"; then
      uv tool upgrade uvicorn 2>/dev/null || true
    fi
  else
    if ask_yes_no "Install uvicorn via uv tool?"; then
      uv tool install uvicorn[standard] 2>/dev/null || warn "uvicorn install failed; run manually: uv tool install uvicorn[standard]"
    fi
  fi

  _add_to_shell_rc 'export PATH="$HOME/.local/bin:$PATH"'
  _add_to_shell_rc 'export PATH="$HOME/.cargo/bin:$PATH"'
}

# Node.js (nvm + pnpm)
install_node() {
  step "Node.js — nvm + pnpm"

  # nvm — disable set -u: nvm scripts use unbound vars internally
  set +u
  if [[ -d "$HOME/.nvm" ]]; then
    success "nvm already installed."
    # shellcheck source=/dev/null
    source "$HOME/.nvm/nvm.sh" 2>/dev/null || true
    if ask_yes_no "Update nvm?" "n"; then
      curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/HEAD/install.sh | bash
    fi
  else
    log "Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/HEAD/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    # shellcheck source=/dev/null
    [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
  fi

  # Source nvm for current session
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  # shellcheck source=/dev/null
  [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh" || true

  # Node LTS
  if command -v node &>/dev/null; then
    set -u
    success "Node.js: $(node --version)"
    if ask_yes_no "Install/switch to latest LTS?" "n"; then
      set +u
      nvm install --lts && nvm use --lts && nvm alias default node
      set -u
    fi
  else
    log "Installing Node.js LTS..."
    nvm install --lts && nvm use --lts && nvm alias default node
    set -u
    success "Node.js: $(node --version)"
  fi

  # pnpm
  if command -v pnpm &>/dev/null; then
    success "pnpm: $(pnpm --version)"
    if ask_yes_no "Update pnpm?" "n"; then
      corepack enable pnpm 2>/dev/null || npm install -g pnpm
    fi
  else
    log "Installing pnpm..."
    corepack enable pnpm 2>/dev/null || npm install -g pnpm
    success "pnpm: $(pnpm --version 2>/dev/null || echo 'see new shell')"
  fi

  # Optional: Next.js / Nest.js CLI
  echo ""
  echo -e "  Node.js frameworks:"
  echo -e "  ${BOLD}1)${NC} Next.js  (create-next-app)"
  echo -e "  ${BOLD}2)${NC} Nest.js  (@nestjs/cli)"
  echo -e "  ${BOLD}3)${NC} Both"
  echo -e "  ${BOLD}0)${NC} Skip"
  local fw_choice
  fw_choice=$(ask_input "Framework CLI to install" "0")
  case "$fw_choice" in
    1|3) pnpm add -g create-next-app 2>/dev/null || npm install -g create-next-app; success "create-next-app installed." ;;
  esac
  case "$fw_choice" in
    2|3) pnpm add -g @nestjs/cli 2>/dev/null || npm install -g @nestjs/cli; success "@nestjs/cli installed." ;;
  esac
}

# Go
install_go() {
  step "Go"

  if command -v go &>/dev/null; then
    success "Go already installed: $(go version)"
    if ask_yes_no "Reinstall/update Go?" "n"; then
      _do_install_go
    fi
  else
    log "Installing Go..."
    _do_install_go
  fi
}

_do_install_go() {
  local go_version
  go_version=$(curl -fsSL "https://go.dev/VERSION?m=text" 2>/dev/null | head -1 | tr -d '[:space:]')
  [[ -z "$go_version" ]] && go_version="go1.22.4"
  local arch
  arch=$(uname -m)
  case "$arch" in
    x86_64)  arch="amd64" ;;
    aarch64) arch="arm64" ;;
    armv7*)  arch="armv6l" ;;
  esac
  local tarball="${go_version}.linux-${arch}.tar.gz"
  local url="https://go.dev/dl/${tarball}"

  log "Downloading $tarball ..."
  curl -fsSL "$url" -o "/tmp/${tarball}"
  $SUDO rm -rf /usr/local/go
  $SUDO tar -C /usr/local -xzf "/tmp/${tarball}"
  rm -f "/tmp/${tarball}"

  _add_to_shell_rc 'export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"'
  export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"
  success "Go installed: $(go version 2>/dev/null || echo "$go_version")"
}

# Rust
install_rust() {
  step "Rust"

  if command -v rustc &>/dev/null; then
    success "Rust already installed: $(rustc --version)"
    if ask_yes_no "Update Rust (rustup update)?" "n"; then
      rustup update
    fi
  else
    log "Installing Rust via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
    # shellcheck source=/dev/null
    source "$HOME/.cargo/env" 2>/dev/null || true
    _add_to_shell_rc 'source "$HOME/.cargo/env"'
    success "Rust installed: $(rustc --version 2>/dev/null || echo 'see new shell')"
  fi
}

# ─── Shell RC helpers ─────────────────────────────────────────────────────────
_get_shell_rc() {
  local shell_name
  shell_name=$(basename "${SHELL:-/bin/bash}")
  case "$shell_name" in
    zsh)  echo "$HOME/.zshrc" ;;
    fish) echo "$HOME/.config/fish/config.fish" ;;
    *)    echo "$HOME/.bashrc" ;;
  esac
}

_add_to_shell_rc() {
  local line="$1"
  local rc
  rc=$(_get_shell_rc)
  if [[ -f "$rc" ]] && grep -qF "$line" "$rc"; then
    return
  fi
  echo "$line" >> "$rc"
}

# ─── Step 7: Summary ─────────────────────────────────────────────────────────
print_summary() {
  header "Summary"

  local items=(
    "OS:${OS_NAME}"
    "git:$(git --version 2>/dev/null | awk '{print $3}' || echo 'not found')"
    "docker:$(docker --version 2>/dev/null | awk '{print $3}' | tr -d ',' || echo 'not found')"
    "docker compose:$(docker compose version 2>/dev/null | awk '{print $4}' || echo 'not found')"
    "gh:$(gh --version 2>/dev/null | head -1 | awk '{print $3}' || echo 'not found')"
    "uv:$(uv --version 2>/dev/null || echo 'not found')"
    "node:$(node --version 2>/dev/null || echo 'not found')"
    "pnpm:$(pnpm --version 2>/dev/null || echo 'not found')"
    "go:$(go version 2>/dev/null | awk '{print $3}' || echo 'not found')"
    "rustc:$(rustc --version 2>/dev/null | awk '{print $2}' || echo 'not found')"
  )

  echo ""
  for item in "${items[@]}"; do
    local key="${item%%:*}"
    local val="${item#*:}"
    if [[ "$val" == "not found" ]]; then
      echo -e "  ${YELLOW}✗${NC} ${key}: ${val}"
    else
      echo -e "  ${GREEN}✓${NC} ${key}: ${val}"
    fi
  done

  echo ""
  warn "If PATH-based tools show 'not found', open a new shell or run: source ~/.bashrc  (or ~/.zshrc)"
  echo ""
  echo -e "${BOLD}${GREEN}Server initialization complete.${NC}"
  echo ""
  echo -e "  Re-run anytime to check / update / add environments:"
  echo -e "  ${CYAN}bash <(curl -fsSL https://raw.githubusercontent.com/WisemanLim/pub-Server-Init/refs/heads/main/server-init.sh)${NC}"
  echo ""
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
  clear
  echo -e "${BOLD}${CYAN}"
  echo "  ╔═══════════════════════════════════════════╗"
  echo "  ║        Server Initialization Script       ║"
  echo "  ║   github.com/WisemanLim/pub-Server-Init   ║"
  echo "  ╚═══════════════════════════════════════════╝"
  echo -e "${NC}"
  echo -e "  ${YELLOW}Idempotent${NC} — safe to re-run anytime."
  echo ""

  detect_os
  check_sudo

  run_system_update
  install_base_packages
  install_docker
  install_gh
  setup_git_github
  install_dev_envs
  print_summary
}

main "$@"
