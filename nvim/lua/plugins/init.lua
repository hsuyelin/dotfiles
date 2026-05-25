-- Plugin load order matters: dependencies before dependents
-- vim.pack.add() installs + adds to rtp; setup() configures

require("plugins.deps")          -- shared deps: plenary, web-devicons, nui, nio

-- UI foundation (colorscheme must be first)
require("plugins.colorschemes")

-- Syntax / parsing (many plugins rely on treesitter)
require("plugins.treesitter")

-- LSP tooling
require("plugins.mason")
require("plugins.completion")
require("plugins.lsp")

-- Search & navigation
require("plugins.telescope")
require("plugins.fzf")
require("plugins.neo-tree")
require("plugins.filesystem")

-- Git
require("plugins.git")

-- UI chrome
require("plugins.ui")
require("plugins.heirline")

-- Editor enhancements
require("plugins.better-editor")
require("plugins.editing")
require("plugins.smear-cursor")

-- Debugger
require("plugins.dap")

-- AI
require("plugins.ai")

-- Language-specific
require("plugins.go")
require("plugins.flutter")
require("plugins.markdown")
require("plugins.swift")
require("plugins.lua")

-- Notes
require("plugins.notes")

-- Misc
require("plugins.competitive")
require("plugins.collaborative")
require("plugins.tmux")
require("plugins.python")
