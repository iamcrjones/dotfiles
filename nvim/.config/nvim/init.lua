-- bootstrap lazy.nvim, LazyVim and your plugins
if vim.g.vscode then
  -- VSCode extension
else
  -- ordinary Neovim
  require("config.lazy")
end
