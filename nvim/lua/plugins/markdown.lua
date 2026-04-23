-- NOTE: peek.nvim requires a one-time build after install:
--   cd ~/.local/share/nvim/site/pack/core/opt/peek.nvim && deno task --quiet build:fast
local gh = function(r) return 'https://github.com/' .. r end

vim.pack.add({
  gh('MeanderingProgrammer/render-markdown.nvim'),
  gh('toppair/peek.nvim'),
})

require("render-markdown").setup({})

-- peek.nvim: load only when editing markdown
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  once = true,
  callback = function()
    require("peek").setup({
      auto_load = true,
      close_on_bdelete = true,
      syntax = true,
      theme = "light",
      update_on_change = true,
      app = "browser",
    })
    vim.api.nvim_buf_create_user_command(0, "PeekOpen", require("peek").open, {})
    vim.api.nvim_buf_create_user_command(0, "PeekClose", require("peek").close, {})
  end,
})

vim.keymap.set("n", "<leader>mp", function() require("peek").open() end, { desc = "Markdown Preview Open" })
vim.keymap.set("n", "<leader>mc", function() require("peek").close() end, { desc = "Markdown Preview Close" })
