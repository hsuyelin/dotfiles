return {
	{
		"rebelot/heirline.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		event = "UiEnter",
		config = function()
			require("configs.heirline")
		end,
	},
}
