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
	-- map jk
	vim.keymap.set("t", "jk", [[<C-\><C-n>]], { buffer = buf, silent = true })
	-- close terminal window on <C-c>
	vim.keymap.set("t", "<C-c>", [[<C-\><C-n><C-w>c]], { buffer = buf, silent = true })
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
				vim.api.nvim_buf_delete(self.buf, { force = true })
				for key, value in ipairs(terminals) do
					if value.buf == self.buf then
						table.remove(terminals, key)
					end
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

return M
