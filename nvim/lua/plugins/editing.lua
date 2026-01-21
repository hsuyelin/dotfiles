return {
	-- Surround
	{
		"kylechui/nvim-surround",
		version = "*", -- Use for stability; omit to use `main` branch for the latest features
		event = "VeryLazy",
		config = function()
			require("nvim-surround").setup({})
		end,
	},

	-- Mouse Movement
	{
		"folke/flash.nvim",
		event = "VeryLazy",
		---@type Flash.Config
		opts = {
			modes = {
				char = {
					keys = { "f", "F", "t", "T", ";", [","] = "<C-;>" },
					char_actions = function(motion)
						return {
							[";"] = "next", -- set to `right` to always go right
							[","] = "prev", -- set to `left` to always go left
							-- clever-f style
							[motion:lower()] = "next",
							[motion:upper()] = "prev",
						}
					end,
				},
			},
		},
		---@type Flash.Config
		keys = {
			{
				"r",
				mode = { "n", "x", "o" },
				function()
					require("flash").jump()
				end,
				desc = "Flash Jump",
			},
			{
				"R",
				mode = { "n", "x", "o" },
				function()
					require("flash").treesitter_search()
				end,
				desc = "Flash Jump",
			},
			{
				"<C-r>",
				mode = { "n", "x", "o" },
				function()
					require("flash").treesitter()
				end,
				desc = "Flash Treesitter",
			},
		},
	},

	-- Better Commenting
	{
		"folke/ts-comments.nvim",
		opts = {},
		event = "VeryLazy",
		enabled = vim.fn.has("nvim-0.10.0") == 1,
	},

	-- Auto Pairs
	{
		"windwp/nvim-autopairs",
		config = function()
			require("nvim-autopairs").setup()
		end,
	},
}
