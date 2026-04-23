local gh = function(r) return 'https://github.com/' .. r end

vim.pack.add({
  gh('ibhagwan/fzf-lua'),
})

require("fzf-lua").setup({})
