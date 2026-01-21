return {
	{
		"saghen/blink.cmp",
		-- optional: provides snippets for the snippet source
		-- dependencies = { "rafamadriz/friendly-snippets" },
		-- use a release tag to download pre-built binaries
		version = "1.*",
		-- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
		-- build = 'cargo build --release',
		-- If you use nix, you can build from source using latest nightly rust with:
		-- build = 'nix run .#build-plugin',

		---@module 'blink.cmp'
		---@type blink.cmp.Config
		opts = {
			-- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
			-- 'super-tab' for mappings similar to vscode (tab to accept)
			-- 'enter' for enter to accept
			-- 'none' for no mappings
			--
			-- All presets have the following mappings:
			-- C-space: Open menu or open docs if already open
			-- C-n/C-p or Up/Down: Select next/previous item
			-- C-e: Hide menu
			-- C-k: Toggle signature help (if signature.enabled = true)
			--
			-- See :h blink-cmp-config-keymap for defining your own keymap
			keymap = { preset = "super-tab" },

			appearance = {
				-- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
				-- Adjusts spacing to ensure icons are aligned
				nerd_font_variant = "mono",
			},

			-- (Default) Only show the documentation popup when manually triggered
			completion = {
				documentation = { auto_show = true, auto_show_delay_ms = 0 },
				menu = {
					auto_show = true,
					auto_show_delay_ms = 0,
					draw = {
						columns = {
							{ "kind_icon" },
							{ "label", "label_description", gap = 1 },
							{ "source_name" },
						},
					},
				},
			},

			-- Default list of enabled providers defined so that you can extend it
			-- elsewhere in your config, without redefining it, due to `opts_extend`

			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
			},

			-- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
			-- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
			-- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
			--
			-- See the fuzzy documentation for more information
			fuzzy = { implementation = "prefer_rust_with_warning" },

			cmdline = {
				enabled = true,
				keymap = {
					["<C-k>"] = { "accept" },
					["<TAB>"] = { "accept", "fallback" },
					["<CR>"] = { "accept_and_enter", "fallback" },
				},
				sources = { "buffer", "cmdline" },
				completion = {
					menu = { auto_show = true },
					list = {
						selection = {
							preselect = true,
							auto_insert = true,
						},
					},
					ghost_text = { enabled = true },
				},
			},
		},
		term = {
			enabled = false,
			keymap = { preset = "inherit" }, -- Inherits from top level `keymap` config when not set
			sources = {},
			completion = {
				trigger = {
					show_on_blocked_trigger_characters = {},
					show_on_x_blocked_trigger_characters = nil, -- Inherits from top level `completion.trigger.show_on_blocked_trigger_characters` config when not set
				},
				-- Inherits from top level config options when not set
				list = {
					selection = {
						-- When `true`, will automatically select the first item in the completion list
						preselect = nil,
						-- When `true`, inserts the completion item automatically when selecting it
						auto_insert = nil,
					},
				},
				-- Whether to automatically show the window when new completion items are available
				menu = { auto_show = nil },
				-- Displays a preview of the selected item on the current line
				ghost_text = { enabled = nil },
			},
		},
		opts_extend = { "sources.default" },
	},
}
