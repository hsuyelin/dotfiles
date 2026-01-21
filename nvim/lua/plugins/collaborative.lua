return {
	{
		"nomad/nomad",
		version = "*",
		build = function()
			---@type nomad.neovim.build
			local build = require("nomad.neovim.build")
			build.builders.download_prebuilt():build(build.contexts.lazy())
		end,
		opts = {},
	},
}
