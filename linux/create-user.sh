#!/bin/bash
set -euo pipefail

# Create User Script (Debian/Ubuntu)
# Creates a user and copies root's SSH key for key-based authentication
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
# Choose sudo access
# ------------------------------------------------------------------------------

e_header "Grant sudo access to '$USERNAME'?"
read -r -p "Add user to sudo group? [Y/n]: " GRANT_SUDO_INPUT
GRANT_SUDO_INPUT="${GRANT_SUDO_INPUT:-Y}"

case "$GRANT_SUDO_INPUT" in
    [Yy]|[Yy][Ee][Ss])
        GRANT_SUDO="yes"
        ;;
    [Nn]|[Nn][Oo])
        GRANT_SUDO="no"
        ;;
    *)
        e_error "Invalid choice. Please answer y or n."
        exit 1
        ;;
esac

# ------------------------------------------------------------------------------
# Create user
# ------------------------------------------------------------------------------

e_header "Creating user '$USERNAME'..."

adduser --gecos "" "$USERNAME"
e_success "User '$USERNAME' created"

# ------------------------------------------------------------------------------
# Add user to sudo group (optional)
# ------------------------------------------------------------------------------

if [[ "$GRANT_SUDO" == "yes" ]]; then
    e_header "Adding '$USERNAME' to sudo group..."

    usermod -aG sudo "$USERNAME"
    e_success "User added to sudo group"
else
    e_success "Skipping sudo group assignment"
fi

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
if [[ "$GRANT_SUDO" == "yes" ]]; then
    echo "  3. Test sudo access:"
    echo "     sudo whoami  (should print: root)"
    echo "  4. Once confirmed working, run harden-ssh.sh to disable root login"
else
    echo "  3. Once confirmed working, run harden-ssh.sh to disable root login"
fi
echo ""
