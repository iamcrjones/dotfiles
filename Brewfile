# Brewfile — declarative package manifest for these dotfiles.
# Install everything with:  brew bundle --file=Brewfile
# Idempotent: already-installed packages are skipped.
#
# NOTE: language runtimes (node, php, composer) are NOT here — they're managed
#       by mise (see mise/config.toml).

# --- Shell & prompt ---
brew "starship"
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"
brew "mise"                       # runtime version manager (node, php, ...)

# --- Editor ---
brew "neovim"
brew "stylua"                     # Lua formatter used by nvim (conform.nvim)
brew "tree-sitter"                # nvim treesitter parser compilation (main branch)

# --- Terminal multiplexer ---
brew "tmux"

# --- CLI tools ---
brew "ripgrep"                    # nvim fzf-lua / telescope grep
brew "fd"                         # nvim fzf-lua / telescope file search
brew "fzf"
brew "jq"                         # Claude Code statusline (statusline-command.sh)
brew "lazygit"                    # `lzg` alias + lazygit.nvim
brew "git"
brew "gh"                         # GitHub CLI
brew "htop"                       # process viewer

# --- GUI apps & fonts ---
cask "wezterm"                    # terminal
cask "font-meslo-lg-nerd-font"    # Nerd Font for wezterm/starship/tmux/nvim glyphs
cask "rectangle"                  # window manager (import RectangleConfig.json via the app)
cask "visual-studio-code"         # editor
cask "dbeaver-community"          # database GUI
cask "1password"                  # password manager (app)
cask "1password-cli"              # `op` CLI

# --- Docker (Colima — lightweight, no Docker Desktop) ---
brew "colima"                     # Docker daemon in a small VM (run `colima start`)
brew "docker"                     # docker CLI
brew "docker-compose"             # compose plugin
brew "lazydocker"                 # Docker TUI (works with Colima)
