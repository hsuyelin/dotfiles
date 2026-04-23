local gh = function(r) return 'https://github.com/' .. r end

vim.pack.add({
  gh('ray-x/guihua.lua'),
  gh('ray-x/go.nvim'),
})

-- Load only when editing Go files
vim.api.nvim_create_autocmd("FileType", {
  pattern = "go",
  once = true,
  callback = function()
    require("go").setup()
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = "*.go",
      callback = function()
        pcall(require("go.format").goimport)
      end,
    })
  end,
})
