local gh = function(r) return 'https://github.com/' .. r end

vim.pack.add({
  gh('cachebag/nvim-tcss'),
})

require("tcss").setup()
