local gh = function(r) return 'https://github.com/' .. r end

vim.pack.add({
  gh('nvim-telescope/telescope.nvim'),
  gh('nvim-telescope/telescope-ui-select.nvim'),
  gh('LukasPietzschmann/telescope-tabs'),
  gh('jvgrootveld/telescope-zoxide'),
})

local telescope = require("telescope")

telescope.setup({
  defaults = {
    layout_strategy = "flex",
    sorting_strategy = "ascending",
    layout_config = {
      vertical = { width = 0.88 },
      horizontal = {
        prompt_position = "top",
        preview_width = 0.54,
        width = 0.88,
        height = 0.88,
      },
    },
    mappings = {
      i = {
        ["<C-u>"] = false,
        ["<C-q>"] = function(...)
          require("trouble.sources.telescope").open(...)
        end,
      },
    },
  },
  extensions = {
    ["ui-select"] = {
      require("telescope.themes").get_dropdown({}),
    },
    zoxide = {
      prompt_title = "[ Zoxide ]",
      mappings = { default = {} },
    },
    emoji = {
      action = function(emoji)
        vim.api.nvim_put({ emoji.value }, "c", false, true)
      end,
    },
  },
  pickers = {
    colorscheme = { enable_preview = true },
  },
})

telescope.load_extension("ui-select")
telescope.load_extension("zoxide")

require("telescope-tabs").setup({})
