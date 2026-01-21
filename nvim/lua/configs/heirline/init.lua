local utils = require("heirline.utils")

local ViMode = require("configs.heirline.components.vi_mode")
local FilePath = require("configs.heirline.components.fs")
local ornaments = require("configs.heirline.components.ornaments")
local layouts = require("configs.heirline.components.layouts")
local debugger = require("configs.heirline.components.debugger")
local swift = require("configs.heirline.components.swift")

local StatusLine = {
	{
		ViMode,
		utils.surround({ "", "" }, "bright_bg", FilePath),
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
		colors = require("configs.heirline.setup_colors")(),
	},
	statusline = StatusLine,
})
