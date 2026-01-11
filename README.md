## Linux management

### Install Node.js with nvm

This repo includes `nvm.sh` to install and configure Node.js via **nvm (Node Version Manager)**.  
This is a good way to install Node.js because:

- **Per-user isolation**: nvm installs Node in your home directory, reducing conflicts with system packages.
- **Easy version switching**: quickly switch between Node versions (e.g. LTS) without reinstalling.
- **Reproducible environments**: everyone can use the same LTS version and npm configuration.
- **Safe upgrades**: nvm makes it easy to upgrade without touching the system package manager.

---

### Why install this?

Many modern tools and scripts require a stable Node.js environment.  
Using nvm provides a controlled, predictable installation that is easy to update and troubleshoot.

---

### Commands

Make the script executable and run it:

```bash
chmod +x nvm.sh
./nvm.sh
