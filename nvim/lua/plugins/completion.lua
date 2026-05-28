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
      ["<TAB>"]   = { "select_next", "fallback" },
      ["<S-TAB>"] = { "select_prev", "fallback" },
      ["<CR>"]    = { "accept_and_enter", "fallback" },
      ["<Up>"]    = { "select_prev", "fallback" },
      ["<Down>"]  = { "select_next", "fallback" },
    },
    sources = { "buffer", "cmdline" },
    completion = {
      menu = { auto_show = true },
      list = {
        -- preselect = false: nothing is auto-highlighted, so <CR> always
        -- runs the literal input unless the user explicitly navigates to
        -- a suggestion with <Up>/<Down> first.
        selection = { preselect = false, auto_insert = false },
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
