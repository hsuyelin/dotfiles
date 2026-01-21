return {
	cmd = { "lua-language-server" },
	filetypes = { "lua" },
	root_markers = vim.list_extend(core.configs.root_markers, { ".luarc.json" }),
	settings = {
		Lua = {
			hint = {
				enable = true,
			},
		},
	},
}
