# AGENTS.md - Dotfiles Repository

Guidelines for AI coding agents working in this repository.

## Repository Overview

Personal dotfiles repository for macOS (primary) and Linux/Ubuntu (secondary). Manages shell environment, package installation, and application settings.

**Entry Points:** `bin/dotfiles` (macOS), `linux/setup.sh` (Linux), `lib/` (shared functions)

## Commands

### macOS
```bash
dotfiles                # Full update (sync + packages)
dotfiles --no-packages  # Sync dotfiles only
dotfiles --no-sync      # Update packages only
dotfiles -h             # Help
```

### Linux
```bash
bash ~/.dotfiles/linux/create-user.sh <username>  # Create sudo user (run as root)
sudo bash ~/.dotfiles/linux/harden-ssh.sh         # Harden SSH
bash ~/.dotfiles/linux/setup.sh                   # Install packages and dotfiles
```

### Testing

**No automated tests.** Verify manually: run setup script, check symlinks, verify packages install, source `.zshrc`.
