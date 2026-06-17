-- NOTE: After first install, run :TSUpdate to download language parsers.
local gh = function(r) return 'https://github.com/' .. r end

vim.pack.add({
  { src = gh('nvim-treesitter/nvim-treesitter'), version = 'master' },
  { src = gh('nvim-treesitter/nvim-treesitter-textobjects'), version = 'master' },
})

local is_mac = (vim.uv or vim.loop).os_uname().sysname == "Darwin"

local ENSURE_INSTALLED = {
  "bash", "c", "cpp", "diff", "go", "gomod", "gosum", "gowork",
  "html", "ini", "javascript", "json", "lua", "markdown", "markdown_inline",
  "python", "query", "regex", "vim", "vimdoc", "yaml",
}
if is_mac then
  table.insert(ENSURE_INSTALLED, "swift")
end

-- There is no dedicated tree-sitter "conf" parser. The vast majority of *.conf
-- files use the standard `key = value` / `[section]` / `# comment` syntax, which
-- the `ini` parser handles well. Map conf -> ini so the FileType autocmd in
-- core/options.lua attaches the ini parser and gives rich highlighting (the
-- weak built-in conf.vim syntax only colors comments).
vim.treesitter.language.register("ini", { "conf" })

local legacy_ok, legacy_configs = pcall(require, "nvim-treesitter.configs")
if legacy_ok then
  legacy_configs.setup({
    ensure_installed = ENSURE_INSTALLED,
    auto_install = false,
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false,
    },
    indent = {
      enable = true,
      disable = { "swift" },
    },
  })
else
  local modern_ok, modern_treesitter = pcall(require, "nvim-treesitter")
  if modern_ok and type(modern_treesitter.setup) == "function" then
    modern_treesitter.setup()
  end
end

-- Treesitter textobjects: select
vim.keymap.set({ "x", "o" }, "af", function()
  require("nvim-treesitter-textobjects.select").select_textobject("@function.outer", "textobjects")
end)
vim.keymap.set({ "x", "o" }, "if", function()
  require("nvim-treesitter-textobjects.select").select_textobject("@function.inner", "textobjects")
end)
vim.keymap.set({ "x", "o" }, "ac", function()
  require("nvim-treesitter-textobjects.select").select_textobject("@class.outer", "textobjects")
end)
vim.keymap.set({ "x", "o" }, "ic", function()
  require("nvim-treesitter-textobjects.select").select_textobject("@class.inner", "textobjects")
end)

-- Treesitter textobjects: swap
vim.keymap.set("n", "<leader>cp", function()
  require("nvim-treesitter-textobjects.swap").swap_next("@parameter.outer")
end, { desc = "Swap next parameter" })
vim.keymap.set("n", "<leader>cP", function()
  require("nvim-treesitter-textobjects.swap").swap_previous("@parameter.outer")
end, { desc = "Swap prev parameter" })
vim.keymap.set("n", "<leader>cf", function()
  require("nvim-treesitter-textobjects.swap").swap_next("@function.outer")
end)
vim.keymap.set("n", "<leader>cF", function()
  require("nvim-treesitter-textobjects.swap").swap_previous("@function.outer")
end)
vim.keymap.set("n", "<leader>cc", function()
  require("nvim-treesitter-textobjects.swap").swap_next("@class.outer")
end)
vim.keymap.set("n", "<leader>cC", function()
  require("nvim-treesitter-textobjects.swap").swap_previous("@class.outer")
end)

-- Treesitter textobjects: move
local move = require("nvim-treesitter-textobjects.move")
local motions = {
  { "]p", "[p", "]P", "[P", "@parameter.outer" },
  { "]f", "[f", "]F", "[F", "@function.outer" },
  { "]c", "[c", "]C", "[C", "@class.outer" },
  { "]o", "[o", "]O", "[O", "@loop.outer" },
}
for _, m in ipairs(motions) do
  vim.keymap.set({ "n", "x", "o" }, m[1], function() move.goto_next_start(m[5], "textobjects") end)
  vim.keymap.set({ "n", "x", "o" }, m[2], function() move.goto_previous_start(m[5], "textobjects") end)
  vim.keymap.set({ "n", "x", "o" }, m[3], function() move.goto_next_end(m[5], "textobjects") end)
  vim.keymap.set({ "n", "x", "o" }, m[4], function() move.goto_previous_end(m[5], "textobjects") end)
