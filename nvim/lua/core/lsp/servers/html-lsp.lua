return {
	cmd = { "vscode-html-language-server", "--stdio" },
	-- TODO: integrate this
	root_markers = vim.list_extend(core.configs.root_markers, { ".luarc.json" }),
	filetypes = { "html" },
	init_options = {
		provideFormatter = true,
		embeddedLanguages = { css = true, javascript = true },
		configurationSection = { "html", "css", "javascript" },
	},
}
