local gh = function(r) return 'https://github.com/' .. r end

vim.pack.add({
    gh('epwalsh/obsidian.nvim'),
})

require("obsidian").setup({
    workspaces = {
        { name = "personal", path = "~/notes" },
    },

    daily_notes = {
        folder = "daily",
        date_format = "%Y-%m-%d",
        template = "daily.md",
    },

    templates = {
        folder = "templates",
    },

    -- Human-readable filenames instead of timestamp IDs
    note_id_func = function(title)
        if title ~= nil then
            return title:gsub(" ", "-"):gsub("[^A-Za-z0-9%-\u{4e00}-\u{9fff}]", ""):lower()
        end
        return tostring(os.time())
    end,

    -- New notes go to inbox/ by default
    notes_subdir = "inbox",

    picker = {
        name = "telescope",
    },

    -- Disable nvim-cmp integration (we use blink.cmp)
    completion = {
        nvim_cmp = false,
        min_chars = 2,
    },

    -- markview already handles markdown rendering
    ui = { enable = false },
})

require("which-key").add({
    mode   = { "n" },
    silent = true,
    noremap = true,
    { "<leader>n",  group = "笔记 (Notes)" },
    { "<leader>nn", "<cmd>ObsidianNew<cr>",          desc = "新建笔记 (New Note)" },
    { "<leader>no", "<cmd>ObsidianQuickSwitch<cr>",  desc = "打开笔记 (Quick Switch)" },
    { "<leader>ns", "<cmd>ObsidianSearch<cr>",       desc = "搜索笔记 (Search)" },
    { "<leader>nd", "<cmd>ObsidianToday<cr>",        desc = "今日笔记 (Today)" },
    { "<leader>ny", "<cmd>ObsidianYesterday<cr>",    desc = "昨日笔记 (Yesterday)" },
    { "<leader>nt", "<cmd>ObsidianTemplate<cr>",     desc = "插入模板 (Template)" },
    { "<leader>nb", "<cmd>ObsidianBacklinks<cr>",    desc = "反向链接 (Backlinks)" },
    { "<leader>nT", "<cmd>ObsidianTags<cr>",         desc = "标签列表 (Tags)" },
})
