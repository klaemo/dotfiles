#!/bin/bash
set -euo pipefail

# SSH Hardening Script (Debian/Ubuntu)
# Disables root login and password authentication
# Usage: sudo bash harden-ssh.sh

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
    e_error "This script must be run as root (use sudo)"
    exit 1
fi

SSHD_CONFIG="/etc/ssh/sshd_config"

if [[ ! -f "$SSHD_CONFIG" ]]; then
    e_error "SSH config not found at $SSHD_CONFIG"
    exit 1
fi

# Check we're not logged in as root via SSH
if [[ "${SUDO_USER:-root}" == "root" ]] && [[ -n "${SSH_CONNECTION:-}" ]]; then
    e_error "You appear to be logged in as root via SSH."
    e_error "Please login as your regular user and run this script with sudo."
    exit 1
fi

# ------------------------------------------------------------------------------
# Safety confirmation
# ------------------------------------------------------------------------------

e_header "SSH Hardening Script"
echo ""
echo "This script will:"
echo "  1. Disable root SSH login (PermitRootLogin no)"
echo "  2. Disable password authentication (PasswordAuthentication no)"
echo ""
e_warning "Make sure you have tested SSH key login for your regular user!"
echo ""
read -p "Have you confirmed SSH key login works for a non-root user? (yes/no): " CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
    e_error "Aborting. Please test SSH key login first."
    echo ""
    echo "Test with: ssh <username>@<server-ip>"
    echo "Then run: sudo whoami"
    exit 1
fi

# ------------------------------------------------------------------------------
# Backup existing config
# ------------------------------------------------------------------------------

e_header "Backing up SSH config..."

BACKUP_FILE="${SSHD_CONFIG}.backup.$(date +%Y%m%d%H%M%S)"
cp "$SSHD_CONFIG" "$BACKUP_FILE"
e_success "Backup created: $BACKUP_FILE"

# ------------------------------------------------------------------------------
# Helper function to set SSH config options
# ------------------------------------------------------------------------------

set_sshd_option() {
    local option="$1"
    local value="$2"
    local config_file="$3"
    
    if grep -qE "^#?\s*${option}\s+" "$config_file"; then
        # Option exists (possibly commented), replace it
        sed -i "s/^#*\s*${option}\s.*/${option} ${value}/" "$config_file"
    else
        # Option doesn't exist, append it
        echo "${option} ${value}" >> "$config_file"
    fi
}

# ------------------------------------------------------------------------------
# Harden SSH configuration
# ------------------------------------------------------------------------------

e_header "Hardening SSH configuration..."

# Disable root login
set_sshd_option "PermitRootLogin" "no" "$SSHD_CONFIG"
e_success "Disabled root login"

# Disable password authentication
set_sshd_option "PasswordAuthentication" "no" "$SSHD_CONFIG"
e_success "Disabled password authentication"

# Additional hardening
set_sshd_option "PermitEmptyPasswords" "no" "$SSHD_CONFIG"
e_success "Disabled empty passwords"

set_sshd_option "X11Forwarding" "no" "$SSHD_CONFIG"
e_success "Disabled X11 forwarding"

set_sshd_option "MaxAuthTries" "3" "$SSHD_CONFIG"
e_success "Limited auth tries to 3"

# ------------------------------------------------------------------------------
# Validate SSH configuration
# ------------------------------------------------------------------------------

e_header "Validating SSH configuration..."

if sshd -t 2>/dev/null; then
    e_success "SSH configuration is valid"
else
    e_error "SSH configuration is invalid!"
    e_warning "Restoring backup..."
    cp "$BACKUP_FILE" "$SSHD_CONFIG"
    e_success "Backup restored"
    exit 1
fi

# ------------------------------------------------------------------------------
# Reload SSH service
# ------------------------------------------------------------------------------

e_header "Reloading SSH service..."

# Debian/Ubuntu uses 'ssh' as the service name
if systemctl reload ssh 2>/dev/null; then
    e_success "SSH service reloaded"
else
    e_warning "Could not reload, trying restart..."
    systemctl restart ssh
    e_success "SSH service restarted"
fi

# ------------------------------------------------------------------------------
# Done
# ------------------------------------------------------------------------------

e_header "SSH hardening complete!"
echo ""
echo "Changes applied:"
echo "  - Root SSH login: DISABLED"
echo "  - Password authentication: DISABLED"
echo "  - Empty passwords: DISABLED"
echo "  - X11 forwarding: DISABLED"
echo "  - Max auth tries: 3"
echo ""
echo "Backup saved to: $BACKUP_FILE"
echo ""
e_warning "DO NOT close this session until you verify you can still connect!"
echo ""
echo "In a NEW terminal, test your connection:"
echo "  ssh <username>@<server-ip>"
echo ""
