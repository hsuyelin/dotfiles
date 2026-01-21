local usergroup = vim.api.nvim_create_augroup("UserViews", { clear = true })

-- -- folds restore
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
