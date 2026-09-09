# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

export CLICOLOR=1

# Homebrew (Apple Silicon) — puts brew + brew-installed tools on PATH
eval "$(/opt/homebrew/bin/brew shellenv)"

plugins=(git)

# Preferred editor
export EDITOR='nvim'

alias pint-run='./vendor/bin/pint -v'
alias lzg='lazygit'

source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# --- Laravel Herd (legacy) -------------------------------------------------
# Replaced by mise (node + php managed below). Kept commented during the
# transition — safe to delete once mise is confirmed working.
# export PATH="/Users/cameron/.config/herd-lite/bin:$PATH"
# export PHP_INI_SCAN_DIR="/Users/cameron/.config/herd-lite/bin:$PHP_INI_SCAN_DIR"
# export HERD_PHP_84_INI_SCAN_DIR="/Users/cameron/Library/Application Support/Herd/config/php/84/"
# export HERD_PHP_85_INI_SCAN_DIR="/Users/cameron/Library/Application Support/Herd/config/php/85/"
# export NVM_DIR="/Users/cameron/Library/Application Support/Herd/config/nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
# [[ -f "/Applications/Herd.app/Contents/Resources/config/shell/zshrc.zsh" ]] && builtin source "/Applications/Herd.app/Contents/Resources/config/shell/zshrc.zsh"
# export PATH="/Users/cameron/Library/Application Support/Herd/bin/":$PATH
# ---------------------------------------------------------------------------

autoload -Uz compinit
compinit

# Composer global bin (composer is installed via mise once php is present)
export PATH="$PATH:$HOME/.composer/vendor/bin"

# mise — manages node, php, and any other language runtimes
eval "$(mise activate zsh)"

# starship prompt
eval "$(starship init zsh)"
