local gh = function(r) return 'https://github.com/' .. r end

vim.pack.add({
  { src = gh('nvim-neo-tree/neo-tree.nvim'), version = vim.version.range('>=3.0 <4.0') },
})

vim.cmd([[ let g:neo_tree_remove_legacy_commands = 1 ]])

require("neo-tree").setup({
  enable_git_status = true,
  popup_border_style = "rounded",
  close_if_last_window = true,

  window = {
    width = 45,
    mappings = {
      ["<tab>"] = "open",
      ["O"] = "expand_all_nodes",
      ["C"] = "close_all_subnodes",
    },
  },
  filesystem = {
    filtered_items = {
      hide_by_pattern = {
        "*.g.dart",
        "*.freezed.dart",
        "__pycache__",
      },
      always_show = {
        ".gitignore",
        ".nvim.lua",
      },
    },
    window = {
      mappings = {
        ["f"] = "fuzzy_finder",
        ["/"] = "fuzzy_finder",
        ["Y"] = "copy_to_clipboard",
        ["P"] = "paste_from_clipboard",
        ["M"] = "move",
        ["D"] = "delete",
        ["A"] = "add",
        ["Ctrl+A"] = "add_directory",
        ["R"] = "rename",
        ["c"] = "set_root",
        ["H"] = "navigate_up",
        ["l"] = "open",
        ["h"] = "close_node",
        ["<space>"] = "toggle_node",
        ["."] = "toggle_hidden",
      },
    },
    bind_to_cwd = true,
    use_libuv_file_watcher = true,
    follow_current_file = {
      enabled = true,
      leave_dirs_open = true,
    },
  },
})
