export VOLTA_HOME="$HOME/.volta";
export PATH="$VOLTA_HOME/bin:$PATH";

export EDITOR='code -n -w';

# Prefer US English and use UTF-8.
export LANG='en_US.UTF-8';
export LC_ALL='en_US.UTF-8';

# Highlight section titles in manual pages.
export LESS_TERMCAP_md=$(tput setaf 136);

# ~/.zsh_extra can be used for other settings you don’t want to commit.
if [[ -a ${HOME}/.zsh_extra ]]; then
  source "$HOME/.zsh_extra";
fi
