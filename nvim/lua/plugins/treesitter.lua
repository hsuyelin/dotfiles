return {
	{
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		branch = "main",
		build = ":TSUpdate",
		opts = {},
	},
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		branch = "main",
		opts = {
			select = {
				-- Automatically jump forward to textobj, similar to targets.vim
				lookahead = true,
				-- You can choose the select mode (default is charwise 'v')
				--
				-- Can also be a function which gets passed a table with the keys
				-- * query_string: eg '@function.inner'
				-- * method: eg 'v' or 'o'
				-- and should return the mode ('v', 'V', or '<c-v>') or a table
				-- mapping query_strings to modes.
				selection_modes = {
					["@parameter.outer"] = "v", -- charwise
					["@function.outer"] = "V", -- linewise
					["@class.outer"] = "<c-v>", -- blockwise
				},
				-- If you set this to `true` (default is `false`) then any textobject is
				-- extended to include preceding or succeeding whitespace. Succeeding
				-- whitespace has priority in order to act similarly to eg the built-in
				-- `ap`.
				--
				-- Can also be a function which gets passed a table with the keys
				-- * query_string: eg '@function.inner'
				-- * selection_mode: eg 'v'
				-- and should return true of false
				include_surrounding_whitespace = false,
			},
		},
		config = function()
			-- Select
			vim.keymap.set({ "x", "o" }, "af", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "if", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@function.inner", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "ac", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@class.outer", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "ic", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@class.inner", "textobjects")
			end)
			-- You can also use captures from other query groups like `locals.scm`
			-- vim.keymap.set({ "x", "o" }, "as", function()
			-- 	require("nvim-treesitter-textobjects.select").select_textobject("@local.scope", "locals")
			-- end)
			-- Swap
			vim.keymap.set("n", "<leader>cp", function()
				require("nvim-treesitter-textobjects.swap").swap_next("@parameter.outer")
			end, { desc = "Swap next parameter" })
			vim.keymap.set("n", "<leader>cP", function()
				require("nvim-treesitter-textobjects.swap").swap_previous("@parameter.outer")
			end, { desc = "Swap previous parameter" })
			vim.keymap.set("n", "<leader>cf", function()
				require("nvim-treesitter-textobjects.swap").swap_next("@function.outer")
			end)
			vim.keymap.set("n", "<leader>cF", function()
				require("nvim-treesitter-textobjects.swap").swap_previous("@function.outer")
			end)
			vim.keymap.set("n", "<leader>cc", function()
				require("nvim-treesitter-textobjects.swap").swap_next("@class.outer")
			end)
			vim.keymap.set("n", "<leader>cC", function()
				require("nvim-treesitter-textobjects.swap").swap_previous("@class.outer")
			end)
			-- Move
			-- parameter
			vim.keymap.set({ "n", "x", "o" }, "]p", function()
				require("nvim-treesitter-textobjects.move").goto_next_start("@parameter.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "]P", function()
				require("nvim-treesitter-textobjects.move").goto_next_end("@parameter.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "[p", function()
				require("nvim-treesitter-textobjects.move").goto_previous_start("@parameter.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "[P", function()
				require("nvim-treesitter-textobjects.move").goto_previous_end("@parameter.outer", "textobjects")
			end)
			-- function
			vim.keymap.set({ "n", "x", "o" }, "]f", function()
				require("nvim-treesitter-textobjects.move").goto_next_start("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "]F", function()
				require("nvim-treesitter-textobjects.move").goto_next_end("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "[f", function()
				require("nvim-treesitter-textobjects.move").goto_previous_start("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "[F", function()
				require("nvim-treesitter-textobjects.move").goto_previous_end("@function.outer", "textobjects")
			end)
			-- class
			vim.keymap.set({ "n", "x", "o" }, "]c", function()
				require("nvim-treesitter-textobjects.move").goto_next_start("@class.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "]C", function()
				require("nvim-treesitter-textobjects.move").goto_next_end("@class.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "[c", function()
				require("nvim-treesitter-textobjects.move").goto_previous_start("@class.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "[C", function()
				require("nvim-treesitter-textobjects.move").goto_previous_end("@class.outer", "textobjects")
			end)
			-- loop
			vim.keymap.set({ "n", "x", "o" }, "]o", function()
				require("nvim-treesitter-textobjects.move").goto_next_start("@loop.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "]O", function()
				require("nvim-treesitter-textobjects.move").goto_next_end("@loop.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "[o", function()
				require("nvim-treesitter-textobjects.move").goto_previous_start("@loop.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "[O", function()
				require("nvim-treesitter-textobjects.move").goto_previous_end("@loop.outer", "textobjects")
			end)
			-- NOTE: don't know what this means
			-- vim.keymap.set({ "n", "x", "o" }, "]s", function()
			-- 	require("nvim-treesitter-textobjects.move").goto_next_start("@local.scope", "locals")
			-- end)
			-- fold
			vim.keymap.set({ "n", "x", "o" }, "]z", function()
				require("nvim-treesitter-textobjects.move").goto_next_start("@fold", "folds")
			end)
			vim.keymap.set({ "n", "x", "o" }, "[z", function()
				require("nvim-treesitter-textobjects.move").goto_previous_start("@fold", "folds")
			end)
			vim.keymap.set({ "n", "x", "o" }, "]m", function()
				require("nvim-treesitter-textobjects.move").goto_next_start("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "]]", function()
				require("nvim-treesitter-textobjects.move").goto_next_start("@class.outer", "textobjects")
			end)
			-- repeat
			local ts_repeat_move = require("nvim-treesitter-textobjects.repeatable_move")
			-- Repeat movement with ; and ,
			vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move_next)
			vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_previous)
		end,
	},
	{
		"HiPhish/rainbow-delimiters.nvim",
		config = function()
			require("rainbow-delimiters.setup").setup({
				-- strategy = {
				-- 	[""] = "rainbow-delimiters.strategy.global",
				-- 	commonlisp = "rainbow-delimiters.strategy.local",
				-- },
				-- query = {
				-- 	[""] = "rainbow-delimiters",
				-- 	latex = "rainbow-blocks",
				-- },
				-- highlight = {
				-- 	"RainbowDelimiterRed",
				-- 	"RainbowDelimiterYellow",
				-- 	"RainbowDelimiterBlue",
				-- 	"RainbowDelimiterOrange",
				-- 	"RainbowDelimiterGreen",
				-- 	"RainbowDelimiterViolet",
				-- 	"RainbowDelimiterCyan",
				-- },
				-- blacklist = { "c", "cpp" },
			})
		end,
	},
}
