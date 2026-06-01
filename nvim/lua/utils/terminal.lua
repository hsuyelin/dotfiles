local M = {}

M.__index = M

---@type table<terminal.Term>
local terminals = {}

---@class terminal.Term
---@field buf number
---@field cmd? string|string[]

---@class terminal.OpenConfig
---@field parent number
---@field auto_enter? boolean

---@private
---@param buf number
local function buf_setup(buf)
	-- apply autocmds
	-- local augroup = vim.api.nvim_create_augroup("terminal", { clear = true })
	-- vim.api.nvim_create_autocmd("BufEnter", {
	-- 	group = augroup,
	-- 	buffer = buf,
	-- 	callback = function()
	-- 		-- -- auto insert
	-- 		-- vim.api.nvim_buf_call(buf, function()
	-- 		-- 	vim.cmd.startinsert()
	-- 		-- end)
	-- 	end,
	-- })
	vim.keymap.set("t", "jk", [[<C-\><C-n>]], { buffer = buf, silent = true })
	-- Window navigation from terminal mode (smart-splits handles <C-\><C-n> internally).
	local ss = require("smart-splits")
	vim.keymap.set("t", "<C-h>", ss.move_cursor_left,  { buffer = buf, silent = true })
	vim.keymap.set("t", "<C-j>", ss.move_cursor_down,  { buffer = buf, silent = true })
	vim.keymap.set("t", "<C-k>", ss.move_cursor_up,    { buffer = buf, silent = true })
	vim.keymap.set("t", "<C-l>", ss.move_cursor_right, { buffer = buf, silent = true })
	-- Clear screen: <M-l> sends Ctrl-L to the shell, bypassing the navigation mapping.
	vim.keymap.set("t", "<M-l>", function()
		vim.fn.chansend(vim.bo.channel, "\12")
	end, { buffer = buf, silent = true })
	-- toggle (hide) the terminal from inside terminal mode
	vim.keymap.set("t", "<leader>!", function()
		local M = require("utils.terminal")
		M.toggle()
	end, { buffer = buf, silent = true })
end

---@param cmd? string
---@return terminal.Term
function M.new(cmd)
	---@type terminal.Term
	local self = setmetatable({}, M)
	self.cmd = cmd or vim.o.shell
	-- create buf
	self.buf = vim.api.nvim_create_buf(false, true)
	-- run cmd
	vim.api.nvim_buf_call(self.buf, function()
		vim.fn.termopen(self.cmd, {
			on_exit = function()
				-- Remove from list first; if buf_delete throws, the list is
				-- already clean and toggle() will never hit the stale entry.
				for key, value in ipairs(terminals) do
					if value.buf == self.buf then
						table.remove(terminals, key)
						break
					end
				end
				if vim.api.nvim_buf_is_valid(self.buf) then
					pcall(vim.api.nvim_buf_delete, self.buf, { force = true })
				end
			end,
		})
	end)
	buf_setup(self.buf)
	-- add to list
	table.insert(terminals, self)
	return self
end

---@param win? number
---@param opts? terminal.OpenConfig
function M:open(win, opts)
	opts = opts or {}

	if not win then
		-- search for it
		local tab = vim.api.nvim_get_current_tabpage()
		local wins = vim.api.nvim_tabpage_list_wins(tab)
		for _, w in ipairs(wins) do
			if vim.api.nvim_win_is_valid(w) and vim.api.nvim_win_get_buf(w) == self.buf then
				win = w
				break
			end
		end
	end

	if not win then
		-- using parent to create it
		local parent = opts.parent or vim.api.nvim_get_current_win()
		vim.api.nvim_win_call(parent, function()
			vim.cmd("silent noswapfile belowright 12 split")
			win = vim.api.nvim_get_current_win()
		end)
	end

	-- use current win
	win = win or vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(win, self.buf)

	if opts.auto_enter then
		vim.api.nvim_set_current_win(win)
	end
end

function M.list()
	return terminals
end

function M.select()
	local list = M.list()

	if #list == 0 then
		M.new() -- create a new
	end
	list[1]:open(nil, { auto_enter = true, auto_insert = true })
end

-- Toggle the first terminal: hide it if visible in the current tab, else show it.
function M.toggle()
	-- Prune entries whose buffers were deleted outside our on_exit.
	for i = #terminals, 1, -1 do
		if not vim.api.nvim_buf_is_valid(terminals[i].buf) then
			table.remove(terminals, i)
		end
	end
	local list = M.list()
	if #list == 0 then
		M.new()
		list = M.list()
	end
	local term = list[1]
	local tab = vim.api.nvim_get_current_tabpage()
	for _, w in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
		if vim.api.nvim_win_is_valid(w) and vim.api.nvim_win_get_buf(w) == term.buf then
			vim.api.nvim_win_close(w, false)
			return
		end
	end
	term:open(nil, { auto_enter = true })
end

-- Open lazygit in a centered floating window; closes cleanly on exit.
function M.lazygit()
	local width  = math.floor(vim.o.columns * 0.92)
	local height = math.floor(vim.o.lines   * 0.88)
	local col    = math.floor((vim.o.columns - width)  / 2)
	local row    = math.floor((vim.o.lines   - height) / 2)

	local buf = vim.api.nvim_create_buf(false, true)
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width    = width,
		height   = height,
		col      = col,
		row      = row,
		style    = "minimal",
		border   = "rounded",
	})

	vim.fn.termopen("lazygit", {
		on_exit = function()
			-- Defer to next event-loop tick: Neovim finishes its own terminal
			-- cleanup before we touch the window/buffer, avoiding TOCTOU crashes.
			vim.schedule(function()
				if vim.api.nvim_win_is_valid(win) then
					pcall(vim.api.nvim_win_close, win, true)
				end
				if vim.api.nvim_buf_is_valid(buf) then
					pcall(vim.api.nvim_buf_delete, buf, { force = true })
				end
			end)
		end,
	})
	vim.cmd("startinsert")
end

return M
