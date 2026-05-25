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
    width = 30,
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

-- Auto-open neo-tree only when nvim is started without a file argument, or
-- when the argument is a directory. Opening a single file leaves the tree
-- closed so the editor area isn't wasted on a narrow view.
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    vim.defer_fn(function()
      if vim.o.diff then return end
      local buf = vim.api.nvim_get_current_buf()
      if vim.api.nvim_get_option_value("buftype", { buf = buf }) ~= "" then return end

      if vim.fn.argc() == 0 then
        vim.cmd("Neotree show")
      elseif vim.fn.argc() == 1 then
        local arg  = vim.fn.argv(0)
        local stat = vim.uv.fs_stat(arg)
        if stat and stat.type == "directory" then
          vim.cmd("Neotree show dir=" .. vim.fn.fnameescape(arg))
        end
      end
    end, 50)
  end,
})
