local gh = function(r) return 'https://github.com/' .. r end

vim.pack.add({
  gh('kylechui/nvim-surround'),
  gh('folke/flash.nvim'),
  gh('folke/ts-comments.nvim'),
  gh('windwp/nvim-autopairs'),
  gh('chentoast/marks.nvim'),
  gh('echasnovski/mini.move'),
})

require("nvim-surround").setup({})

require("flash").setup({
  modes = {
    char = {
      keys = { "f", "F", "t", "T", ";", [","] = "<C-;>" },
      char_actions = function(motion)
        return {
          [";"] = "next",
          [","] = "prev",
          [motion:lower()] = "next",
          [motion:upper()] = "prev",
        }
      end,
    },
  },
})

vim.keymap.set({ "n", "x", "o" }, "r", function() require("flash").jump() end, { desc = "Flash Jump" })
vim.keymap.set({ "n", "x", "o" }, "R", function() require("flash").treesitter_search() end, { desc = "Flash Treesitter Search" })
vim.keymap.set({ "n", "x", "o" }, "<C-r>", function() require("flash").treesitter() end, { desc = "Flash Treesitter" })

if vim.fn.has("nvim-0.10.0") == 1 then
  require("ts-comments").setup({})
end

require("nvim-autopairs").setup()

require("mini.move").setup({
  mappings = {
    -- Visual mode: move selection
    left       = "<M-h>",
    right      = "<M-l>",
    down       = "<M-j>",
    up         = "<M-k>",
    -- Normal mode: move current line
    line_left  = "<M-h>",
    line_right = "<M-l>",
    line_down  = "<M-j>",
    line_up    = "<M-k>",
  },
})

require("marks").setup({
  default_mappings = true,
  signs = true,
  mappings = {
    set_next = "m,",
    toggle = "m;",
    next = "m]",
    prev = "m[",
    preview = "m:",
    delete_buf = "dm-",
  },
})
