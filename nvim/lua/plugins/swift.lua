local gh = function(r) return 'https://github.com/' .. r end

vim.pack.add({
  gh('folke/snacks.nvim'),
  gh('wojciech-kulik/xcodebuild.nvim'),
})

require("snacks").setup({
  image = { enabled = true },
})

require("xcodebuild").setup({
  console_logs = {
    enabled = false,
    format_line = function(line) return line end,
    filter_line = function(_) return true end,
  },
})
