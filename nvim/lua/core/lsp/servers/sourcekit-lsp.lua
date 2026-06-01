return {
	cmd = { "sourcekit-lsp" },
	filetypes = { "swift" },
	root_markers = vim.list_extend(
		vim.deepcopy(core.configs.root_markers),
		{ "buildServer.json", "*.xcodeproj", "*.xcworkspace", "Package.swift" }
	),
}
