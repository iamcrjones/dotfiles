# dotfiles

macOS (Apple Silicon) dotfiles. One command sets up a fresh machine:

```sh
git clone git@github.com:iamcrjones/dotfiles.git ~/Code/dotfiles
cd ~/Code/dotfiles
./install.sh
```

## What `install.sh` does

1. Ensures Xcode Command Line Tools + Homebrew are installed
2. Installs everything in `Brewfile` (`brew bundle`)
3. Installs language runtimes (node, php@8.5, composer) via **mise**
4. Symlinks configs into place, backing up anything it would overwrite to
   `~/.dotfiles-backup/<timestamp>/`
5. Clones TPM and installs tmux plugins
6. Syncs Neovim plugins (lazy.nvim)

Re-runnable and idempotent.

## Managed configs

| Repo | Symlinked to |
|------|--------------|
| `.zshrc` | `~/.zshrc` |
| `.tmux.conf` | `~/.tmux.conf` |
| `.wezterm.lua` | `~/.wezterm.lua` |
| `nvim/` | `~/.config/nvim` |
| `starship.toml` | `~/.config/starship.toml` |
| `mise/config.toml` | `~/.config/mise/config.toml` |

## Claude Code (optional — work machines)

Kept separate from `install.sh` so personal machines can skip it:

```sh
./install-claude.sh
```

Installs the `claude-code` cask (which provides the `claude` CLI) and symlinks
only the tracked `.claude` items (`settings.json`, `statusline-command.sh`,
`agents/`, `commands/`, `skills/`) into `~/.claude`. Claude Code's runtime state
(`projects/`, `todos/`, history, credentials) is left untouched.

## Tooling model

- **Homebrew** installs CLI tools + GUI apps (see `Brewfile`).
- **mise** manages language runtimes (node, php, composer, ...) — not Herd.
  PHP uses the `verzly/mise-php` plugin (registered in `install.sh`) so it isn't
  compiled from source — it also bundles Composer. Add a language with e.g.
  `mise use -g python@3.12`.

## Manual steps

- **Rectangle**: import `RectangleConfig.json` via Rectangle → Settings (can't be symlinked)
- **nvim LSPs/formatters**: run `:Mason` inside nvim (needs node + php)
- **Docker** — Colima is installed; run `colima start` to boot the daemon (no Docker Desktop)
- **Claude Code** — optional, work machines only: `./install-claude.sh`

## Notes

- The old Laravel Herd blocks in `.zshrc` are commented out — delete them once
  mise is confirmed working.
