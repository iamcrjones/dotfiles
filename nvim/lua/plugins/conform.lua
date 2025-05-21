-- ~/.config/nvim/lua/plugins/conform.lua
return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      javascript = { "prettier_npx" },
      typescript = { "prettier_npx" },
      javascriptreact = { "prettier_npx" },
      typescriptreact = { "prettier_npx" },
      vue = { "prettier_npx" },
      json = { "prettier_npx" },
      html = { "prettier_npx" },
      css = { "prettier_npx" },
      scss = { "prettier_npx" },
      -- php = { "prettier_npx" }, -- optional
    },
    formatters = {
      prettier_npx = {
        command = "npx",
        args = { "prettier", "--stdin-filepath", "$FILENAME" },
        cwd = require("conform.util").root_file({ ".prettierrc", "package.json" }),
      },
    },
  },
}
