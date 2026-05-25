-- NOTE: peek.nvim requires a one-time build after install:
--   cd ~/.local/share/nvim/site/pack/core/opt/peek.nvim && deno task --quiet build:fast
local gh = function(r) return 'https://github.com/' .. r end

vim.pack.add({
    gh('OXY2DEV/markview.nvim'),
    gh('toppair/peek.nvim'),
})

require("markview").setup({
    preview = {
        -- Render in normal / operator-pending; reveal raw in insert
        modes = { "n", "no" },
        hybrid_modes = { "n" },
        linewise_hybrid_mode = true,
        callbacks = {
            on_enable = function(_, win)
                vim.wo[win].conceallevel = 2
                vim.wo[win].concealcursor = "c"
            end,
            on_disable = function(_, win)
                vim.wo[win].conceallevel = 0
            end,
        },
    },
})

-- peek.nvim: load only when editing markdown
vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    once = true,
    callback = function()
        require("peek").setup({
            auto_load    = true,
            close_on_bdelete = true,
            syntax       = true,
            theme        = "light",
            update_on_change = true,
            app          = "browser",
        })
        vim.api.nvim_buf_create_user_command(0, "PeekOpen",  require("peek").open,  {})
        vim.api.nvim_buf_create_user_command(0, "PeekClose", require("peek").close, {})
    end,
})

require("which-key").add({
    mode   = { "n" },
    silent = true,
    noremap = true,
    { "<leader>m",  group = "Markdown" },
    { "<leader>mt", "<cmd>Markview toggle<cr>",       desc = "切换渲染 (Toggle Render)" },
    { "<leader>mh", "<cmd>Markview hybridToggle<cr>", desc = "切换混合模式 (Hybrid Mode)" },
    { "<leader>ms", "<cmd>Markview splitToggle<cr>",  desc = "分屏预览 (Split Preview)" },
    { "<leader>mp", function() require("peek").open()  end, desc = "浏览器预览 (Browser Preview)" },
    { "<leader>mc", function() require("peek").close() end, desc = "关闭预览 (Close Preview)" },
})
