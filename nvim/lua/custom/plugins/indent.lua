return {
  'lukas-reineke/indent-blankline.nvim',
  config = function()
    local indent_blankline = require 'ibl'

    indent_blankline.setup {
      indent = {
        char = '▏',
      },
      whitespace = {
        highlight = 'Whitespace',
      },
      exclude = {
        filetypes = {
          'help',
          'startify',
          'dashboard',
          'packer',
          'neogitstatus',
          'NvimTree',
          'Trouble',
        },
        buftypes = {
          'terminal',
          'nofile',
        },
      },
      scope = {
        enabled = true,
      },
    }
  end,
}
