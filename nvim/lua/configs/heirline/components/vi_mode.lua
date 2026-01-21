local utils = require("heirline.utils")

local ViMode = {
	init = function(self)
		self.mode = vim.fn.mode()
	end,
	static = {
		mode_colors = {
			n = "red",
			i = "green",
			v = "cyan",
			V = "cyan",
			["\22"] = "cyan",
			c = "orange",
			s = "purple",
			S = "purple",
			["\19"] = "purple",
			R = "orange",
			r = "orange",
			["!"] = "orange",
			t = "orange",
		},
		mode_icons = {
			n = "󰈸",
			i = "",
			v = "",
			V = "",
			["\22"] = "",
			c = "",
			s = "",
			S = "",
			["\19"] = "",
			R = "",
			r = "",
			["!"] = "",
			t = "",
		},
	},
	update = {
		"ModeChanged",
		pattern = "*:*",
		callback = vim.schedule_wrap(function()
			vim.cmd("redrawstatus")
		end),
	},
}

local ViModeIcon = {
	provider = function(self)
		local icon = self.mode_icons[self.mode:sub(1, 1)] or ""
		local label = self.mode:upper()
		if icon == "" then
			return label
		end
		return string.format("%s %s", icon, label)
	end,
	hl = function(self)
		return {
			fg = "bright_bg",
			bg = self.mode_colors[self.mode],
			bold = true,
		}
	end,
}

local ViModeLeftSurrounder = {
	provider = function()
		return ""
	end,
	hl = function(self)
		return {
			fg = self.mode_colors[self.mode],
		}
	end,
}

local ViModeRightSurrounder = {
	provider = function()
		return ""
	end,
	hl = function(self)
		return {
			fg = self.mode_colors[self.mode],
		}
	end,
}

ViMode = utils.insert(ViMode, ViModeLeftSurrounder, ViModeIcon, ViModeRightSurrounder)
return ViMode
