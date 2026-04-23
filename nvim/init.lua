-- Track startup time (replaces lazy.stats)
vim.g.nvim_start_time = vim.uv.hrtime()

require("core")
require("utils")
require("plugins")
require("core.keymaps")
