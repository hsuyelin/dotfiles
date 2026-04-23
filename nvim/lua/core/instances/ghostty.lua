-- Ghostty-specific nvim config
-- Loaded when GHOSTTY_RESOURCES_DIR is set (Ghostty injects this automatically)

-- Ghostty supports true 24-bit color, kitty keyboard protocol, and bracketed
-- paste natively. nvim 0.10+ auto-detects all of these via $TERM_PROGRAM.
-- No manual overrides needed for core functionality.

-- Enable undercurl for Ghostty (used by diagnostics and spell checking)
vim.cmd([[let &t_Cs = "\e[4:3m"]])
vim.cmd([[let &t_Ce = "\e[4:0m"]])
