-- blink.cmp: pre-built Rust binaries are fetched automatically via version tag.
-- Falls back to Lua implementation if Rust binary is unavailable.
local gh = function(r) return 'https://github.com/' .. r end

vim.pack.add({
  { src = gh('saghen/blink.cmp'), version = vim.version.range('>=1.0 <2.0') },
})

require("blink.cmp").setup({
  keymap = { preset = "super-tab" },

  appearance = {
    nerd_font_variant = "mono",
  },

  completion = {
    documentation = { auto_show = true, auto_show_delay_ms = 0 },
    menu = {
      auto_show = true,
      auto_show_delay_ms = 0,
      draw = {
        columns = {
          { "kind_icon" },
          { "label", "label_description", gap = 1 },
          { "source_name" },
        },
      },
    },
  },

  sources = {
    default = { "lsp", "path", "snippets", "buffer" },
  },

  fuzzy = { implementation = "prefer_rust_with_warning" },

  cmdline = {
    enabled = true,
    keymap = {
      ["<C-k>"] = { "accept" },
      ["<TAB>"] = { "accept", "fallback" },
      ["<CR>"] = { "accept_and_enter", "fallback" },
    },
    sources = { "buffer", "cmdline" },
    completion = {
      menu = { auto_show = true },
      list = {
        selection = { preselect = true, auto_insert = true },
      },
      ghost_text = { enabled = true },
    },
  },

  term = {
    enabled = false,
    keymap = { preset = "inherit" },
    sources = {},
  },
})
