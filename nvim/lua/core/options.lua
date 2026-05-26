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

-- nvim-treesitter exposes its own foldexpr() that uses its internal parser
-- management. vim.treesitter.foldexpr() uses a separate get_parser() path
-- that cannot find parsers attached by nvim-treesitter (confirmed: sh files
-- show has_ts_parser=false even when syntax highlighting works).
-- Cache on first call so require() is not repeated for every line.
local _fold_fn
_G._FoldExpr = function()
	if not _fold_fn then
		-- 1. nvim-treesitter Lua API (v1 new API)
		local ok, ts = pcall(require, "nvim-treesitter")
		if ok and type(ts.foldexpr) == "function" then
			_fold_fn = ts.foldexpr
		-- 2. nvim-treesitter Vimscript autoload (older API, uses its own parser registry)
		elseif vim.fn.exists("*nvim_treesitter#foldexpr") == 1 then
			_fold_fn = function() return vim.fn["nvim_treesitter#foldexpr"]() end
		else
			-- 3. Neovim built-in fallback
			_fold_fn = vim.treesitter.foldexpr
		end
	end
	return _fold_fn()
end

local options = {
	-- Folding: treesitter-based, all folds open on start.
	-- Use za to toggle, zM/zR to fold/unfold all.
	foldmethod    = "expr",
	foldexpr      = "v:lua._FoldExpr()",
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

-- Treesitter fold setup -------------------------------------------------------
-- vim.treesitter.foldexpr() needs the parser attached via vim.treesitter.start().
-- The sh → bash mapping is registered by nvim-treesitter, but its timing is not
-- guaranteed before FileType fires. Register it here at startup so get_lang()
-- always resolves correctly, then pass the language explicitly to start().
vim.treesitter.language.register("bash", { "sh", "zsh" })

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("TsFoldSetup", { clear = true }),
	callback = function(ev)
		local buf = ev.buf
		if vim.bo[buf].buftype ~= "" then return end
		local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
		if not lang then return end
		-- Attach parser with explicit language so get_parser() can find it.
		local ok = pcall(vim.treesitter.start, buf, lang)
		if not ok then return end
		vim.schedule(function()
			if vim.api.nvim_buf_is_valid(buf) then
				vim.api.nvim_buf_call(buf, function()
					vim.cmd("silent! normal! zx")
				end)
			end
		end)
	end,
})

-- :FoldDiag — print fold state at the cursor line for debugging.
vim.api.nvim_create_user_command("FoldDiag", function()
	local buf  = vim.api.nvim_get_current_buf()
	local lnum = vim.api.nvim_win_get_cursor(0)[1]
	local ft   = vim.bo[buf].filetype

	local lang = vim.treesitter.language.get_lang(ft)

	local has_parser = false
	pcall(function() has_parser = vim.treesitter.get_parser(buf) ~= nil end)

	local has_parser_bash = false
	pcall(function() has_parser_bash = vim.treesitter.get_parser(buf, "bash") ~= nil end)

	-- Capture why vim.treesitter.start() fails (if it does)
	local ts_start_ok, ts_start_err = true, nil
	if lang then
		ts_start_ok, ts_start_err = pcall(vim.treesitter.start, buf, lang)
	end

	local nvimts_foldexpr = nil
	pcall(function()
		local ts = require("nvim-treesitter")
		nvimts_foldexpr = type(ts.foldexpr) == "function" and ts.foldexpr(lnum) or "no foldexpr"
	end)

	local vimscript_fn_exists = vim.fn.exists("*nvim_treesitter#foldexpr") == 1
	local vimscript_foldexpr = nil
	if vimscript_fn_exists then
		pcall(function() vimscript_foldexpr = vim.fn["nvim_treesitter#foldexpr"]() end)
	end

	vim.print({
		filetype                   = ft,
		lang_from_get_lang         = lang,
		foldmethod                 = vim.wo.foldmethod,
		foldexpr                   = vim.wo.foldexpr,
		foldlevel_at_line          = vim.fn.foldlevel(lnum),
		has_ts_parser              = has_parser,
		has_ts_parser_bash         = has_parser_bash,
		ts_start_ok                = ts_start_ok,
		ts_start_err               = ts_start_err,
		vim_ts_foldexpr            = vim.treesitter.foldexpr(lnum),
		nvimts_lua_foldexpr        = nvimts_foldexpr,
		nvimts_vimscript_exists    = vimscript_fn_exists,
		nvimts_vimscript_foldexpr  = vimscript_foldexpr,
		global_FoldExpr            = _G._FoldExpr and _G._FoldExpr() or "not defined",
	})
end, { desc = "Diagnose fold state at cursor" })
