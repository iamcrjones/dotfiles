return {
	"folke/which-key.nvim",
	event = "VeryLazy", -- Load very late to avoid startup impact
	config = function()
		require("which-key").setup({
			-- Configure which-key options here if needed
			-- For example, change the popup delay:
			-- delay = 100,
		})
		local wk = require("which-key")
		wk.add({
			{ "<leader>e", "<cmd>Oil<cr>", desc = "Open Oil", mode = "n" },

			{
				"<leader>F",
				function()
					require("conform").format({ async = true })
				end,
				mode = "n",
				desc = "Format buffer",
			},
			{ "<leader><space>", "<cmd>Telescope find_files<cr>", desc = "Find File", mode = "n" },
			{ "<leader>/", "<cmd>Telescope live_grep<cr>", desc = "Live Grep", mode = "n" },
			{ "<leader>f", group = "file" }, -- group
			{ "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find File", mode = "n" },
			{ "<leader>g", group = "git" }, -- group
			{ "<leader>gg", "<cmd>LazyGit<cr>", desc = "Open LazyGit", mode = "n" },
			{
				-- Nested mappings are allowed and can be added in any order
				-- Most attributes can be inherited or overridden on any level
				-- There's no limit to the depth of nesting
				mode = { "n", "v" }, -- NORMAL and VISUAL mode
				{ "<leader>q", "<cmd>q<cr>", desc = "Quit" }, -- no need to specify mode since it's inherited
				{ "<leader>w", "<cmd>w<cr>", desc = "Write" },
			},
		})
	end,
}
