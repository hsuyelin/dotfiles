local utils = require("heirline.utils")

local ViMode = require("plugins.heirline.components.vi_mode")
local FilePath = require("plugins.heirline.components.fs")
local ornaments = require("plugins.heirline.components.ornaments")
local layouts = require("plugins.heirline.components.layouts")
local debugger = require("plugins.heirline.components.debugger")
local swift = require("plugins.heirline.components.swift")

local StatusLine = {
	{
		ViMode,
		utils.surround({ "", "" }, "bright_bg", FilePath),
	},
	layouts.Align,
	{
		-- swift
		layouts.Space,
		swift.XcodeBuildLastStatus,
		layouts.Space,
		swift.XcodeBuildTestPlan,
		layouts.Space,
		swift.XcodeBuildDevice,
		layouts.Space,
		-- lsp
		ornaments.LSPActive,
		-- git
		ornaments.GitBranch,
	},
}

-- setup heirline
require("heirline").setup({
	opts = {
		colors = require("plugins.heirline.setup_colors")(),
	},
	statusline = StatusLine,
})
