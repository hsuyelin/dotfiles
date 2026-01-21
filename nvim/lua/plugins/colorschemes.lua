return {
	-- catppuccin
	{
		"catppuccin/nvim",
		name = "catppuccin",
		config = function()
			require("catppuccin").setup({
				flavour = "frappe",
				transparent_background = true,
				integrations = {
					neogit = false,
					hop = true,
					telescope = true,
					neotree = {
						enabled = true,
						show_root = true,
						transparent_panel = false,
					},
				},
			})
		end,
	},

	-- nightfox
	"EdenEast/nightfox.nvim",

	-- tokyonight
	{
		"folke/tokyonight.nvim",
		config = function()
			if vim.o.winborder == "none" then
				require("tokyonight").setup({
					on_highlights = function(hl, c)
						local prompt = "#2d3149"
						-- Lsp Signature
						hl.FloatBorder = {
							bg = c.bg_dark,
							fg = c.bg_dark,
						}
						-- Telescope
						hl.TelescopeNormal = {
							bg = c.bg_dark,
							fg = c.fg_dark,
						}
						hl.TelescopeBorder = {
							bg = c.bg_dark,
							fg = c.bg_dark,
						}
						hl.TelescopePromptNormal = {
							bg = prompt,
						}
						hl.TelescopePromptBorder = {
							bg = prompt,
							fg = prompt,
						}
						hl.TelescopePromptTitle = {
							bg = prompt,
							fg = prompt,
						}
						hl.TelescopePreviewTitle = {
							bg = c.bg_dark,
							fg = c.bg_dark,
						}
						hl.TelescopeResultsTitle = {
							bg = c.bg_dark,
							fg = c.bg_dark,
						}
					end,
				})
			end
		end,
	},

	{
		"olimorris/onedarkpro.nvim",
		priority = 1000, -- Ensure it loads first
	},
}
