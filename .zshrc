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

# Syntax highlighting - must be last in this file!
# https://github.com/zsh-users/zsh-syntax-highlighting
source $HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
