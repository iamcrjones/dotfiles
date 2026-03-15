# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH
export PATH="/Users/cameron/.config/herd-lite/bin:$PATH"
export PHP_INI_SCAN_DIR="/Users/cameron/.config/herd-lite/bin:$PHP_INI_SCAN_DIR"
export CLICOLOR=1

export BREW="/opt/homebrew/bin:$PATH"

plugins=(git)

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
  export EDITOR='nvim'
# fi

alias pint-run='./vendor/bin/pint -v'
alias lzd='lazydocker'
alias lzg='lazygit'

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Herd injected PHP 8.4 configuration.
export HERD_PHP_84_INI_SCAN_DIR="/Users/cameron/Library/Application Support/Herd/config/php/84/"


# Herd injected NVM configuration
export NVM_DIR="/Users/cameron/Library/Application Support/Herd/config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

[[ -f "/Applications/Herd.app/Contents/Resources/config/shell/zshrc.zsh" ]] && builtin source "/Applications/Herd.app/Contents/Resources/config/shell/zshrc.zsh"

# Herd injected PHP binary.
export PATH="/Users/cameron/Library/Application Support/Herd/bin/":$PATH
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/cameron/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions
# export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"


# Herd injected PHP 8.5 configuration.
export HERD_PHP_85_INI_SCAN_DIR="/Users/cameron/Library/Application Support/Herd/config/php/85/"

export PATH="$PATH:$HOME/.composer/vendor/bin"
eval "$(~/.local/bin/mise activate)"
eval "$(starship init zsh)"
