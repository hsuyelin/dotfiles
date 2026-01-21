return {
	root_markers = { ".project", ".git" },
	lsp = {
		servers = {
			-- Lua
			"lua_ls",

			-- Shell
			"shellcheck",
			
			-- SwiftUI
			{
				"sourcekit-lsp",
				mason = false,
			},

			-- C++
			"clangd",

			-- Rust
			"rust_analyzer",

			-- Kotlin
		},
	},
	icons = require("core.configs.icons"),
}
