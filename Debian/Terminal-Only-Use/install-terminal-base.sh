#!/usr/bin/env bash
set -Eeuo pipefail

# Debian 13 terminal-only base installer
# - Installs a practical package set for terminal workflows
# - Avoids GUI package recommendations
# - Optionally installs btop
# - Adds "alias fd=fdfind" to the target user's ~/.bashrc
#
# Usage:
#   bash install-terminal-base.sh
#   INSTALL_BTOP=1 bash install-terminal-base.sh
#
# Notes:
# - This script does NOT harden SSH automatically
# - This script does NOT enable or configure nftables/fail2ban automatically
# - Run it as a normal sudo-capable user, not as root, if you want ~/.bashrc updated for your user

log()  { printf '[INFO] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
err()  { printf '[ERR ] %s\n' "$*" >&2; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    err "Required command not found: $1"
    exit 1
  }
}

require_sudo() {
  if ! sudo -n true 2>/dev/null; then
    log "sudo authentication is required."
    sudo -v
  fi
}

detect_target_user() {
  if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    TARGET_USER="${SUDO_USER}"
    TARGET_HOME="$(getent passwd "${SUDO_USER}" | cut -d: -f6)"
  else
    TARGET_USER="${USER}"
    TARGET_HOME="${HOME}"
  fi

  if [[ -z "${TARGET_HOME:-}" || ! -d "${TARGET_HOME}" ]]; then
    err "Could not determine target home directory."
    exit 1
  fi
}

check_debian() {
  if [[ ! -r /etc/os-release ]]; then
    err "/etc/os-release not found."
    exit 1
  fi

  . /etc/os-release

  if [[ "${ID:-}" != "debian" ]]; then
    err "This script is intended for Debian."
    exit 1
  fi

  log "Detected: ${PRETTY_NAME:-Debian}"
}

collect_packages() {
  CORE_PACKAGES=(
    tmux
    htop
    ncdu
    ripgrep
    fd-find
    fzf
    jq
    micro
  )

  DEV_PACKAGES=(
    git
    build-essential
    strace
    lsof
  )

  OPS_PACKAGES=(
    openssh-server
    rsync
    nftables
    fail2ban
    wireguard-tools
    smartmontools
    lm-sensors
  )

  OPTIONAL_PACKAGES=()
  if [[ "${INSTALL_BTOP:-0}" == "1" ]]; then
    OPTIONAL_PACKAGES+=(btop)
  fi

  ALL_PACKAGES=(
    "${CORE_PACKAGES[@]}"
    "${DEV_PACKAGES[@]}"
    "${OPS_PACKAGES[@]}"
    "${OPTIONAL_PACKAGES[@]}"
  )
}

validate_packages() {
  AVAILABLE_PACKAGES=()
  MISSING_PACKAGES=()

  for pkg in "${ALL_PACKAGES[@]}"; do
    if apt-cache show "$pkg" >/dev/null 2>&1; then
      AVAILABLE_PACKAGES+=("$pkg")
    else
      MISSING_PACKAGES+=("$pkg")
    fi
  done

  if ((${#MISSING_PACKAGES[@]} > 0)); then
    warn "The following packages were not found in current APT metadata:"
    printf '  - %s\n' "${MISSING_PACKAGES[@]}" >&2
    warn "They will be skipped."
  fi

  if ((${#AVAILABLE_PACKAGES[@]} == 0)); then
    err "No installable packages remained after validation."
    exit 1
  fi
}

install_packages() {
  log "Refreshing APT metadata..."
  sudo apt-get update

  log "Installing packages..."
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${AVAILABLE_PACKAGES[@]}"
}

ensure_fd_alias() {
  local bashrc="${TARGET_HOME}/.bashrc"
  local marker="# Added by install-terminal-base.sh: fd alias for Debian"

  if [[ ! -f "$bashrc" ]]; then
    warn "${bashrc} not found, skipping alias setup."
    return
  fi

  if grep -Fq "$marker" "$bashrc"; then
    log "fd alias already present in ${bashrc}"
    return
  fi

  {
    printf '\n%s\n' "$marker"
    printf "alias fd='fdfind'\n"
  } >> "$bashrc"

  if [[ "${TARGET_USER}" != "${USER}" ]]; then
    sudo chown "${TARGET_USER}:${TARGET_USER}" "$bashrc"
  fi

  log "Added alias: fd -> fdfind"
}

print_summary() {
  cat <<EOF

Installation complete.

Installed package groups:
  Core: tmux htop ncdu ripgrep fd-find fzf jq micro
  Dev : git build-essential strace lsof
  Ops : openssh-server rsync nftables fail2ban wireguard-tools smartmontools lm-sensors
EOF

  if [[ "${INSTALL_BTOP:-0}" == "1" ]]; then
    cat <<'EOF'
  Extra: btop
EOF
  fi

  cat <<'EOF'

Useful next commands:
  tmux new -s work
  rg "TODO|FIXME" .
  fd ssh /etc
  ncdu /
  jq . /path/to/file.json
  htop
  strace -p <PID>
  lsof -i :22
  sensors
  sudo smartctl -a /dev/sda
  sudo smartctl -a /dev/nvme0

Recommended follow-up:
  sudo systemctl status ssh
  sudo systemctl status fail2ban
  sudo systemctl status nftables
  sudo sensors-detect

Open a new shell or run:
  source ~/.bashrc
EOF
}

main() {
  require_cmd sudo
  require_cmd apt-get
  require_cmd apt-cache
  require_cmd getent
  require_sudo
  detect_target_user
  check_debian
  collect_packages
  validate_packages
  install_packages
  ensure_fd_alias
  print_summary
}

main "$@"
