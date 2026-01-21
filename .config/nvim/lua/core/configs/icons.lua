local icons = {
	diagnostics = {
		Error = " ",
		Warn = " ",
		Hint = " ",
		Info = " ",
	},
}

vim.diagnostic.config({
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = icons.diagnostics.Error,
			[vim.diagnostic.severity.WARN] = icons.diagnostics.Warn,
			[vim.diagnostic.severity.HINT] = icons.diagnostics.Hint,
			[vim.diagnostic.severity.INFO] = icons.diagnostics.Info,
		},
	},
})

return icons
