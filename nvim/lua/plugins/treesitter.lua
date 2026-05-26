-- NOTE: After first install, run :TSUpdate to download language parsers.
local gh = function(r) return 'https://github.com/' .. r end

vim.pack.add({
  { src = gh('nvim-treesitter/nvim-treesitter'), version = 'master' },
  { src = gh('nvim-treesitter/nvim-treesitter-textobjects'), version = 'master' },
  gh('HiPhish/rainbow-delimiters.nvim'),
})

local ENSURE_INSTALLED = {
  "bash", "c", "cpp", "diff", "go", "gomod", "gosum", "gowork",
  "html", "javascript", "json", "lua", "markdown", "markdown_inline",
  "python", "query", "regex", "swift", "vim", "vimdoc", "yaml",
}

local legacy_ok, legacy_configs = pcall(require, "nvim-treesitter.configs")
if legacy_ok then
  legacy_configs.setup({
    ensure_installed = ENSURE_INSTALLED,
    auto_install = false,
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false,
    },
    indent = {
      enable = true,
      disable = { "swift" },
    },
  })
else
  local modern_ok, modern_treesitter = pcall(require, "nvim-treesitter")
  if modern_ok and type(modern_treesitter.setup) == "function" then
    modern_treesitter.setup()
  end
end

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
  highlight = {
    "RainbowDelimiterRed", "RainbowDelimiterYellow", "RainbowDelimiterBlue",
    "RainbowDelimiterOrange", "RainbowDelimiterGreen", "RainbowDelimiterViolet",
    "RainbowDelimiterCyan",
  },
})

-- Auto-install any missing parsers from ENSURE_INSTALLED on first launch.
-- vim.pack.add() has no build hook, so ensure_installed alone is not reliable.
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    local install_ok, install = pcall(require, "nvim-treesitter.install")
    if not install_ok then return end
    local parsers_ok, parsers = pcall(require, "nvim-treesitter.parsers")
    if not parsers_ok then return end
    local missing = {}
    for _, lang in ipairs(ENSURE_INSTALLED) do
      local parser_path = vim.fn.stdpath("data") .. "/site/parser/" .. lang .. ".so"
      if vim.fn.filereadable(parser_path) == 0 then
        table.insert(missing, lang)
      end
    end
    if #missing > 0 then
      vim.notify(
        "[treesitter] Installing missing parsers: " .. table.concat(missing, ", "),
        vim.log.levels.INFO
      )
      install.install(missing)
    end
  end,
})
