return {
  {
    "mason-org/mason.nvim",
  config = function()
    require("mason").setup()
  end
  }
,{
    "mason-org/mason-lspconfig.nvim",
    opts = {ensure_installed = {"lua_ls","ts_ls"}},
    dependencies = {
        { "mason-org/mason.nvim", opts = {} },
    },
},{
        "neovim/nvim-lspconfig",
    config = function()
    local lspconfig = require("lspconfig")
      lspconfig.lua_ls.setup({})
      lspconfig.ts_ls.setup({})
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, {})
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {})
      vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, {})
    end
  }
}
