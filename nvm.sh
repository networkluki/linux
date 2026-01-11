#!/usr/bin/env bash
set -euo pipefail

echo "[*] Installing nvm..."
if [ ! -d "$HOME/.nvm" ]; then
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
else
  echo "[i] nvm already installed"
fi

# Load nvm
export NVM_DIR="$HOME/.nvm"

[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

echo "[*] Verifying nvm..."
command -v nvm >/dev/null || {
  echo "[!] nvm not found in PATH"
  exit 1
}

echo "[*] Installing Node.js LTS..."
nvm install --lts
nvm use --lts

echo "[*] Node and npm versions:"
node -v
npm -v

############################################
# npm configuration
############################################

echo "[*] Creating npm-global directory (legacy step)..."
mkdir -p "$HOME/.npm-global"

echo "[*] Setting npm prefix (will be removed for nvm compatibility)..."
npm config set prefix "$HOME/.npm-global"

# Ensure PATH line exists (idempotent)
if ! grep -q 'npm-global/bin' "$HOME/.bashrc"; then
  echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$HOME/.bashrc"
fi

NODE_VERSION="$(node -v)"

echo "[*] Removing npm prefix for nvm compatibility (Node $NODE_VERSION)..."
nvm use --delete-prefix "$NODE_VERSION" --silent

############################################
# npm defaults
############################################

echo "[*] Applying npm defaults..."
npm config set fund false
npm config set audit true
npm config set save-prefix='~'

############################################
# Verification
############################################

echo
echo "====== VERIFICATION ======"
echo "npm prefix:"
npm config get prefix

echo
echo "npm config list:"
npm config list

echo
echo "[✓] Installation complete"
echo "Run command: source ~/.bashrc"
