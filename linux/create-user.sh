#!/bin/bash
set -euo pipefail

# Create User Script (Debian/Ubuntu)
# Creates a sudo user and copies root's SSH key for key-based authentication
# Usage: Run as root: bash create-user.sh <username>

# ------------------------------------------------------------------------------
# Utility functions
# ------------------------------------------------------------------------------

e_header() {
    printf "\n\033[1;37m%s\033[0m\n" "$@"
}

e_success() {
    printf "\033[0;32m+ %s\033[0m\n" "$@"
}

e_error() {
    printf "\033[0;31m! %s\033[0m\n" "$@"
}

e_warning() {
    printf "\033[0;33m! %s\033[0m\n" "$@"
}

# ------------------------------------------------------------------------------
# Pre-flight checks
# ------------------------------------------------------------------------------

if [[ $EUID -ne 0 ]]; then
    e_error "This script must be run as root"
    exit 1
fi

if [[ $# -ne 1 ]]; then
    e_error "Usage: $0 <username>"
    exit 1
fi

USERNAME="$1"

if id "$USERNAME" &>/dev/null; then
    e_error "User '$USERNAME' already exists"
    exit 1
fi

# ------------------------------------------------------------------------------
# Ensure sudo is installed
# ------------------------------------------------------------------------------

e_header "Checking for sudo..."

if ! command -v sudo &>/dev/null; then
    e_warning "sudo not found, installing..."
    apt-get update -qq && apt-get install -y sudo
    e_success "sudo installed"
else
    e_success "sudo is already installed"
fi

# ------------------------------------------------------------------------------
# Create user
# ------------------------------------------------------------------------------

e_header "Creating user '$USERNAME'..."

adduser --gecos "" "$USERNAME"
e_success "User '$USERNAME' created"

# ------------------------------------------------------------------------------
# Add user to sudo group
# ------------------------------------------------------------------------------

e_header "Adding '$USERNAME' to sudo group..."

usermod -aG sudo "$USERNAME"
e_success "User added to sudo group"

# ------------------------------------------------------------------------------
# Copy SSH key from root
# ------------------------------------------------------------------------------

e_header "Setting up SSH key authentication..."

ROOT_AUTH_KEYS="/root/.ssh/authorized_keys"
USER_SSH_DIR="/home/$USERNAME/.ssh"
USER_AUTH_KEYS="$USER_SSH_DIR/authorized_keys"

if [[ -f "$ROOT_AUTH_KEYS" ]] && [[ -s "$ROOT_AUTH_KEYS" ]]; then
    mkdir -p "$USER_SSH_DIR"
    cp "$ROOT_AUTH_KEYS" "$USER_AUTH_KEYS"
    chmod 700 "$USER_SSH_DIR"
    chmod 600 "$USER_AUTH_KEYS"
    chown -R "$USERNAME:$USERNAME" "$USER_SSH_DIR"
    e_success "Copied SSH authorized_keys from root"
else
    e_warning "No SSH keys found in /root/.ssh/authorized_keys"
    e_warning "You will need to manually add SSH keys for '$USERNAME'"
    mkdir -p "$USER_SSH_DIR"
    touch "$USER_AUTH_KEYS"
    chmod 700 "$USER_SSH_DIR"
    chmod 600 "$USER_AUTH_KEYS"
    chown -R "$USERNAME:$USERNAME" "$USER_SSH_DIR"
fi

# ------------------------------------------------------------------------------
# Done
# ------------------------------------------------------------------------------

e_header "User setup complete!"
echo ""
echo "Next steps:"
echo "  1. KEEP THIS ROOT SESSION OPEN"
echo "  2. In a NEW terminal, test SSH login:"
echo "     ssh $USERNAME@<server-ip>"
echo "  3. Test sudo access:"
echo "     sudo whoami  (should print: root)"
echo "  4. Once confirmed working, run harden-ssh.sh to disable root login"
echo ""
