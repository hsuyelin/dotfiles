local gh = function(r) return 'https://github.com/' .. r end

vim.pack.add({
  gh('rebelot/heirline.nvim'),
})

-- Defer to UiEnter so all highlight groups are ready
vim.api.nvim_create_autocmd("UiEnter", {
  once = true,
  callback = function()
    require("plugins.heirline")
  end,
})
