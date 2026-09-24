return {
  'neovim/nvim-lspconfig',
  dependencies = {
    { import = 'custom.plugins.lsp.lazydev' },
    { import = 'custom.plugins.lsp.mason' },
    { import = 'custom.plugins.telescope' },
    'saghen/blink.cmp',
    'b0o/schemastore.nvim',
  },
  config = function()
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('custom-lsp-attach', { clear = true }),
      callback = function(event)
        local map = function(keys, func, desc, mode)
          mode = mode or 'n'
          vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
        end

        map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
        map('<leader>ca', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
        map('<leader>cd', vim.diagnostic.open_float, 'Open Line Diagnostics')
        map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
        map('gri', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
        map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
        map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
        map('gO', require('telescope.builtin').lsp_document_symbols, 'Open Document Symbols')
        map('gW', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'Open Workspace Symbols')
        map('gt', require('telescope.builtin').lsp_type_definitions, '[G]oto [T]ype Definition')

        local function client_supports_method(client, method, bufnr)
          if vim.fn.has 'nvim-0.11' == 1 then
            return client:supports_method(method, bufnr)
          else
            return client.supports_method(method, { bufnr = bufnr })
          end
        end

        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
          local highlight_augroup = vim.api.nvim_create_augroup('custom-lsp-highlight', { clear = false })
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })

          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })

          vim.api.nvim_create_autocmd('LspDetach', {
            group = vim.api.nvim_create_augroup('custom-lsp-detach', { clear = true }),
            callback = function(event2)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds { group = 'custom-lsp-highlight', buffer = event2.buf }
            end,
          })
        end

        if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
          map('<leader>th', function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
          end, '[T]oggle Inlay [H]ints')
        end
      end,
    })

    vim.diagnostic.config {
      severity_sort = true,
      float = { border = 'rounded', source = 'if_many' },
      underline = { severity = vim.diagnostic.severity.ERROR },
      signs = vim.g.have_nerd_font and {
        text = {
          [vim.diagnostic.severity.ERROR] = '󰅚 ',
          [vim.diagnostic.severity.WARN] = '󰀪 ',
          [vim.diagnostic.severity.INFO] = '󰋽 ',
          [vim.diagnostic.severity.HINT] = '󰌶 ',
        },
      } or {},
      virtual_text = {
        source = 'if_many',
        spacing = 2,
        format = function(diagnostic)
          local diagnostic_message = {
            [vim.diagnostic.severity.ERROR] = diagnostic.message,
            [vim.diagnostic.severity.WARN] = diagnostic.message,
            [vim.diagnostic.severity.INFO] = diagnostic.message,
            [vim.diagnostic.severity.HINT] = diagnostic.message,
          }
          return diagnostic_message[diagnostic.severity]
        end,
      },
    }

    vim.filetype.add {
      pattern = {
        ['.*%.yaml%..*'] = 'yaml',
        ['.*%.yml%..*'] = 'yaml',
      },
    }

    -- blink.cmp advertises richer completion capabilities than Neovim's
    -- defaults. Apply them to every server via the wildcard ('*') config.
    local capabilities = require('blink.cmp').get_lsp_capabilities()
    vim.lsp.config('*', { capabilities = capabilities })

    -- Path to the bundled @vue/language-server. ts_ls loads the
    -- @vue/typescript-plugin from here to type-check .vue <script> blocks.
    local vue_language_server_path = vim.fn.stdpath 'data' .. '/mason/packages/vue-language-server/node_modules/@vue/language-server'

    -- Per-server overrides. These are deep-merged on top of the defaults
    -- nvim-lspconfig ships in its lsp/ directory, so servers not listed here
    -- (tailwindcss, cssls, html, eslint, jsonls, emmet, yamlls,
    -- marksman, intelephense, ...) just use those defaults. mason-lspconfig
    -- (v2) auto-enables every installed server for us.
    vim.lsp.config('lua_ls', {
      settings = {
        Lua = {
          completion = { callSnippet = 'Replace' },
        },
      },
    })

    -- Vue 3 hybrid mode: vue_ls owns the <template>/<style>, while ts_ls owns
    -- the <script> via the Vue TypeScript plugin. For this to work ts_ls must
    -- also attach to .vue files. The shipped vue_ls config already forwards
    -- TypeScript requests to ts_ls, so no vue_ls override is needed here.
    vim.lsp.config('ts_ls', {
      filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'vue' },
      init_options = {
        plugins = {
          {
            name = '@vue/typescript-plugin',
            location = vue_language_server_path,
            languages = { 'vue' },
          },
        },
      },
    })

    -- JSON/YAML schema validation via SchemaStore's catalog: field-level
    -- validation, autocomplete and hover for package.json, tsconfig.json,
    -- eas.json, GitHub Actions, docker-compose, and ~1400 others. app.json is
    -- mapped explicitly because SchemaStore leaves its fileMatch empty.
    vim.lsp.config('jsonls', {
      settings = {
        json = {
          validate = { enable = true },
          schemas = require('schemastore').json.schemas {
            extra = {
              {
                name = 'Expo app config',
                fileMatch = { 'app.json', 'app.config.json' },
                url = 'https://www.schemastore.org/expo-53.0.0.json',
              },
            },
          },
        },
      },
    })

    vim.lsp.config('yamlls', {
      settings = {
        yaml = {
          -- Use SchemaStore's catalog instead of yaml-language-server's built-in one.
          schemaStore = { enable = false, url = '' },
          schemas = require('schemastore').yaml.schemas(),
        },
      },
    })

    -- Install the language servers, formatters and linters this config relies
    -- on, so a fresh machine reproduces the setup. mason-lspconfig then enables
    -- each installed server automatically.
    require('mason-tool-installer').setup {
      ensure_installed = {
        -- Web / JS / TS / Vue
        'typescript-language-server',
        'vue-language-server',
        'eslint-lsp',
        'tailwindcss-language-server',
        'css-lsp',
        'html-lsp',
        'json-lsp',
        'emmet-language-server',
        'prettier',
        'prettierd',
        -- Lua
        'lua-language-server',
        'stylua',
        -- PHP
        'intelephense',
        'php-cs-fixer',
        'phpcbf',
        'phpcs',
        'pint',
        -- Other
        'yaml-language-server',
        'marksman',
        'markdownlint',
        'shfmt',
      },
    }

    require('mason-lspconfig').setup {
      ensure_installed = {},
      automatic_enable = true,
    }
  end,
}
