vim.api.nvim_create_autocmd("FileType", {
	pattern = { "c", "cpp", "objc", "objcpp" },
	callback = function(ev)
		vim.keymap.set("n", "gA", function()
			local params = vim.lsp.util.make_text_document_params(ev.buf)
			vim.lsp.buf_request(ev.buf, "textDocument/switchSourceHeader", params, function(err, result)
				if err or not result then
					vim.notify("No alternate file found", vim.log.levels.WARN)
					return
				end
				vim.cmd("edit " .. vim.fn.fnameescape(vim.uri_to_fname(result)))
			end)
		end, { buffer = ev.buf, desc = "Switch header ↔ source (clangd)" })
	end,
})

return {
	cmd = { "clangd" },
	filetypes = { "c", "cpp", "objc", "objcpp" },
	root_markers = core.configs.root_markers,
}
