local wezterm = require("wezterm")
local config = wezterm.config_builder()

--Fonts
config.font = wezterm.font("MesloLGS Nerd Font Mono")
config.font_size = 18

--Make sure mac alt key nav with zellij working
config.send_composed_key_when_left_alt_is_pressed = true
config.send_composed_key_when_right_alt_is_pressed = true
config.use_ime = false

--Remove tab bar
config.enable_tab_bar = false

--Colors
-- config.color_scheme = "Tokyo Night"
-- config.color_scheme = "Palenight (Gogh)"
config.color_scheme = "Kanagawa (Gogh)"
--Window config
config.window_decorations = "RESIZE"
config.window_background_opacity = 0.8
config.macos_window_background_blur = 15

-- config.default_prog = { "/opt/homebrew/bin/tmux" }

return config
