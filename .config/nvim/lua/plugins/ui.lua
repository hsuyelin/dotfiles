return {
	-- Bufferline
	{
		"akinsho/bufferline.nvim",
		version = "*",
		dependencies = "nvim-tree/nvim-web-devicons",
		config = function()
			---@type bufferline.Config
			require("bufferline").setup({
				options = {
					always_show_bufferline = false,
					close_command = function(buf)
						utils.bufdelete.delete(buf)
					end,
					diagnostics = "nvim_lsp",
					offsets = {
						-- {
						-- 	filetype = "neo-tree",
						-- 	-- text = "File Explorer",
						-- 	-- text_align = "left",
						-- 	separator = true
						-- }
					},
					indicator = {
						style = "underline",
					},
				},
			})
		end,
	},

	{
		"folke/noice.nvim",
		event = "VeryLazy",
		dependencies = {
			"MunifTanjim/nui.nvim",
			"rcarriga/nvim-notify",
		},
		opts = {
			lsp = {
				signature = {
					enabled = false,
				},
			},
		},
	},
}
