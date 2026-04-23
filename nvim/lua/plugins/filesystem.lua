local gh = function(r) return 'https://github.com/' .. r end

vim.pack.add({
  gh('ahmedkhalf/project.nvim'),
})

require("project_nvim").setup({
  manual_mode = true,
  patterns = {
    ".git",
    ".project",
    "pubspec.yaml",
  },
  scope_chdir = "global",
})

require("telescope").load_extension("projects")
