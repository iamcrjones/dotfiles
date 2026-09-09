#!/usr/bin/env bash
#
# dotfiles bootstrap — macOS (Apple Silicon)
# Installs tooling (Homebrew + mise) and symlinks configs into place.
#
# Usage:
#   ./install.sh
#
# Safe to re-run: it's idempotent and backs up anything it would overwrite
# to ~/.dotfiles-backup/<timestamp>/ before replacing it with a symlink.

set -euo pipefail

# ---------------------------------------------------------------------------
# Paths & helpers
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# 1. Xcode Command Line Tools (C compiler + make; needed by treesitter/LuaSnip)
# ---------------------------------------------------------------------------
if ! xcode-select -p >/dev/null 2>&1; then
  info "Installing Xcode Command Line Tools (accept the GUI prompt)..."
  xcode-select --install || true
  warn "Re-run this script once the Command Line Tools finish installing."
  exit 1
fi

# ---------------------------------------------------------------------------
# 2. Homebrew + Brewfile
# ---------------------------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

info "Installing packages from Brewfile..."
brew bundle --file="$DOTFILES/Brewfile"

# ---------------------------------------------------------------------------
# 3. Language runtimes via mise (node, php) + composer
# ---------------------------------------------------------------------------
link "$DOTFILES/mise/config.toml" "$HOME/.config/mise/config.toml"

if command -v mise >/dev/null 2>&1; then
  # PHP via the verzly/mise-php plugin (prebuilt; avoids compiling from source).
  # The plugin also installs a dedicated Composer alongside each PHP version.
  info "Registering the php mise plugin..."
  mise plugins ls 2>/dev/null | grep -qx php || mise plugins add php verzly/mise-php
  info "Installing language runtimes with mise (node, php@8.5 + bundled composer)..."
  mise install
else
  warn "mise not found on PATH; skipping runtime install."
fi

# ---------------------------------------------------------------------------
# 4. Symlink configs
# ---------------------------------------------------------------------------
info "Symlinking dotfiles..."
link "$DOTFILES/.zshrc"        "$HOME/.zshrc"
link "$DOTFILES/.tmux.conf"    "$HOME/.tmux.conf"
link "$DOTFILES/.wezterm.lua"  "$HOME/.wezterm.lua"
link "$DOTFILES/nvim"          "$HOME/.config/nvim"
link "$DOTFILES/starship.toml" "$HOME/.config/starship.toml"

# NOTE: Claude Code (cask + ~/.claude symlinks) is handled separately by
#       ./install-claude.sh so personal machines can skip it.

# ---------------------------------------------------------------------------
# 5. tmux plugin manager (TPM) + plugins
# ---------------------------------------------------------------------------
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
  info "Cloning TPM (tmux plugin manager)..."
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi
if [ -x "$TPM_DIR/bin/install_plugins" ]; then
  info "Installing tmux plugins..."
  "$TPM_DIR/bin/install_plugins" || warn "TPM install returned non-zero (open tmux and press <prefix> + I)."
fi

# ---------------------------------------------------------------------------
# 6. Neovim plugins (lazy.nvim self-bootstraps on first launch, then sync)
# ---------------------------------------------------------------------------
if command -v nvim >/dev/null 2>&1; then
  info "Syncing Neovim plugins (lazy.nvim)..."
  nvim --headless "+Lazy! sync" +qa || warn "nvim plugin sync had issues; open nvim to finish."
  warn "Run :Mason in nvim to install LSP servers/formatters (needs node + php on PATH)."
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
info "Bootstrap complete."
echo
echo "Manual follow-ups:"
echo "  - Rectangle: open Rectangle -> Settings -> import '$DOTFILES/RectangleConfig.json'"
echo "  - Reload your shell:  exec zsh   (or restart the terminal)"
echo "  - tmux: if plugins didn't auto-install, start tmux and press <prefix> + I"
echo "  - Docker: run 'colima start' to boot the Docker daemon (Colima)"
echo "  - Claude Code (work machines only): ./install-claude.sh"
if [ -d "$BACKUP_DIR" ]; then
  echo "  - Replaced files were backed up to: $BACKUP_DIR"
fi
