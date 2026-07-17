local gh = function(r)
    return "https://github.com/" .. r
end

vim.pack.add({
    gh("kylechui/nvim-surround"),
    gh("folke/flash.nvim"),
    gh("folke/ts-comments.nvim"),
    gh("windwp/nvim-autopairs"),
    gh("chentoast/marks.nvim"),
    gh("echasnovski/mini.move"),
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

vim.keymap.set({ "n", "x", "o" }, "r", function()
    require("flash").jump()
end, { desc = "Flash Jump" })
vim.keymap.set({ "n", "x", "o" }, "R", function()
    require("flash").treesitter_search()
end, { desc = "Flash Treesitter Search" })
vim.keymap.set({ "n", "x", "o" }, "<C-r>", function()
    require("flash").treesitter()
end, { desc = "Flash Treesitter" })

if vim.fn.has("nvim-0.10.0") == 1 then
    require("ts-comments").setup({})
end

require("nvim-autopairs").setup()

local mini_move = require("mini.move")

mini_move.setup({
    mappings = {
        -- Visual mode: move selection
        left = "<M-h>",
        right = "<M-l>",
        down = "<M-j>",
        up = "<M-k>",
        -- Normal mode: move current line
        line_left = "<M-h>",
        line_right = "<M-l>",
        line_down = "<M-j>",
        line_up = "<M-k>",
    },
})

local function move_line(direction)
    return function()
        mini_move.move_line(direction)
    end
end

local function move_selection(direction)
    return function()
        mini_move.move_selection(direction)
    end
end

vim.keymap.set("n", "<S-Up>", move_line("up"), { desc = "Move line up" })
vim.keymap.set("n", "<S-Down>", move_line("down"), { desc = "Move line down" })
vim.keymap.set("x", "<S-Up>", move_selection("up"), { desc = "Move selection up" })
vim.keymap.set("x", "<S-Down>", move_selection("down"), { desc = "Move selection down" })

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
