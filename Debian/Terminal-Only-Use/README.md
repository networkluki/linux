# Debian Terminal-Only Base

### 1. Core
This repository contains automated scripts to convert a standard Debian 13 (Trixie) Desktop installation into a minimal, headless terminal server. 
The system is completely stripped of the graphical user interface (GNOME) and subsequently provisioned with essential command-line tools optimized for development and system operations.

### 2. Technicals deep
The conversion and provisioning process is split into two primary scripts:

* **`debian-terminal-only.sh`**: A state-aware two-phase script requiring root privileges.
    * **Phase 1**: Configures `/etc/apt/sources.list` for Debian Trixie, sets the GRUB timeout to 0, changes the systemd default target to `multi-user.target`, installs `openssh-server` and `ufw`, explicitly allows SSH traffic, and initiates an automatic reboot.
    * **Phase 2**: Executed after the reboot. The script uninstalls GNOME metapackages, the GDM3 display manager, and all graphical applications. It replaces `pinentry-gnome3` with `pinentry-curses` and cleans user home directories of desktop-related cache files and standard XDG directories.
* **`install-terminal-base.sh`**: A provisioning script for the terminal environment. It verifies OS compatibility, validates package availability via `apt-cache`, and installs core tools (`tmux`, `fzf`, `ripgrep`, `jq`, `micro`) as well as operational tools (`nftables`, `fail2ban`, `wireguard-tools`) without installing recommended GUI dependencies (`--no-install-recommends`). The script also applies an `fd` alias pointing to `fdfind` in the target user's `~/.bashrc`.

### 3. Practical example
Execution must follow this strict chronological sequence to ensure system stability.

```bash
# 1. Make the scripts executable
chmod +x debian-terminal-only.sh install-terminal-base.sh

# 2. Execute OS conversion (Phase 1)
# WARNING: The system will automatically reboot at the end of this step.
sudo ./debian-terminal-only.sh

# 3. Complete OS conversion (Phase 2)
# After the system has rebooted into the TTY terminal (or via SSH), run the script again.
sudo ./debian-terminal-only.sh

# 4. Provision terminal tools
# Run as a normal sudo-capable user to ensure ~/.bashrc is updated for the correct profile.
# To include 'btop', set the environment variable INSTALL_BTOP=1.
INSTALL_BTOP=1 bash install-terminal-base.sh

# 5. Reload bashrc
source ~/.bashrc
