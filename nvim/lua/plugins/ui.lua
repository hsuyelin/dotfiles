local gh = function(r) return 'https://github.com/' .. r end

vim.pack.add({
  gh('akinsho/bufferline.nvim'),
  gh('rcarriga/nvim-notify'),
  gh('folke/noice.nvim'),
})

---@type bufferline.Config
require("bufferline").setup({
  options = {
    always_show_bufferline = false,
    close_command = function(buf)
      utils.bufdelete.delete(buf)
    end,
    diagnostics = "nvim_lsp",
    offsets = {},
    indicator = {
      style = "underline",
    },
  },
})

local notify = require("notify")
local suppressed_notify_patterns = {
  "%[nvim%-treesitter%] warning: skipping unsupported language",
  "^No information available$",
  "^No signature help available$",
  "^No code actions available$",
  "method textDocument/.+ is not supported by any of the servers registered for the current buffer",
}

-- nvim-notify: keep popups reserved for actionable warnings/errors only.
---@diagnostic disable-next-line: missing-fields
notify.setup({
  top_down = false,
  max_width = 60,
  timeout = 1500,
  level = vim.log.levels.INFO,
  render = "minimal",
  stages = "static",
  background_colour = "#000000",
})
local ok, telescope = pcall(require, "telescope")
if ok then
  pcall(telescope.load_extension, "notify")
end

local noice_routes = {
  {
    filter = { event = "msg_show", kind = "search_count" },
    opts = { skip = true },
  },
  {
    filter = {
      event = "msg_show",
      any = {
        { find = "%d+ lines? written" },
        { find = "%d+ fewer lines?" },
        { find = "%d+ more lines?" },
        { find = "Already at newest change" },
        { find = "Already at oldest change" },
      },
    },
    opts = { skip = true },
  },
}

for _, pattern in ipairs(suppressed_notify_patterns) do
  table.insert(noice_routes, 1, {
    filter = { event = "notify", find = pattern },
    opts = { skip = true },
  })
end

vim.schedule(function()
  require("noice").setup({
    notify = { enabled = true, view = "notify" },
    messages = {
      enabled = true,
      view = "mini",
      view_warn = "mini",
      view_error = "notify",
    },
    lsp = {
      hover = { enabled = true, silent = true },
      progress = { enabled = false },
      message = { enabled = true },
      signature = {
        enabled = true,
        auto_open = {
          enabled = false,
        },
      },
      override = {
        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
        ["vim.lsp.util.stylize_markdown"] = true,
      },
    },
    presets = {
      long_message_to_split = true,
      lsp_doc_border = false,
    },
    routes = noice_routes,
  })
end)
