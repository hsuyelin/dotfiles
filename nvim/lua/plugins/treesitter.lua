-- NOTE: After first install, run :TSUpdate to download language parsers.
local gh = function(r) return 'https://github.com/' .. r end

vim.pack.add({
  { src = gh('nvim-treesitter/nvim-treesitter'), version = 'main' },
  { src = gh('nvim-treesitter/nvim-treesitter-textobjects'), version = 'main' },
  gh('HiPhish/rainbow-delimiters.nvim'),
})

require("nvim-treesitter").setup()

-- Auto-install parsers on first open
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("ts_auto_install", { clear = true }),
  callback = function()
    local ft = vim.bo.filetype
    if ft == "" then return end
    local lang = vim.treesitter.language.get_lang(ft)
    if lang and not pcall(vim.treesitter.language.inspect, lang) then
      pcall(function() vim.cmd("TSInstall " .. lang) end)
    end
  end,
})

-- Treesitter textobjects: select
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

-- Treesitter textobjects: swap
vim.keymap.set("n", "<leader>cp", function()
  require("nvim-treesitter-textobjects.swap").swap_next("@parameter.outer")
end, { desc = "Swap next parameter" })
vim.keymap.set("n", "<leader>cP", function()
  require("nvim-treesitter-textobjects.swap").swap_previous("@parameter.outer")
end, { desc = "Swap prev parameter" })
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

-- Treesitter textobjects: move
local move = require("nvim-treesitter-textobjects.move")
local motions = {
  { "]p", "[p", "]P", "[P", "@parameter.outer" },
  { "]f", "[f", "]F", "[F", "@function.outer" },
  { "]c", "[c", "]C", "[C", "@class.outer" },
  { "]o", "[o", "]O", "[O", "@loop.outer" },
}
for _, m in ipairs(motions) do
  vim.keymap.set({ "n", "x", "o" }, m[1], function() move.goto_next_start(m[5], "textobjects") end)
  vim.keymap.set({ "n", "x", "o" }, m[2], function() move.goto_previous_start(m[5], "textobjects") end)
  vim.keymap.set({ "n", "x", "o" }, m[3], function() move.goto_next_end(m[5], "textobjects") end)
  vim.keymap.set({ "n", "x", "o" }, m[4], function() move.goto_previous_end(m[5], "textobjects") end)
end
vim.keymap.set({ "n", "x", "o" }, "]z", function() move.goto_next_start("@fold", "folds") end)
vim.keymap.set({ "n", "x", "o" }, "[z", function() move.goto_previous_start("@fold", "folds") end)
vim.keymap.set({ "n", "x", "o" }, "]m", function() move.goto_next_start("@function.outer", "textobjects") end)
vim.keymap.set({ "n", "x", "o" }, "]]", function() move.goto_next_start("@class.outer", "textobjects") end)

-- Repeat movement with ; and ,
local ts_repeat = require("nvim-treesitter-textobjects.repeatable_move")
vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat.repeat_last_move_next)
vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat.repeat_last_move_previous)

-- Rainbow delimiters
require("rainbow-delimiters.setup").setup({
  strategy = {
    [""] = "rainbow-delimiters.strategy.global",
    commonlisp = "rainbow-delimiters.strategy.local",
  },
  query = {
    [""] = "rainbow-delimiters",
    latex = "rainbow-blocks",
  },
  highlight = {
    "RainbowDelimiterRed", "RainbowDelimiterYellow", "RainbowDelimiterBlue",
    "RainbowDelimiterOrange", "RainbowDelimiterGreen", "RainbowDelimiterViolet",
    "RainbowDelimiterCyan",
  },
})
