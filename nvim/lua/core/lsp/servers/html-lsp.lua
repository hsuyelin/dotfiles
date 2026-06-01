return {
	cmd = { "vscode-html-language-server", "--stdio" },
	-- TODO: integrate this
	root_markers = vim.list_extend(vim.deepcopy(core.configs.root_markers), { "package.json" }),
	filetypes = { "html" },
	init_options = {
		provideFormatter = true,
		embeddedLanguages = { css = true, javascript = true },
		configurationSection = { "html", "css", "javascript" },
	},
}
