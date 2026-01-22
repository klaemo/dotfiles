#!/bin/bash
set -euo pipefail

# Tailscale + UFW Setup Script (Debian/Ubuntu)
# Installs Tailscale, brings it up, and configures UFW.
# Usage: sudo bash setup-tailscale.sh

# ------------------------------------------------------------------------------
# Utility functions
# ------------------------------------------------------------------------------

e_header() {
    printf "\n\033[1;37m%s\033[0m\n" "$@"
}

e_success() {
    printf "\033[0;32m✓ %s\033[0m\n" "$@"
}

e_error() {
    printf "\033[0;31m✗ %s\033[0m\n" "$@"
}

e_warning() {
    printf "\033[0;33m! %s\033[0m\n" "$@"
}

command_exists() {
    command -v "$1" &>/dev/null
}

# ------------------------------------------------------------------------------
# Pre-flight checks
# ------------------------------------------------------------------------------

if [[ $EUID -ne 0 ]]; then
    e_error "This script must be run as root (use sudo)"
    exit 1
fi

if [[ ! -f /etc/os-release ]]; then
    e_error "Cannot detect OS. /etc/os-release not found."
    exit 1
fi

source /etc/os-release
if [[ "${ID:-}" != "ubuntu" && "${ID_LIKE:-}" != *"debian"* ]]; then
    e_warning "This script is designed for Ubuntu/Debian. Detected: ${ID:-unknown}"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
fi

if ! command_exists curl; then
    e_header "Installing curl..."
    apt-get update -qq
    apt-get install -y curl
fi

e_success "Pre-flight checks passed (${PRETTY_NAME:-Linux})"

# ------------------------------------------------------------------------------
# Install and start Tailscale
# ------------------------------------------------------------------------------

if ! command_exists tailscale; then
    e_header "Installing Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
    e_success "Tailscale installed"
else
    e_success "Tailscale already installed"
fi

if command_exists systemctl; then
    systemctl enable --now tailscaled >/dev/null 2>&1 || true
fi

if ! tailscale status >/dev/null 2>&1; then
    e_header "Bringing Tailscale up..."
    tailscale up
    e_success "Tailscale is connected"
else
    e_success "Tailscale already running"
fi

# ------------------------------------------------------------------------------
# Configure UFW
# ------------------------------------------------------------------------------

if ! command_exists ufw; then
    e_header "Installing ufw..."
    apt-get update -qq
    apt-get install -y ufw
    e_success "ufw installed"
fi

e_header "Configuring ufw defaults..."
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
e_success "ufw defaults set"

e_header "Allowing SSH and Tailscale traffic..."
ufw allow 22/tcp
ufw allow in on tailscale0
e_success "Firewall rules updated"

e_header "Reloading ufw and SSH..."
ufw reload
systemctl restart ssh
e_success "ufw reloaded and SSH restarted"

# ------------------------------------------------------------------------------
# Done
# ------------------------------------------------------------------------------

e_header "Tailscale + ufw setup complete!"
echo ""
echo "Notes:"
echo "  - SSH is allowed from anywhere and on tailscale0"
echo "  - Default incoming policy is deny"
echo "  - Check status with: sudo ufw status verbose"
echo ""
