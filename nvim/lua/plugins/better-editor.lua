---@diagnostic disable: missing-parameter
local gh = function(r) return 'https://github.com/' .. r end

vim.pack.add({
  gh('lukas-reineke/indent-blankline.nvim'),
  gh('HiPhish/rainbow-delimiters.nvim'),
  gh('folke/which-key.nvim'),
  gh('folke/trouble.nvim'),
  gh('mrjones2014/smart-splits.nvim'),
  gh('karb94/neoscroll.nvim'),
  gh('folke/todo-comments.nvim'),
})

-- Use custom group names so we fully control the colors via hooks.
-- RainbowDelimiterX groups from the plugin are only available after it loads
-- and vanish on colorscheme reload — hooks.HIGHLIGHT_SETUP fires every time.
local _rainbow_hl = {
  "RainbowRed",
  "RainbowYellow",
  "RainbowBlue",
  "RainbowOrange",
  "RainbowGreen",
  "RainbowViolet",
  "RainbowCyan",
}

local ibl_hooks = require("ibl.hooks")
ibl_hooks.register(ibl_hooks.type.HIGHLIGHT_SETUP, function()
  -- Catppuccin Mocha palette
  vim.api.nvim_set_hl(0, "RainbowRed",    { fg = "#F38BA8" })
  vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#F9E2AF" })
  vim.api.nvim_set_hl(0, "RainbowBlue",   { fg = "#89B4FA" })
  vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#FAB387" })
  vim.api.nvim_set_hl(0, "RainbowGreen",  { fg = "#A6E3A1" })
  vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#CBA6F7" })
  vim.api.nvim_set_hl(0, "RainbowCyan",   { fg = "#89DCEB" })
end)

require("ibl").setup({
  scope = {
    show_start = true,   -- underline on the opening bracket line
    show_end   = true,   -- underline on the closing bracket line
    highlight  = _rainbow_hl,
  },
})

require("rainbow-delimiters.setup").setup({
  highlight = _rainbow_hl,
})

-- which-key: defer (only needed on first keypress)
vim.schedule(function()
  require("which-key").setup({})
end)

require("trouble").setup({
  auto_preview = false,
  auto_refresh = true,
  auto_close = true,
})

vim.keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics" })
vim.keymap.set("n", "<leader>xf", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Buffer Diagnostics" })
vim.keymap.set("n", "<leader>xs", "<cmd>Trouble lsp toggle<cr>", { desc = "LSP references/definitions/..." })
vim.keymap.set("n", "<c-s-p>", function()
  require("trouble").prev()
  require("trouble").jump()
end, { desc = "Previous Diagnostics" })
vim.keymap.set("n", "<c-s-n>", function()
  require("trouble").next()
  require("trouble").jump()
end, { desc = "Next Diagnostics" })

-- neoscroll: defer (only needed when scrolling)
vim.schedule(function()
  require("neoscroll").setup({
    mappings = { "<C-u>", "<C-d>", "<C-b>", "<C-f>", "zt", "zz", "zb" },
    easing = "quadratic",
    duration_multiplier = 0.4,
  })
end)

require("todo-comments").setup()
