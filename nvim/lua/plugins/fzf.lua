local gh = function(r) return 'https://github.com/' .. r end

vim.pack.add({
  gh('ibhagwan/fzf-lua'),
})

local ok, fzf = pcall(require, "fzf-lua")
if ok then
  fzf.setup({
    files = {
      cmd = "rg --files --hidden --follow --color never -g '!.git' -g '!**/.git/*'",
    },
    grep = {
      rg_opts = "--column --line-number --no-heading --color=always --smart-case --hidden -g '!.git' -g '!**/.git/*'",
    },
  })
end
