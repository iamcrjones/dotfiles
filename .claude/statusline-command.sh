#!/usr/bin/env bash
# Claude Code status line — Kanagawa Dragon inspired
# Mirrors key elements from the Starship config: directory, git, model, context

input=$(cat)

# ANSI colours (dimmed-friendly approximations of Kanagawa Dragon palette)
teal='\033[38;2;102;147;191m'
green='\033[38;2;135;169;135m'
violet='\033[38;2;137;146;167m'
yellow='\033[38;2;196;178;138m'
red='\033[38;2;196;116;110m'
gray='\033[38;2;166;166;156m'
bg5='\033[38;2;57;56;54m'
reset='\033[0m'
bold='\033[1m'

# ── Directory ─────────────────────────────────────────────
cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // empty')
# Shorten home directory to ~
cwd_display="${cwd/#$HOME/\~}"

# ── Git branch ────────────────────────────────────────────
branch=""
if git -C "$cwd" rev-parse --is-inside-work-tree --no-optional-locks 2>/dev/null | grep -q true; then
    branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
fi

# ── Git status (dirty indicator) ──────────────────────────
git_dirty=""
if [ -n "$branch" ]; then
    if ! git -C "$cwd" diff --quiet --no-optional-locks 2>/dev/null || \
       ! git -C "$cwd" diff --cached --quiet --no-optional-locks 2>/dev/null; then
        git_dirty="*"
    fi
fi

# ── Model ─────────────────────────────────────────────────
model=$(echo "$input" | jq -r '.model.display_name // empty')

# ── Context usage ─────────────────────────────────────────
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# ── Effort ────────────────────────────────────────────────
effort=$(echo "$input" | jq -r '.effort.level // empty')

# ── Assemble ──────────────────────────────────────────────
parts=""

# Directory
parts="${parts}$(printf "${teal}${bold} %s${reset}" "$cwd_display")"

# Git
if [ -n "$branch" ]; then
    branch_str=" ${branch}${git_dirty}"
    if [ -n "$git_dirty" ]; then
        parts="${parts}$(printf " ${yellow}%s${reset}" "$branch_str")"
    else
        parts="${parts}$(printf " ${green}%s${reset}" "$branch_str")"
    fi
fi

# Model
if [ -n "$model" ]; then
    parts="${parts}$(printf "  ${violet}%s${reset}" "$model")"
fi

# Effort
if [ -n "$effort" ]; then
    parts="${parts}$(printf " ${gray}[%s]${reset}" "$effort")"
fi

# Context
if [ -n "$used_pct" ]; then
    used_int=$(printf "%.0f" "$used_pct")
    if [ "$used_int" -ge 80 ]; then
        ctx_color="$red"
    elif [ "$used_int" -ge 50 ]; then
        ctx_color="$yellow"
    else
        ctx_color="$green"
    fi
    parts="${parts}$(printf "  ${ctx_color}ctx:%s%%${reset}" "$used_int")"
fi

printf "%b\n" "$parts"
