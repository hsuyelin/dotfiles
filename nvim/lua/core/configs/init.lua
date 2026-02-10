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

			-- Go
			"gopls",

			-- Rust
			"rust_analyzer",

			-- Python
			"pyright",
		},
	},
	icons = require("core.configs.icons"),
}
