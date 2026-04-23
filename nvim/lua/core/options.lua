-- leader
vim.g.mapleader = " "
vim.g.maplocalleader = ","

local nvim_bin = vim.fn.stdpath("config") .. "/bin"
if not vim.env.PATH:find(nvim_bin, 1, true) then
	vim.env.PATH = nvim_bin .. ":" .. vim.env.PATH
end

local uv = vim.uv or vim.loop
local runtime_dir = vim.fn.stdpath("cache") .. "/runtime"
if not vim.env.XDG_RUNTIME_DIR or not uv.fs_access(vim.env.XDG_RUNTIME_DIR, "rwx") then
	vim.fn.mkdir(runtime_dir, "p")
	vim.env.XDG_RUNTIME_DIR = runtime_dir
end

local options = {
	exrc = true,
	clipboard = "unnamedplus",
	termguicolors = true,
	mouse = "a",
	fileencoding = "utf-8",
	ignorecase = true,
	autoindent = true,
	tabstop = 2,
	shiftwidth = 2,
	number = true,
	relativenumber = true,
	wrap = true,
	cursorline = true,
	cursorcolumn = false,
	timeout = true,
	timeoutlen = 800,
	winblend = 6,
	swapfile = false,
	scrolloff = 20,
	cmdheight = 0,
	laststatus = 3,
	title = true,
	titlestring = "%{expand('%:p') != '' ? expand('%:p') : getcwd()}",
	winborder = "bold",
}

for k, v in pairs(options) do
	vim.opt[k] = v
end

-- filetypes
vim.filetype.add({
	extension = {
		arb = "json",
	},
	filename = {
		[".zshrc"] = "sh",
	},
})
