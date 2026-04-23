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

-- nvim-notify: defer so it doesn't block startup
vim.schedule(function()
  ---@diagnostic disable-next-line: missing-fields
  require("notify").setup({
    top_down = false,
    max_width = 80,
    background_colour = "#000000",
  })
  vim.notify = require("notify")
  local ok, telescope = pcall(require, "telescope")
  if ok then telescope.load_extension("notify") end
end)

-- noice: defer (depends on notify being set up)
vim.schedule(function()
  require("noice").setup({
    lsp = {
      signature = { enabled = false },
    },
  })
end)
