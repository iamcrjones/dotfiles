#!/bin/bash

# Update package databases and upgrade installed packages
sudo pacman -Syu --noconfirm

# Install programming languages and tools
sudo pacman -S --noconfirm nodejs npm php

# Install additional development tools via yay
yay -S --noconfirm neovim alacritty polybar starship tmux fish apache ttf-meslo-nerd stow

# Script to install composer
/home/iamcrjones/dotfiles/setup_scripts/composer_install.sh

# Clean up unnecessary packages and cache
sudo pacman -Sc --noconfirm
yay -Sc --noconfirm

echo "Development environment setup complete!"