end
vim.keymap.set({ "n", "x", "o" }, "]z", function() move.goto_next_start("@fold", "folds") end)
vim.keymap.set({ "n", "x", "o" }, "[z", function() move.goto_previous_start("@fold", "folds") end)
vim.keymap.set({ "n", "x", "o" }, "]m", function() move.goto_next_start("@function.outer", "textobjects") end)
vim.keymap.set({ "n", "x", "o" }, "]]", function() move.goto_next_start("@class.outer", "textobjects") end)

-- Repeat movement with ; and ,
local ts_repeat = require("nvim-treesitter-textobjects.repeatable_move")
vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat.repeat_last_move_next)
vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat.repeat_last_move_previous)

-- Ensure tree-sitter-cli is available (required to compile parsers from source).
--   macOS : brew install tree-sitter-cli
--   Linux : npm install -g tree-sitter-cli  (only when npm is present)
local function ensure_tree_sitter_cli()
  if vim.fn.exepath("tree-sitter") ~= "" then return end

  if is_mac then
    local brew = vim.fn.exepath("brew")
    if brew == "" then
      vim.notify("[treesitter] tree-sitter-cli not found. Install: brew install tree-sitter-cli", vim.log.levels.WARN)
      return
    end
    vim.notify("[treesitter] installing tree-sitter-cli via brew...", vim.log.levels.INFO)
    vim.fn.jobstart({ brew, "install", "tree-sitter-cli" }, {
      on_exit = function(_, code)
        vim.schedule(function()
          if code == 0 then
            vim.notify("[treesitter] tree-sitter-cli installed", vim.log.levels.INFO)
          else
            vim.notify("[treesitter] tree-sitter-cli install failed (exit " .. code .. ")", vim.log.levels.WARN)
          end
        end)
      end,
    })
  else
    -- npm's tree-sitter-cli only ships x86_64 prebuilds; on ARM it leaves no
    -- executable behind.  Prefer cargo (compiles from source, any arch).
    local cargo = vim.fn.exepath("cargo")
    if cargo ~= "" then
      vim.notify("[treesitter] installing tree-sitter-cli via cargo...", vim.log.levels.INFO)
      vim.fn.jobstart({ cargo, "install", "tree-sitter-cli" }, {
        on_exit = function(_, code)
          vim.schedule(function()
            if code == 0 then
              vim.notify("[treesitter] tree-sitter-cli installed", vim.log.levels.INFO)
            else
              vim.notify("[treesitter] tree-sitter-cli install failed (exit " .. code .. ")", vim.log.levels.WARN)
            end
          end)
        end,
      })
      return
    end

    local npm = vim.fn.exepath("npm")
    if npm == "" then
      vim.notify(
        "[treesitter] tree-sitter-cli not found. On ARM: cargo install tree-sitter-cli",
        vim.log.levels.WARN
      )
      return
    end
    local arch = (vim.uv or vim.loop).os_uname().machine
    if arch:find("arm") or arch:find("aarch") then
      vim.notify(
        "[treesitter] ARM detected: npm tree-sitter-cli has no prebuilt binary. Run: cargo install tree-sitter-cli",
        vim.log.levels.WARN
      )
      return
    end
    vim.notify("[treesitter] installing tree-sitter-cli via npm...", vim.log.levels.INFO)
    vim.fn.jobstart({ npm, "install", "-g", "tree-sitter-cli" }, {
      on_exit = function(_, code)
        vim.schedule(function()
          if code == 0 then
            vim.notify("[treesitter] tree-sitter-cli installed", vim.log.levels.INFO)
          else
            vim.notify("[treesitter] tree-sitter-cli install failed (exit " .. code .. ")", vim.log.levels.WARN)
          end
        end)
      end,
    })
  end
end

-- Auto-install any missing parsers from ENSURE_INSTALLED on first launch.
-- vim.pack.add() has no build hook, so ensure_installed alone is not reliable.
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    ensure_tree_sitter_cli()

    local install_ok, install = pcall(require, "nvim-treesitter.install")
    if not install_ok then return end
    local parsers_ok, parsers = pcall(require, "nvim-treesitter.parsers")
    if not parsers_ok then return end
    local missing = {}
    for _, lang in ipairs(ENSURE_INSTALLED) do
      local parser_path = vim.fn.stdpath("data") .. "/site/parser/" .. lang .. ".so"
      if vim.fn.filereadable(parser_path) == 0 then
        table.insert(missing, lang)
      end
    end
    if #missing > 0 then
      vim.notify(
        "[treesitter] Installing missing parsers: " .. table.concat(missing, ", "),
        vim.log.levels.INFO
      )
      install.install(missing)
    end
  end,
})
