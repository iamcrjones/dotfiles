    set -U fish_greeting ""

    source ~/.config/fish/functions/start_tmux_sessions.fish

    alias tmux-uploads="start_tmux_uploads"
    alias tmux-bbops="start_tmux_bbops"
    alias tmux-fresh="start_tmux_fresh"
    alias tmux-api="start_tmux_sde_api"
    alias tmux-auth="start_tmux_sde_auth"
    alias tmux-spot="start_tmux_sde_spot"
    alias tmux-sde="start_sde"
    set -x PATH $PATH /home/cameron/.local/share/bob/nvim-bin
    starship init fish | source
