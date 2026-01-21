return {
	cmd = { "sourcekit-lsp" },
	filetypes = { "swift" },
	root_markers = vim.list_extend(core.configs.root_markers, { "*.xcodeproj" }),
}
