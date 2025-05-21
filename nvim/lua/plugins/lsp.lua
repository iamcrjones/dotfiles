-- ~/.config/nvim/lua/plugins/lsp.lua
return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      tsserver = {},
    },
    setup = {
      tsserver = function(_, opts)
        opts.on_attach = function(client, bufnr)
          client.server_capabilities.documentFormattingProvider = false
        end
        return false -- LazyVim will use this setup instead of the default
      end,
    },
  },
}
