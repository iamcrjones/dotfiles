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

# Composer global bin (Composer is bundled with php via the verzly/mise-php plugin)
export PATH="$PATH:$HOME/.config/composer/vendor/bin"

# mise — manages node, php, and any other language runtimes
eval "$(mise activate zsh)"

# --- Dev environment: tmux session per repo --------------------------------
# Repos to spin up a tmux dev session for. Each session is named after the
# target directory (e.g. ~/Code/some-repo -> "some-repo"). Edit this list freely.
DEV_REPOS=(
)

# dev.exe — loop over $DEV_REPOS (or the paths passed as args) and create one
# detached tmux session per repo, each with a "dev mode" three-pane layout
# (nvim up top, two shells below). Skips repos that are missing or already
# have a session, then attaches to the first one.
function dev.exe() {
    # Three-pane layout: main pane on top, two shells split across the bottom.
    setup_dev_layout() {
        local target_window="$1"
        tmux split-window -v -t "$target_window" -c '#{pane_current_path}'
        tmux select-pane -t "$target_window.1"
        tmux split-window -h -t "$target_window" -c '#{pane_current_path}'
        tmux select-pane -t "$target_window.0"
    }

    local repos=("${DEV_REPOS[@]}")
    (( $# > 0 )) && repos=("$@")   # dev.exe ~/Code/foo ~/Code/bar overrides the list

    local repo path session first_session=""
    for repo in "${repos[@]}"; do
        path=${~repo%/}             # expand a leading ~ and drop any trailing slash
        session=${path:t}           # basename of the dir
        session=${session//[.:]/_}  # tmux dislikes . and : in session names

        if [[ ! -d "$path" ]]; then
            echo "Skipping $session — $path not found"
            continue
        fi

        if tmux has-session -t "$session" 2>/dev/null; then
            echo "Session $session already exists, skipping"
            [[ -z "$first_session" ]] && first_session="$session"
            continue
        fi

        echo "Spinning up $session ($path)..."
        tmux new-session -d -s "$session" -c "$path"
        setup_dev_layout "$session:0"
        tmux send-keys -t "$session:0.0" "clear; nvim ." C-m
        tmux send-keys -t "$session:0.2" "clear" C-m

        [[ -z "$first_session" ]] && first_session="$session"
    done

    if [[ -z "$first_session" ]]; then
        echo "No sessions started."
        return 1
    fi

    echo "Environment spin up complete!"
    if [[ -n "$TMUX" ]]; then
        tmux switch-client -t "$first_session"   # already inside tmux
    else
        tmux attach-session -t "$first_session"
    fi
}

# starship prompt
eval "$(starship init zsh)"
