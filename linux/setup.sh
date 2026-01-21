#!/bin/bash
set -euo pipefail

# Linux Server Setup Script
# Tested on Ubuntu 24.04
# Usage: bash ~/.dotfiles/linux/setup.sh

DOTFILES_DIR="${HOME}/.dotfiles"
LINUX_DIR="${DOTFILES_DIR}/linux"

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

e_header "Running pre-flight checks..."

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

if ! command_exists sudo; then
    e_error "sudo is required but not installed."
    exit 1
fi

e_success "Pre-flight checks passed (${PRETTY_NAME:-Linux})"

# ------------------------------------------------------------------------------
# Enable Ubuntu backports repository
# ------------------------------------------------------------------------------

e_header "Enabling Ubuntu backports repository..."

if [[ "${ID:-}" == "ubuntu" ]]; then
    CODENAME="${VERSION_CODENAME:-$(lsb_release -cs 2>/dev/null || echo '')}"
    if [[ -n "${CODENAME}" ]]; then
        BACKPORTS_SOURCE="/etc/apt/sources.list.d/ubuntu-backports.sources"
        if ! grep -rq "${CODENAME}-backports" /etc/apt/sources.list.d/ 2>/dev/null && \
           ! grep -q "${CODENAME}-backports" /etc/apt/sources.list 2>/dev/null; then
            sudo tee "${BACKPORTS_SOURCE}" >/dev/null <<EOF
Types: deb
URIs: http://archive.ubuntu.com/ubuntu
Suites: ${CODENAME}-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF
            e_success "Ubuntu backports repository enabled (${CODENAME}-backports)"
        else
            e_success "Ubuntu backports repository already enabled"
        fi
    else
        e_warning "Could not determine Ubuntu codename, skipping backports setup"
    fi
else
    e_warning "Not Ubuntu, skipping backports repository setup"
fi

# ------------------------------------------------------------------------------
# Install packages via apt
# ------------------------------------------------------------------------------

e_header "Updating apt and installing packages..."

sudo apt-get update -qq

# Core packages (mapped from Homebrew desired_formulae)
APT_PACKAGES=(
    bat
    curl
    fzf
    gh
    git
    htop
    httpie
    rsync
    unzip
    wget
    zsh
    zsh-syntax-highlighting
)

sudo apt-get install -y "${APT_PACKAGES[@]}"
e_success "Core apt packages installed"

# ------------------------------------------------------------------------------
# Install/Update AWS CLI v2 (official installer)
# ------------------------------------------------------------------------------

e_header "Installing/updating AWS CLI v2..."
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
if command_exists aws; then
    sudo /tmp/aws/install --update
    e_success "AWS CLI v2 updated"
else
    sudo /tmp/aws/install
    e_success "AWS CLI v2 installed"
fi
rm -rf /tmp/awscliv2.zip /tmp/aws

# ------------------------------------------------------------------------------
# Handle bat -> batcat symlink (Ubuntu names it batcat)
# ------------------------------------------------------------------------------

if command_exists batcat && ! command_exists bat; then
    mkdir -p "${HOME}/.local/bin"
    ln -sf "$(which batcat)" "${HOME}/.local/bin/bat"
    e_success "Created bat symlink for batcat"
fi

# ------------------------------------------------------------------------------
# Install lazygit (not in Ubuntu repos by default)
# ------------------------------------------------------------------------------

if ! command_exists lazygit; then
    e_header "Installing lazygit from GitHub releases..."
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    mkdir -p "${HOME}/.local/bin"
    tar xf /tmp/lazygit.tar.gz -C "${HOME}/.local/bin" lazygit
    rm /tmp/lazygit.tar.gz
    e_success "lazygit installed to ~/.local/bin"
else
    e_success "lazygit already installed"
fi

# ------------------------------------------------------------------------------
# Install zellij (not in Ubuntu repos by default)
# ------------------------------------------------------------------------------

