local gh = function(r) return 'https://github.com/' .. r end

vim.pack.add({
  { src = gh('nvim-neo-tree/neo-tree.nvim'), version = vim.version.range('>=3.0 <4.0') },
})

vim.cmd([[ let g:neo_tree_remove_legacy_commands = 1 ]])

-- Open filepath in the first normal editor window; create a vsplit if none
-- exists. Afterwards, reveal the file in the tree without stealing focus.
local function open_in_editor(filepath)
    local target_win = nil
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_config(win).relative == "" then
            local buf = vim.api.nvim_win_get_buf(win)
            if vim.bo[buf].filetype ~= "neo-tree" then
                target_win = win
                break
            end
        end
    end
    if target_win then
        vim.api.nvim_set_current_win(target_win)
    else
        vim.cmd("vsplit")
    end
    vim.cmd("edit " .. vim.fn.fnameescape(filepath))
    vim.schedule(function()
        require("neo-tree.command").execute({
            source = "filesystem",
            action = "show",
            reveal_file = filepath,
        })
    end)
end

-- fzf-lua action: resolve the selected entry to an absolute path and open it.
local function fzf_open(selected, opts)
    if not selected or #selected == 0 then return end
    local entry = require("fzf-lua.path").entry_to_file(selected[1], opts)
    open_in_editor(entry.path)
end

-- Fuzzy-find all files under the neo-tree root using fzf-lua + ripgrep.
-- Supports case-insensitive filename fuzzy match and directory name match.
local function fuzzy_find(state)
    local ok, fzf = pcall(require, "fzf-lua")
    if not ok then return end
    fzf.files({
        cwd = state.path,
        prompt = "  ",
        actions = { ["default"] = fzf_open },
    })
end

-- Glob-filter files under the neo-tree root (e.g. *.swift, *.m, *.swift *.h).
-- Accepts multiple space-separated glob patterns passed to ripgrep -g flags.
local function glob_find(state)
    local ok, fzf = pcall(require, "fzf-lua")
    if not ok then return end
    vim.ui.input({ prompt = "Glob (e.g. *.swift *.m): " }, function(input)
        if not input or input == "" then return end
        local root = state.path
        local parts = {
            "rg --files --hidden --follow --color never",
            "-g '!.git' -g '!**/.git/*'",
        }
        for glob in input:gmatch("%S+") do
            parts[#parts + 1] = "-g " .. vim.fn.shellescape(glob)
        end
        fzf.files({
            cwd = root,
            cmd = table.concat(parts, " "),
            prompt = input .. " ❯ ",
            actions = { ["default"] = fzf_open },
        })
    end)
end

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
      ["<C-f>"] = function() vim.cmd("Telescope find_files") end,
      [">"] = function()
        vim.api.nvim_win_set_width(0, vim.api.nvim_win_get_width(0) + 5)
      end,
      ["<"] = function()
        vim.api.nvim_win_set_width(0, math.max(15, vim.api.nvim_win_get_width(0) - 5))
      end,
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
        ["f"] = fuzzy_find,
        ["/"] = fuzzy_find,
        ["F"] = glob_find,
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
--
-- buftype check is intentionally absent for argc==0: the dashboard sets
-- buftype="nofile", which would otherwise block neo-tree from opening.
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    vim.defer_fn(function()
      if vim.o.diff then return end

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
