#!/usr/bin/env bash
set -euo pipefail

log() { printf '%s\n' "$*"; }

log "[*] Installing nvm..."
if [ ! -d "$HOME/.nvm" ]; then
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
else
  log "[i] nvm already installed"
fi

# ----------------------------
# Load nvm (nounset-safe)
# ----------------------------
export NVM_DIR="$HOME/.nvm"

# nvm is not fully nounset-safe in all code paths
set +u
# shellcheck disable=SC1090
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
# shellcheck disable=SC1090
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
set -u 2>/dev/null || true

log "[*] Verifying nvm..."
command -v nvm >/dev/null || {
  log "[!] nvm not found in PATH (did nvm.sh load correctly?)"
  exit 1
}

# ----------------------------
# Install + use Node LTS
# ----------------------------
log "[*] Installing Node.js LTS..."
# Extra robust: keep nounset off while running nvm commands
set +u
nvm install --lts
nvm use --lts
set -u 2>/dev/null || true

log "[*] Node and npm versions:"
node -v
npm -v

# ----------------------------
# npm defaults (safe + useful)
# ----------------------------
log "[*] Applying npm defaults..."
npm config set fund false
npm config set audit true
npm config set save-prefix '~'

# Ensure we are NOT using a custom prefix with nvm (avoid conflicts)
if npm config get prefix 2>/dev/null | grep -q "\.npm-global"; then
  log "[*] Removing npm custom prefix (nvm prefers its own prefix)..."
  npm config delete prefix || true
fi

# ----------------------------
# Verification
# ----------------------------
log ""
log "====== VERIFICATION ======"
log "node path:"
command -v node || true
log "node -v: $(node -v)"
log "npm -v:  $(npm -v)"
log ""
log "npm prefix:"
npm config get prefix
log ""
log "npm config list:"
npm config list
log ""
log "[✓] Installation complete"
log "Tip: open a new terminal or run: source ~/.bashrc"
