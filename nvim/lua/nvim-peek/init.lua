-- ~/.config/nvim/lua/plugins/nvim-peek/init.lua

local M = {}

function M.setup(opts)
  -- If you want to allow user configuration later
  opts = opts or {}

  vim.keymap.set("v", "<leader>p", function()
    require("nvim-peek.peek").show()
  end, { desc = "Preview selection in float", silent = true })
end

return M
