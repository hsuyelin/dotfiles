---@class utils.bufdelete
local M = {}

---@class utils.bufdelete.Opts
---@field buf? number
---@field force? boolean
---@field filter? fun(buf: number):boolean
---@field wipeout? boolean

---@param opts? number | utils.bufdelete.Opts | fun(buf: number):boolean
function M.delete(opts)
	opts = opts or {}
	opts = type(opts) == "number" and { buf = opts } or opts
	opts = type(opts) == "function" and { filter = opts } or opts
	---@cast opts utils.bufdelete.Opts

	-- delete buffers recursively and return
	if type(opts.filter) == "function" then
		for _, b in ipairs(vim.tbl_filter(opts.filter, vim.api.nvim_list_bufs())) do
			if vim.bo[b].buflisted then
				M.delete(vim.tbl_extend("force", opts, { buf = b, filter = false }))
			end
		end
		return
	end

	-- perform delete operation

	local buf = opts.buf or 0
	buf = buf == 0 and vim.api.nvim_get_current_buf() or buf

	vim.api.nvim_buf_call(buf, function()
		if vim.bo[buf].modified and not opts.force then
			local choice = vim.fn.confirm(("Save changes to %q?"):format(vim.fn.bufname(buf)), "&Yes\n&No\n&Cancel", 1)
			if choice == 0 or choice == 3 then
				return
			end
			if choice == 1 then
				vim.cmd.write()
			end
		end

		for _, win in ipairs(vim.fn.win_findbuf(buf)) do
			vim.api.nvim_win_call(win, function()
				-- if not vim.api.nvim_win_is_valid(win) or vim.api.nvim_win_get_buf(win) ~= buf then
				-- 	return
				-- end

				local alt = vim.fn.bufnr("#")
				if alt ~= buf and vim.fn.buflisted(alt) == 1 then
					vim.api.nvim_win_set_buf(win, alt)
					return
				end

				---@diagnostic disable-next-line: param-type-mismatch
				local has_local = pcall(vim.cmd, "bprevious")
				if has_local and buf ~= vim.api.nvim_win_get_buf(win) then
					return
				end

				local new_buf = vim.api.nvim_create_buf(true, false)
				vim.api.nvim_win_set_buf(win, new_buf)
			end)
		end

		if vim.api.nvim_buf_is_valid(buf) then
			pcall(opts.wipeout and vim.cmd.bwipeout or vim.cmd.bdelete, buf)
		end
	end)
end

return M
