local M = {}
local first_run = true

function M.show()
  vim.schedule(function()
    local bufnr = vim.api.nvim_get_current_buf()
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")

    if first_run then
      local log_file = vim.fn.expand("~/nvim_peek_first_run.log")
      local log_message = string.format(
        "First run: start_pos = %s, end_pos = %s, bufnr = %s",
        vim.inspect(start_pos),
        vim.inspect(end_pos),
        bufnr
      )
      vim.fn.append(log_message, log_file)
      first_run = false
    end

    if not start_pos or not end_pos then
      vim.notify("Could not get visual selection range", vim.log.levels.ERROR)
      return
    end

    local start_line = math.min(start_pos[2], end_pos[2])
    local end_line = math.max(start_pos[2], end_pos[2])

    local start_index = start_line - 1
    local end_index = end_line

    local lines = vim.api.nvim_buf_get_lines(bufnr, start_index, end_index, false)
    if not lines or vim.tbl_isempty(lines) then
      vim.notify("No lines selected", vim.log.levels.WARN)
      return
    end

    local float_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(float_buf, 0, -1, false, lines)
    vim.bo[float_buf].buftype = "nofile"
    vim.bo[float_buf].bufhidden = "wipe"
    vim.bo[float_buf].modifiable = false
    vim.bo[float_buf].readonly = true

    local width = math.min(80, math.max(30, math.floor(vim.o.columns * 0.4)))
    local height = math.max(1, math.min(#lines, 20))
    local row = math.floor((vim.o.lines - height) / 2 - 1)
    local col = math.floor((vim.o.columns - width) / 2)

    local float_win = vim.api.nvim_open_win(float_buf, true, {
      relative = "editor",
      row = row,
      col = col,
      width = width,
      height = height,
      style = "minimal",
      border = "rounded",
    })

    vim.api.nvim_buf_set_keymap(float_buf, "n", "q", "<cmd>bd!<CR>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(float_buf, "n", "<Esc>", "<cmd>bd!<CR>", { noremap = true, silent = true })
    vim.wo[float_win].cursorline = true
  end)
end

return M
