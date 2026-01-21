local utils = require("heirline.utils")
local conditions = require("heirline.conditions")
-- WorkDir
local WorkDir = {
	init = function(self)
		local cwd = vim.fn.getcwd(0)
		self.cwd = vim.fn.fnamemodify(cwd, ":~")
	end,
	hl = { fg = "directory" },
	flexible = 1,
	{
		-- evaluates to the full-lenth path
		provider = function(self)
			local trail = self.cwd:sub(-1) == "/" and "" or "/"
			-- return self.icon .. self.cwd .. trail
			return self.cwd .. trail
		end,
	},
	{
		-- evaluates to the shortened path
		provider = function(self)
			local cwd = vim.fn.pathshorten(self.cwd)
			local trail = self.cwd:sub(-1) == "/" and "" or "/"
			return cwd .. trail .. " "
		end,
	},
}

-- File Section
local FileNameBlock = {
	init = function(self)
		self.filename = vim.api.nvim_buf_get_name(0)
	end,
	hl = { fg = "file" },
}
local FileIcon = {
	init = function(self)
		local filename = vim.api.nvim_buf_get_name(0)
		local extension = vim.fn.fnamemodify(filename, ":e")
		self.icon, self.icon_color = require("nvim-web-devicons").get_icon_color(filename, extension)
	end,
	provider = function(self)
		if not self.icon then
			return ""
		end
		return " " .. self.icon
	end,
	hl = function(self)
		return { fg = self.icon_color }
	end,
}
local FileName = {
	condition = function()
		return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t") ~= ""
	end,
	flexible = 2,
	{
		provider = function(self)
			local filename = vim.fn.fnamemodify(self.filename, ":.")
			return filename
		end,
	},
	{
		provider = function(self)
			local filename = vim.fn.fnamemodify(self.filename, ":.")
			return vim.fn.pathshorten(filename)
		end,
	},
}

local FileFlags = {
	{
		condition = function()
			return vim.bo.modified
		end,
		provider = function()
			return " [+]"
		end,
		hl = { fg = "green" },
	},
	{
		condition = function()
			return not vim.bo.modifiable or vim.bo.readonly
		end,
		provider = "",
		hl = { fg = "orange" },
	},
}

FileNameBlock = utils.insert(FileNameBlock, FileName, FileFlags, FileIcon, { provider = "%<" })

local FilePath = {
	hl = {
		bg = "bright_bg",
	},
}

FilePath = utils.insert(FilePath, WorkDir, FileNameBlock)

return FilePath
