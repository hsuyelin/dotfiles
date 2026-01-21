return {
	{
		-- 'nvim-telescope/telescope.nvim', tag = '0.1.0',
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		config = function()
			require("telescope").setup({
				defaults = {
					layout_strategy = "flex",
					sorting_strategy = "ascending",
					layout_config = {
						vertical = { width = 0.88 },
						horizontal = {
							prompt_position = "top",
							preview_width = 0.54,
							width = 0.88,
							height = 0.88,
						},
					},
					mappings = {
						i = {
							["<C-u>"] = false,
							["<C-q>"] = require("trouble.sources.telescope").open,
						},
					},
					file_ignore_patterns = {
						-- flutter project
						-- "android",
						-- "ios",
						-- "web",
						-- "macos",
						-- "windows",
						-- "assets",
					},
				},
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown({}),
					},
					zoxide = {
                        prompt_title = "[ Zoxide ]",
                        mappings = {
                            default = {
                            },
                        },
                    },
					emoji = {
						action = function(emoji)
							vim.api.nvim_put({ emoji.value }, "c", false, true)
						end,
					},
				},
				pickers = {
					colorscheme = {
						enable_preview = true,
					},
				},
			})
		end,
	},

	{
		"nvim-telescope/telescope-ui-select.nvim",
		dependencies = { "nvim-telescope/telescope.nvim" },
		config = function()
			require("telescope").load_extension("ui-select")
		end,
	},

	{
		"LukasPietzschmann/telescope-tabs",
		dependencies = { "nvim-telescope/telescope.nvim" },
		config = function()
			require("telescope-tabs").setup({})
		end,
	},

	{
		"jvgrootveld/telescope-zoxide",
		dependencies = { "nvim-telescope/telescope.nvim" },
		config = function()
			require("telescope").load_extension("zoxide")
		end,
	}
}
