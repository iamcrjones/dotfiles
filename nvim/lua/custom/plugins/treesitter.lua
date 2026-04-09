return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'main', -- Ensure you are on 'main'
  build = ':TSUpdate',
  config = function()
    require('nvim-treesitter').setup {
      -- your config here
    }
  end,
}