if ! command_exists zellij; then
    e_header "Installing zellij from GitHub releases..."
    ZELLIJ_VERSION=$(curl -s "https://api.github.com/repos/zellij-org/zellij/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo /tmp/zellij.tar.gz "https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz"
    mkdir -p "${HOME}/.local/bin"
    tar xf /tmp/zellij.tar.gz -C "${HOME}/.local/bin"
    rm /tmp/zellij.tar.gz
    e_success "zellij installed to ~/.local/bin"
else
    e_success "zellij already installed"
fi

# ------------------------------------------------------------------------------
# Install pure prompt
# ------------------------------------------------------------------------------

PURE_DIR="${HOME}/.zsh/pure"
if [[ ! -d "${PURE_DIR}" ]]; then
    e_header "Installing pure prompt..."
    mkdir -p "${HOME}/.zsh"
    git clone https://github.com/sindresorhus/pure.git "${PURE_DIR}"
    e_success "pure prompt installed"
else
    e_success "pure prompt already installed"
fi

# ------------------------------------------------------------------------------
# Set zsh as default shell
# ------------------------------------------------------------------------------

e_header "Setting zsh as default shell..."

ZSH_PATH=$(which zsh)
if [[ "${SHELL}" != "${ZSH_PATH}" ]]; then
    if ! grep -q "${ZSH_PATH}" /etc/shells; then
        e_warning "zsh not in /etc/shells, adding..."
        echo "${ZSH_PATH}" | sudo tee -a /etc/shells
    fi
    sudo chsh -s "${ZSH_PATH}" "${USER}"
    e_success "Default shell changed to zsh (will take effect on next login)"
else
    e_success "zsh is already the default shell"
fi

# ------------------------------------------------------------------------------
# Link dotfiles
# ------------------------------------------------------------------------------

e_header "Linking dotfiles..."

mkdir -p "${HOME}/.zsh"
mkdir -p "${HOME}/.config"

# Symlink zshrc
ln -sf "${LINUX_DIR}/zshrc" "${HOME}/.zshrc"
e_success "Linked ~/.zshrc"

# Symlink aliases
ln -sf "${LINUX_DIR}/aliases" "${HOME}/.aliases"
e_success "Linked ~/.aliases"

# Copy zellij config (use Linux-specific layout)
rsync -avz --quiet "${DOTFILES_DIR}/settings/zellij/" "${HOME}/.config/zellij/"
# Overwrite the dev layout with Linux version
cp "${LINUX_DIR}/settings/zellij/layouts/dev.kdl" "${HOME}/.config/zellij/layouts/dev.kdl"
e_success "Copied zellij config"

# Copy bat config
rsync -avz --quiet "${DOTFILES_DIR}/settings/bat/" "${HOME}/.config/bat/"
e_success "Copied bat config"

# Link other dotfiles
for file in .gitconfig .gitattributes .gitignore .wgetrc .inputrc; do
    if [[ -f "${DOTFILES_DIR}/${file}" ]]; then
        ln -sf "${DOTFILES_DIR}/${file}" "${HOME}/${file}"
        e_success "Linked ~/${file}"
    fi
done

# ------------------------------------------------------------------------------
# Rebuild bat cache (for themes)
# ------------------------------------------------------------------------------

if command_exists bat; then
    e_header "Rebuilding bat cache..."
    bat cache --build &>/dev/null || true
    e_success "bat cache rebuilt"
fi

# ------------------------------------------------------------------------------
# Install volta (Node.js version manager)
# ------------------------------------------------------------------------------

if ! command_exists volta; then
    e_header "Installing volta..."
    curl https://get.volta.sh | bash -s -- --skip-setup
    e_success "volta installed"
    
    # Generate completions
    if [[ -x "${HOME}/.volta/bin/volta" ]]; then
        "${HOME}/.volta/bin/volta" completions -o "${HOME}/.zsh/_volta" zsh 2>/dev/null || true
    fi
else
    e_success "volta already installed"
fi

# ------------------------------------------------------------------------------
# Install opencode
# ------------------------------------------------------------------------------

if ! command_exists opencode; then
    e_header "Installing opencode..."
    curl -fsSL https://opencode.ai/install | bash
    e_success "opencode installed"
else
    e_success "opencode already installed"
fi

# ------------------------------------------------------------------------------
# Verification
# ------------------------------------------------------------------------------

e_header "Verifying installation..."

TOOLS=(git zsh fzf bat aws lazygit zellij)
for tool in "${TOOLS[@]}"; do
    if command_exists "$tool"; then
        e_success "$tool is available"
    else
        e_warning "$tool not found in PATH"
    fi
done

# ------------------------------------------------------------------------------
# Done
# ------------------------------------------------------------------------------

e_header "Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Log out and back in (or run 'exec zsh') to use zsh"
echo "  2. Add any custom config to ~/.zsh_extra"
echo ""
