require("core")
require("utils")
require("installer")
require("keymaps")

vim.api.nvim_command([[colorscheme catppuccin]])
-- vim.cmd("colorscheme catppuccin-frappe")

-- loading configs
require("configs")
