return {
	-- TODO: write my own projectile.nvim and dashboard.nvim
	{
		"ahmedkhalf/project.nvim",
		config = function()
			require("project_nvim").setup({
				manual_mode = true,
				patterns = {
					".git",
					".project",
					"pubspec.yaml",
				},
				scope_chdir = "global",
			})
			require("telescope").load_extension("projects")
		end,
	},
}
