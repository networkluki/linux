#!/usr/bin/env bash
# debian-terminal-only.sh
# Converts a fresh Debian Trixie desktop install to a terminal-only server.
# Run as root or with sudo. Requires a reboot midway (handled automatically).
#
# WARNING: This REMOVES the entire GNOME desktop environment.
# Make sure you have SSH access or physical console before running.

set -euo pipefail

LOGFILE="/var/log/debian-terminal-only.log"
exec > >(tee -a "$LOGFILE") 2>&1

# --- Guard: must be root ---
if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Run this script as root (sudo $0)" >&2
    exit 1
fi

# --- State file for two-phase execution ---
STATE_FILE="/var/tmp/.debian-terminal-only-phase"
PHASE=$(cat "$STATE_FILE" 2>/dev/null || echo "1")

# ============================================================
# PHASE 1: sources.list, grub, default target, base packages
# ============================================================
if [[ "$PHASE" == "1" ]]; then
    echo "=== Phase 1: Base configuration ==="

    # --- Fix sources.list ---
    cat > /etc/apt/sources.list <<'EOF'
deb http://deb.debian.org/debian/ trixie main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian/ trixie main contrib non-free non-free-firmware

deb http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
deb-src http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware

deb http://deb.debian.org/debian/ trixie-updates main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian/ trixie-updates main contrib non-free non-free-firmware
EOF
    echo "sources.list written."

    apt-get update
    apt-get -y dist-upgrade

    # --- GRUB: zero timeout (no menu delay) ---
    sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
    update-grub

    # --- Default to multi-user (no GUI) ---
    systemctl set-default multi-user.target

    # --- Install essential server packages ---
    apt-get install -y ufw openssh-server screenfetch net-tools

    # --- Enable firewall with SSH allowed ---
    ufw allow OpenSSH
    ufw --force enable

    # --- Ensure sshd is running ---
    systemctl enable --now ssh

    # --- Mark phase 2 and reboot ---
    echo "2" > "$STATE_FILE"

    echo ""
    echo "=== Phase 1 complete. Rebooting into multi-user target. ==="
    echo "After reboot, log in via console/SSH and run this script again."
    echo ""
    sleep 3
    reboot
fi

# ============================================================
# PHASE 2: Strip GNOME and all GUI packages
# ============================================================
if [[ "$PHASE" == "2" ]]; then
    echo "=== Phase 2: Removing GNOME desktop ==="

    # Stop display manager if still running
    systemctl disable --now gdm3 2>/dev/null || true

    # --- Remove GNOME meta-packages and shell ---
    apt-get purge -y \
        task-gnome-desktop \
        gnome-core \
        gnome \
        gnome-shell \
        gdm3 \
        2>/dev/null || true

    # --- Remove individual GNOME apps ---
    apt-get purge -y \
        gnome-backgrounds \
        gnome-bluetooth-sendto \
        gnome-calculator \
        gnome-calendar \
        gnome-characters \
        gnome-clocks \
        gnome-connections \
        gnome-contacts \
        gnome-control-center \
        gnome-disk-utility \
        gnome-font-viewer \
        gnome-logs \
        gnome-maps \
        gnome-menus \
        gnome-music \
        gnome-remote-desktop \
        gnome-settings-daemon \
        gnome-snapshot \
        gnome-software \
        gnome-sound-recorder \
        gnome-sushi \
        gnome-system-monitor \
        gnome-terminal \
        gnome-text-editor \
        gnome-tour \
        gnome-tweaks \
        gnome-user-docs \
        gnome-user-share \
        gnome-weather \
        libreoffice-gnome \
        nautilus \
        2>/dev/null || true

    apt-get autoremove --purge -y

    # --- Replace gnome-keyring / pinentry with curses variants ---
    apt-get install -y pinentry-curses
    update-alternatives --set pinentry /usr/bin/pinentry-curses 2>/dev/null || true

    apt-get purge -y \
        gnome-keyring \
        gnome-keyring-pkcs11 \
        libpam-gnome-keyring \
        pinentry-gnome3 \
        gnome-desktop3-data \
        libgnome-autoar-0-0 \
        libgnome-autoar-gtk-0-0 \
        libgnome-desktop-3-20t64 \
        2>/dev/null || true

    apt-get autoremove --purge -y

    # --- Final cleanup ---
    apt-get clean

    # --- Clean up home directories for all non-root human users ---
    getent passwd | awk -F: '$3 >= 1000 && $3 < 65534 { print $6 }' | while read -r HOMEDIR; do
        [[ -d "$HOMEDIR" ]] || continue
        echo "Cleaning home directory: $HOMEDIR"

        rm -f "$HOMEDIR/.face" "$HOMEDIR/.face.icon"
        rm -rf "$HOMEDIR/.cache/"*

        rmdir "$HOMEDIR/Desktop" "$HOMEDIR/Documents" "$HOMEDIR/Downloads" \
              "$HOMEDIR/Music" "$HOMEDIR/Pictures" "$HOMEDIR/Public" \
              "$HOMEDIR/Templates" "$HOMEDIR/Videos" 2>/dev/null || true

        # Remove GNOME config remnants
        find "$HOMEDIR/.config" "$HOMEDIR/.local" -maxdepth 3 \
            \( -iname '*gnome*' -o -iname '*nautilus*' -o -iname '*gdm*' \) \
            -exec rm -rf {} + 2>/dev/null || true
    done

    # --- Remove state file ---
    rm -f "$STATE_FILE"

    echo ""
    echo "=== Phase 2 complete. ==="
    echo ""
    echo "Verification:"
    echo "  Default target : $(systemctl get-default)"
    echo "  Display manager: $(systemctl is-active display-manager 2>/dev/null || echo 'inactive')"
    echo "  Memory usage   :"
    free -h
    echo ""
    echo "  Remaining GNOME packages (should be minimal/empty):"
    dpkg -l | grep -iE 'gnome|gdm' | grep '^ii' || echo "  (none)"
    echo ""
    echo "Reboot recommended: sudo reboot"
fi
