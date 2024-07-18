function start_tmux_uploads
    set directory "/home/cameron/Documents/code/SiteDE.UploadPortal"
    tmux new-session -d -s uploads \; \
        send-keys -t 0 "cd $directory; nvim" Enter \; \
        split-window -v -c $directory \; \
        send-keys -t 1 "cd $directory; npm run dev" Enter \; \
        split-window -h -c $directory \; \
        select-pane -t 0 \; \
        attach-session -t uploads
end


function start_tmux_bbops
    set directory /home/cameron/Documents/code/sitede-dockets/
    tmux new-session -d -s bbops \; \
        send-keys -t 0 "cd $directory; nvim" Enter \; \
        split-window -v -c $directory \; \
        send-keys -t 1 "cd $directory; npm run dev" Enter \; \
        split-window -h -c $directory \; \
        select-pane -t 0 \; \
        attach-session -t bbops
end

function start_tmux_sde_api
    set directory "/home/cameron/Documents/code/SiteDE.API"
    tmux new-session -d -s sde_api \; \
        send-keys -t 0 "cd $directory; nvim" Enter \; \
        split-window -v -c $directory \; \
        send-keys -t 1 "cd $directory; php artisan serve" Enter \; \
        split-window -h -c $directory \; \
        select-pane -t 0 \; \
        attach-session -t sde_api
end

function start_tmux_sde_auth
    set directory "/home/cameron/Documents/code/SiteDE.Authentication"
    tmux new-session -d -s sde_auth \; \
        send-keys -t 0 "cd $directory; nvim" Enter \; \
        split-window -v -c $directory \; \
        send-keys -t 1 "cd $directory; npm run dev" Enter \; \
        split-window -h -c $directory \; \
        select-pane -t 0 \; \
        attach-session -t sde_auth
end

function start_tmux_sde_spot
    set directory "/home/cameron/Documents/code/SiteDE.Spot"
    tmux new-session -d -s sde_spot \; \
        send-keys -t 0 "cd $directory; nvim" Enter \; \
        split-window -v -c $directory \; \
        send-keys -t 1 "cd $directory; npm run dev" Enter \; \
        split-window -h -c $directory \; \
        select-pane -t 0 \; \
        attach-session -t sde_spot
end

function start_tmux_fresh
    set directory /home/cameron/
    tmux new-session -d -s fresh \; \
        send-keys -t 0 "cd; clear" Enter \; \
        split-window -v -c $directory \; \
        split-window -h -c $directory \; \
        select-pane -t 0 \; \
        attach-session -t fresh
end

function start_sde
    alacritty --title "SDE API" -e fish -c 'source ~/.config/fish/config.fish; start_tmux_sde_api; fish' &
    alacritty --title "SDE AUTH" -e fish -c 'source ~/.config/fish/config.fish; start_tmux_sde_auth; fish' &
    alacritty --title "SDE SPOT" -e fish -c 'source ~/.config/fish/config.fish; start_tmux_sde_spot; fish' &
    alacritty --title "SDE UPLOADS" -e fish -c 'source ~/.config/fish/config.fish; start_tmux_uploads; fish' &
end
