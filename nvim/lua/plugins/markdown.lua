return {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" }, -- if you prefer nvim-web-devicons
		---@module 'render-markdown'
		---@type render.md.UserConfig
		opts = {},
	},
	-- Markdown Preview
	{
		"toppair/peek.nvim",
		build = "deno task --quiet build:fast",
		ft = { "markdown" },
		keys = {
			{
				"<leader>mp",
				function()
					require("peek").open()
				end,
				desc = "Markdown Preview Open",
			},
			{
				"<leader>mc",
				function()
					require("peek").close()
				end,
				desc = "Markdown Preview Close",
			},
		},
		config = function()
			require("peek").setup({
				auto_load = true,
				close_on_bdelete = true,
				syntax = true,
				theme = "light", -- 'dark' or 'light'
				update_on_change = true,
				app = "browser",
			})

			vim.api.nvim_buf_create_user_command(0, "PeekOpen", require("peek").open, {})
			vim.api.nvim_buf_create_user_command(0, "PeekClose", require("peek").close, {})
		end,
	},
}
