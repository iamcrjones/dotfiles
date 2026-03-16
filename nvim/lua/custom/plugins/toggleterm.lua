return {
  'akinsho/toggleterm.nvim',
  version = '*',
  config = function()
    require('toggleterm').setup {
      -- Configuration options (optional)
      -- size = 20,
      open_mapping = [[<C-_>]],
      direction = 'float',
      float_opts = {
        border = 'curved',
      },
    }
  end,
}
