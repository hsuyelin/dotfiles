-- leader
vim.g.mapleader = " "
vim.g.maplocalleader = ","

local nvim_bin = vim.fn.stdpath("config") .. "/bin"
if not vim.env.PATH:find(nvim_bin, 1, true) then
	vim.env.PATH = nvim_bin .. ":" .. vim.env.PATH
end

-- Mason installs LSP servers via system tools (node → pyright/bashls, go → gopls).
-- GUI-launched nvim may not inherit the shell's full PATH, so inject Homebrew
-- paths explicitly to guarantee these tools are always reachable.
local extra_paths = {
	"/opt/homebrew/bin",  -- Apple Silicon
	"/usr/local/bin",     -- Intel Mac
}
for _, p in ipairs(extra_paths) do
	if vim.fn.isdirectory(p) == 1 and not vim.env.PATH:find(p, 1, true) then
		vim.env.PATH = p .. ":" .. vim.env.PATH
	end
end

local uv = vim.uv or vim.loop
local runtime_dir = vim.fn.stdpath("cache") .. "/runtime"
if not vim.env.XDG_RUNTIME_DIR or not uv.fs_access(vim.env.XDG_RUNTIME_DIR, "rwx") then
	vim.fn.mkdir(runtime_dir, "p")
	vim.env.XDG_RUNTIME_DIR = runtime_dir
end

local options = {
	-- Folding: treesitter-based, all folds open on start.
	-- Use za to toggle, zM/zR to fold/unfold all.
	foldmethod    = "expr",
	foldexpr      = "v:lua.vim.treesitter.foldexpr()",
	foldlevel     = 99,
	foldlevelstart = 99,
	foldenable    = true,
	foldtext      = "",   -- show the actual first line, not the default ugly summary

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
