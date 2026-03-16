-- return {
--   {
--     'sainnhe/everforest',
--     config = function()
--       vim.g.everforest_background = 'soft'
--
--       -- Optional: Set a specific style. Default is 'default'.
--       -- Other options include 'dark', 'light', 'tree', 'bush', 'fall', 'winter'.
--       -- vim.g.everforest_style = 'dark'
--
--       -- Configure 'transparent_background' to make your Neovim background
--       -- transparent, inheriting from your terminal's background.
--       vim.g.everforest_transparent_background = 1
--       vim.g.everforest_enable_undercurl = 1
--
--       -- Optional: Set specific themes for different parts of Neovim.
--       -- This can be useful for blending with other plugins.
--       -- vim.g.everforest_disable_italic_comment = 1
--       -- vim.g.everforest_enable_italic = 1
--       -- vim.g.everforest_hard_selection = 0
--       -- vim.g.everforest_better_performance = 0
--       -- vim.g.everforest_dark_foreground = 0
--
--       vim.cmd.colorscheme 'everforest'
--
--       -- You can add additional highlight group customizations here if needed.
--       -- For example, to change the background of LineNr:
--       -- vim.cmd("highlight LineNr guibg=NONE")
--     end,
--   },
-- }
return {
  'rebelot/kanagawa.nvim',
  config = function()
    require('kanagawa').setup {
      compile = false, -- enable compiling the colorscheme
      undercurl = true, -- enable undercurls
      commentStyle = { italic = true },
      functionStyle = {},
      keywordStyle = { italic = true },
      statementStyle = { bold = true },
      typeStyle = {},
      transparent = true, -- do not set background color
      dimInactive = false, -- dim inactive window `:h hl-NormalNC`
      terminalColors = true, -- define vim.g.terminal_color_{0,17}
      colors = { -- add/modify theme and palette colors
        palette = {},
        theme = { wave = {}, lotus = {}, dragon = {}, all = {} },
      },
      overrides = function(colors) -- add/modify highlights
        return {}
      end,
      theme = 'dragon', -- Load "wave" theme
      background = { -- map the value of 'background' option to a theme
        dark = 'dragon', -- try "dragon" !
        light = 'lotus',
      },
    }

    -- setup must be called before loading
    vim.cmd 'colorscheme kanagawa'
  end,
}
