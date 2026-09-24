#!/usr/bin/env bash
#
# Claude Code setup — optional, work machines only.
# Installs the Claude Code app (Homebrew cask, which provides the `claude` CLI)
# and symlinks the tracked ~/.claude config. Kept separate from install.sh so
# personal machines can skip it.
#
# Usage:
#   ./install-claude.sh

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

c_reset=$'\033[0m'; c_blue=$'\033[34m'; c_green=$'\033[32m'; c_yellow=$'\033[33m'
info() { printf "%s==>%s %s\n" "$c_blue"   "$c_reset" "$*"; }
ok()   { printf "%s ok %s %s\n" "$c_green"  "$c_reset" "$*"; }
warn() { printf "%s !! %s %s\n" "$c_yellow" "$c_reset" "$*"; }

# link SRC DST — symlink SRC to DST, backing up any existing DST first.
link() {
  local src="$1" dst="$2"
  if [ ! -e "$src" ]; then warn "source missing, skipping: $src"; return; fi
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then ok "$dst"; return; fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mkdir -p "$BACKUP_DIR"
    mv "$dst" "$BACKUP_DIR/"
    warn "backed up existing $(basename "$dst") -> $BACKUP_DIR/"
  fi
  ln -s "$src" "$dst"
  ok "linked $dst -> $src"
}

# --- Homebrew must be available (run ./install.sh first on a fresh machine) ---
command -v brew >/dev/null 2>&1 || eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || true
if ! command -v brew >/dev/null 2>&1; then
  warn "Homebrew not found on PATH — run ./install.sh first."
  exit 1
fi

# --- Install Claude Code (native cask; puts the `claude` command on PATH) ---
info "Installing Claude Code (cask)..."
brew install --cask claude-code

# --- Symlink tracked ~/.claude items; preserve runtime state ---
# (projects/, todos/, history, credentials are intentionally NOT touched.)
info "Symlinking Claude Code config (preserving runtime state)..."
link "$DOTFILES/.claude/settings.json"         "$HOME/.claude/settings.json"
link "$DOTFILES/.claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
link "$DOTFILES/.claude/agents"                "$HOME/.claude/agents"
link "$DOTFILES/.claude/commands"              "$HOME/.claude/commands"
link "$DOTFILES/.claude/skills"                "$HOME/.claude/skills"

info "Claude Code setup complete."
echo "  - Run 'claude' and authenticate on first launch."
echo "  - Plugins referenced in settings.json (php-lsp, greptile) install on first run."
if [ -d "$BACKUP_DIR" ]; then
  echo "  - Replaced files were backed up to: $BACKUP_DIR"
fi
