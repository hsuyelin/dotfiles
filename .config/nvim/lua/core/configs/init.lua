return {
	root_markers = { ".project", ".git" },
	lsp = {
		servers = {
			-- Lua
			"lua_ls",

			-- Shell
			"shellcheck",

			-- Swift / Objective-C (Xcode toolchain)
			{
				"sourcekit-lsp",
				mason = false,
			},

			-- C / C++ / Objective-C
			"clangd",

			-- Rust
			"rust_analyzer",

			-- Go
			"gopls",

			-- Python
			"pyright",
		},
	},
	icons = require("core.configs.icons"),
}
