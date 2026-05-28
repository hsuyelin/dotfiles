_G.core = {}

core.configs = {
	root_markers = { ".project", ".git" },
	lsp = {
		servers = {
			-- Lua
			"lua_ls",

			-- Shell (bash-language-server, uses shellcheck internally)
			"bashls",

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
	icons = require("core.icons"),
}

require("core.options")
require("core.instances")
