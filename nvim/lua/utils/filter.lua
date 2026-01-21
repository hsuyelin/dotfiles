local M = {}

---@class utils.filter.Opts
---@field keyword string The keyword to search for
---@field buf? number The source buffer (default: current buffer)

---@param opts string | utils.filter.Opts
function M.run(opts)
	-- Normalize options: allow passing a string directly
	opts = type(opts) == "string" and { keyword = opts } or opts
	---@cast opts utils.filter.Opts

	if not opts.keyword or opts.keyword == "" then
		vim.notify("Filter: Keyword is required", vim.log.levels.WARN)
		return
	end

	local src_buf = opts.buf or 0
	if not vim.api.nvim_buf_is_valid(src_buf) then
		src_buf = vim.api.nvim_get_current_buf()
	end

	local lines = vim.api.nvim_buf_get_lines(src_buf, 0, -1, false)
	local filtered_lines = {}
	local keyword = opts.keyword:lower()

	for _, line in ipairs(lines) do
		if line:lower():find(keyword, 1, true) then
			table.insert(filtered_lines, line)
		end
	end

	if #filtered_lines == 0 then
		vim.notify(("Filter: No lines found containing '%s'"):format(opts.keyword), vim.log.levels.INFO)
		return
	end

	local new_buf = vim.api.nvim_create_buf(false, true) -- create scratch buffer
	vim.api.nvim_buf_set_lines(new_buf, 0, -1, false, filtered_lines)

	-- Open in vertical split
	vim.cmd.vsplit()
	vim.api.nvim_win_set_buf(0, new_buf)

	-- Set buffer options for scratch behavior
	vim.bo[new_buf].bufhidden = "wipe"
	vim.bo[new_buf].swapfile = false
	vim.bo[new_buf].filetype = "text" -- optional

	-- Set `q` to close the buffer
	vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = new_buf, silent = true, nowait = true })

	vim.notify(("Filter: Extracted %d lines"):format(#filtered_lines), vim.log.levels.INFO)
end

-- Register command
vim.api.nvim_create_user_command("Filter", function(args)
	M.run({ keyword = args.args })
end, { nargs = 1 })

return M
