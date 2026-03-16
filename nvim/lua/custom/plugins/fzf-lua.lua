return {
  'ibhagwan/fzf-lua',
  dependencies = {
    { 'nvim-tree/nvim-web-devicons', cond = vim.g.have_nerd_font },
  },
  config = function()
    require('fzf-lua').setup {
      find_opts = [[-type f \! -path '*/.git/*' \! -name '.env']],
      rg_opts = [[--color=never --hidden --files --no-ignore -g "!.git"]],
      fd_opts = [[--color=never --hidden --type f --type l -I --exclude .git]],
      file_ignore_patterns = {
        'node_modules/',
        'dist/',
        '.next',
        'vendor/',
      },
      grep = {
        hidden = true,
        follow = false,
        no_ignore = true,
        fzf_opts = { ['--exact'] = true },
      },
      files = {
        hidden = true,
        follow = false,
        no_ignore = true,
        fzf_opts = { ['--exact'] = true },
      },
    }

    local fzf_lua = require 'fzf-lua'

    vim.keymap.set('n', '<leader>sh', fzf_lua.helptags, { desc = '[S]earch [H]elp' })
    vim.keymap.set('n', '<leader>sk', fzf_lua.keymaps, { desc = '[S]earch [K]eymaps' })
    vim.keymap.set('n', '<leader>sf', fzf_lua.files, { desc = '[S]earch [F]iles' })
    vim.keymap.set('n', '<leader>ss', fzf_lua.builtin, { desc = '[S]earch [S]elect Fzf-lua' })
    vim.keymap.set('n', '<leader>sw', fzf_lua.grep_cword, { desc = '[S]earch current [W]ord' })
    vim.keymap.set('n', '<leader>sg', fzf_lua.live_grep, { desc = '[S]earch by [G]rep' })
    vim.keymap.set('n', '<leader>sd', fzf_lua.diagnostics_document, { desc = '[S]earch [D]iagnostics' })
    vim.keymap.set('n', '<leader>sr', fzf_lua.resume, { desc = '[S]earch [R]esume' })
    vim.keymap.set('n', '<leader>s.', fzf_lua.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
    vim.keymap.set('n', '<leader>sb', fzf_lua.buffers, { desc = '[S]earch existing buffers' })

    vim.keymap.set('n', '<leader>/', function()
      fzf_lua.blines {
        winopts = {
          title = 'Search in Current Buffer',
          previewer = false,
        },
        fzf_opts = { ['--prompt'] = 'Lines> ' },
      }
    end, { desc = '[/] Fuzzily search in current buffer' })

    vim.keymap.set('n', '<leader>s/', function()
      fzf_lua.live_grep_open_files {
        winopts = { title = 'Live Grep in Open Files' },
      }
    end, { desc = '[S]earch [/] in Open Files' })

    vim.keymap.set('n', '<leader>sn', function()
      fzf_lua.files { cwd = vim.fn.stdpath 'config' }
    end, { desc = '[S]earch [N]eovim files' })
  end,
}
