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
        ["c"] = function(state)
          local node = state.tree:get_node()
          if node.type ~= "directory" then return end
          local path = node:get_id()
          require("neo-tree.sources.filesystem.commands").set_root(state)
          vim.cmd("cd " .. vim.fn.fnameescape(path))
          vim.notify("cwd → " .. path, vim.log.levels.INFO)
        end,
        ["H"] = "navigate_up",
        ["l"] = "open",
        ["h"] = "close_node",
        ["<space>"] = "toggle_node",
        ["."] = "toggle_hidden",
      },
    },
    -- Decouple tree root from cwd: follow_current_file can freely move the
    -- tree view without reverting the cwd set by the custom "c" mapping above.
    bind_to_cwd = false,
    use_libuv_file_watcher = true,
    follow_current_file = {
      enabled = true,
      leave_dirs_open = true,
    },
  },
})

-- Auto-open neo-tree on startup; reveal current file if one was provided.
-- defer_fn(50) outlasts the VimEnter event loop tick so neo-tree's :Neotree
-- command is guaranteed to be registered before we call it.
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    vim.defer_fn(function()
      if vim.o.diff then return end
      local buf = vim.api.nvim_get_current_buf()
      if vim.api.nvim_get_option_value("buftype", { buf = buf }) ~= "" then return end
      if vim.fn.argc() > 0 then
        vim.cmd("Neotree show reveal_force_cwd")
      else
        vim.cmd("Neotree show")
      end
    end, 50)
  end,
})
