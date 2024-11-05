if [ -d "/opt/homebrew" ]; then
  # Homebrew
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Prompt
# https://github.com/sindresorhus/pure
fpath+=("$HOMEBREW_PREFIX/share/zsh/site-functions")
autoload -U promptinit
promptinit
prompt pure

# Completions
fpath+=$HOME/.zsh
autoload -Uz compinit
compinit -u

# Options
# https://scriptingosx.com/2019/06/moving-to-zsh-part-3-shell-options/
setopt NO_CASE_GLOB # case-insensitive globbing
setopt AUTO_CD # change directories without `cd` (like `...`)
setopt EXTENDED_HISTORY
setopt SHARE_HISTORY # share history across multiple zsh sessions
setopt APPEND_HISTORY # append to history
setopt HIST_IGNORE_DUPS # do not store duplicates
setopt HIST_REDUCE_BLANKS # removes blank lines from history
setopt CORRECT
# setopt CORRECT_ALL

# case insensitive path-completion
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*'

bindkey '^[[A' up-line-or-search # search history on up arrow
bindkey '^[[B' down-line-or-search # search history on down arrow

# Preview file content using bat (https://github.com/sharkdp/bat)
export FZF_CTRL_T_OPTS="
  --preview 'bat -n --color=always {}'"

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

# Prefer US English and use UTF-8.
export LANG='en_US.UTF-8';
export LC_ALL='en_US.UTF-8';

# Highlight section titles in manual pages.
export LESS_TERMCAP_md=$(tput setaf 136);

# Hide brew env hints
export HOMEBREW_NO_ENV_HINTS=true

export VOLTA_HOME="$HOME/.volta";

path=(
  "$VOLTA_HOME/bin"         # Highest priority
  "/usr/local/bin"
  ${path}                   # Existing paths
)
typeset -U path             # Remove duplicates
export PATH

# ~/.zsh_extra can be used for other settings you don’t want to commit.
if [[ -a ${HOME}/.zsh_extra ]]; then
  source "$HOME/.zsh_extra";
fi

# aliases
[[ -f ~/.aliases ]] && source ~/.aliases

# Syntax highlighting - must be last in this file!
# https://github.com/zsh-users/zsh-syntax-highlighting
source $HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
