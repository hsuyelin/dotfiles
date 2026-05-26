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
		-- loadview from an old view file may still write setlocal foldmethod=manual
		-- even after viewoptions no longer includes "folds". Re-apply treesitter
		-- folding unconditionally for normal file buffers. vim.schedule defers until
		-- FileType fires and nvim-treesitter attaches the parser, so foldexpr()
		-- has a live parse tree to query.
		if vim.bo.buftype == "" then
			vim.schedule(function()
				vim.opt_local.foldmethod = "expr"
				vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
				vim.cmd("silent! normal! zx")
			end)
		end
	end,
})
