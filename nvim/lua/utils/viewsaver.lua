-- Only save cursor position; exclude folds so mkview never writes setlocal
-- foldmethod/foldexpr lines that would override treesitter fold settings on
-- the next loadview call.
vim.opt.viewoptions:remove("folds")

local usergroup = vim.api.nvim_create_augroup("UserViews", { clear = true })

vim.api.nvim_create_autocmd({ "BufUnload", "VimLeave" }, {
	pattern = "*",
	group = usergroup,
	callback = function(data)
		if data.file == "" then
			return
		end
		vim.cmd("silent! mkview!")
	end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
	pattern = "*",
	group = usergroup,
	callback = function(data)
		if data.file == "" then
			return
		end
		vim.cmd("silent! loadview")
	end,
})
