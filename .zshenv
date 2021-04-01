export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

export EDITOR='code -n -w'

# ~/.zsh_extra can be used for other settings you don’t want to commit.
if [[ ! -a ${HOME}/.zsh_extra ]]; then
  source "$HOME/.zsh_extra"
fi
