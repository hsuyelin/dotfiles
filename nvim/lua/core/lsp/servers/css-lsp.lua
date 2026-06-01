return {
	cmd = { "vscode-css-language-server", "--stdio" },
	filetypes = { "css", "scss", "less" },
	init_options = { provideFormatter = true },
	root_markers = vim.list_extend(vim.deepcopy(core.configs.root_markers), { "package.json" }),
	settings = {
		css = { validate = true },
		scss = { validate = true },
		less = { validate = true },
	},
}
