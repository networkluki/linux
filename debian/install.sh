#!/usr/bin/env sh
# NetworkLuki APT repository installer
#
# Usage:
#   sh install.sh
#
# Then:
#   sudo apt update
#   sudo apt install nlsshm

set -eu

REPO_URL="https://apt.networkluki.com"
KEY_URL="$REPO_URL/public.key"
KEYRING="/usr/share/keyrings/networkluki-apt.gpg"
LIST_FILE="/etc/apt/sources.list.d/networkluki.list"
CODENAME="trixie"

info()  { printf '%s\n' "[networkluki] $*"; }
error() { printf '%s\n' "[networkluki][ERROR] $*" >&2; exit 1; }

require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        error "Run as root: sudo sh install.sh"
    fi
}

detect_codename() {
    if [ -r /etc/os-release ]; then
        . /etc/os-release
        if [ -n "${VERSION_CODENAME:-}" ]; then
            CODENAME="$VERSION_CODENAME"
        fi
    fi
}

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || error "Missing required command: $1"
}

require_root
need_cmd curl
need_cmd gpg
need_cmd apt-get

detect_codename

info "Detected codename: $CODENAME"

info "Installing prerequisites..."
apt-get update -y
apt-get install -y ca-certificates gnupg

info "Fetching and installing GPG key..."
curl -fsSL "$KEY_URL" \
  | gpg --dearmor \
  | tee "$KEYRING" >/dev/null
chmod 0644 "$KEYRING"

info "Adding APT repository..."
echo "deb [signed-by=$KEYRING] $REPO_URL $CODENAME main" \
  > "$LIST_FILE"

info "APT repository installed successfully."
info "Next steps:"
info "  sudo apt update"
info "  sudo apt install nlsshm"
