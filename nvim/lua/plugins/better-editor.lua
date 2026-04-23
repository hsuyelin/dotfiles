---@diagnostic disable: missing-parameter
local gh = function(r) return 'https://github.com/' .. r end

vim.pack.add({
  gh('lukas-reineke/indent-blankline.nvim'),
  gh('folke/which-key.nvim'),
  gh('folke/trouble.nvim'),
  gh('mrjones2014/smart-splits.nvim'),
  gh('karb94/neoscroll.nvim'),
  gh('folke/todo-comments.nvim'),
})

require("ibl").setup({
  scope = {
    show_end = false,
    show_start = false,
  },
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
