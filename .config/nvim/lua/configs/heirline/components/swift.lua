local XcodeBuildDevice = {
	condition = function()
		return vim.bo.filetype == "swift" and vim.g.xocdebuild_platform
	end,
	init = function(self)
		self.platform = vim.g.xcodebuild_platform
		self.device_name = vim.g.xcodebuild_device_name
		self.os = vim.g.xcodebuild_os
	end,
	hl = {
		fg = "yellow",
		-- "yellow",
		bold = false,
	},
	provider = function(self)
		if self.platform == "macOS" then
			return " macOS"
		end

		local deviceIcon = ""
		if self.platform:match("watch") then
			deviceIcon = "􀟤"
		elseif self.platform:match("tv") then
			deviceIcon = "􀡴 "
		elseif self.platform:match("vision") then
			deviceIcon = "􁎖 "
		end

		if self.os then
			return deviceIcon .. " " .. self.device_name .. " (" .. self.os .. ")"
		end

		return deviceIcon .. " " .. self.device_name
	end,
}

local XcodeBuildLastStatus = {
	condition = function()
		return vim.bo.filetype == "swift" and vim.g.xcodebuild_last_status
	end,
	hl = {
		fg = "cyan",
		bold = false,
	},
	provider = function()
		return " " .. vim.g.xcodebuild_last_status
	end,
}

local XcodeBuildTestPlan = {
	condition = function()
		return vim.bo.filetype == "swift" and vim.g.xcodebuild_test_plan
	end,
	hl = {
		fg = "blue",
		bold = false,
	},
	provider = function()
		return "󰙨 " .. vim.g.xcodebuild_test_plan
	end,
}

return {
	XcodeBuildDevice = XcodeBuildDevice,
	XcodeBuildLastStatus = XcodeBuildLastStatus,
	XcodeBuildTestPlan = XcodeBuildTestPlan,
}
