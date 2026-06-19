# tmux Command Guide

A practical guide to `tmux` for terminal workflows, Linux servers, SSH sessions, and persistent shell environments.

## What is tmux?

`tmux` is a terminal multiplexer. It lets you:

- run multiple shells inside one terminal
- split the terminal into panes
- create multiple windows inside one session
- keep processes running after disconnecting from SSH
- reattach to the same session later

This is especially useful for:

- Linux servers
- development workflows
- log monitoring
- long-running scripts
- SSH administration

---

## Installation

### Linux
```bash
sudo apt update
sudo apt install tmux
