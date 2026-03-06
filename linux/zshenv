# Linux zshenv - sourced for all zsh shells (interactive and non-interactive)
# Use for environment variables and PATH that should be available everywhere

# ------------------------------------------------------------------------------
# Environment
# ------------------------------------------------------------------------------

export LANG='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'
export BAT_THEME="Catppuccin Frappe"

# ------------------------------------------------------------------------------
# PATH
# ------------------------------------------------------------------------------

path=(
    "$HOME/.local/bin"
    "$HOME/.dotfiles/bin"
    "/usr/local/bin"
    ${path}
)
typeset -U path
export PATH

# ------------------------------------------------------------------------------
# bun
# ------------------------------------------------------------------------------

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
