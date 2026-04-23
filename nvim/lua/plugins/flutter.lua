local gh = function(r) return 'https://github.com/' .. r end

vim.pack.add({
  gh('akinsho/flutter-tools.nvim'),
})

-- Load only when editing Dart files
vim.api.nvim_create_autocmd("FileType", {
  pattern = "dart",
  once = true,
  callback = function()
    local dap_avail = pcall(require, "dap")

    require("flutter-tools").setup({
      debugger = {
        enabled = true,
        run_via_dap = dap_avail,
        register_configurations = function(_)
          require("dap").configurations.dart = {
            {
              type = "dart",
              request = "launch",
              name = "Launch Flutter Program",
              program = "./lib/main.dart",
              cwd = "${workspaceFolder}",
            },
          }
        end,
      },
      decorations = {
        statusline = {
          app_version = false,
          device = true,
        },
      },
      widget_guides = { enabled = true },
      dev_log = { enabled = false },
      lsp = {
        color = {
          enabled = true,
          background = true,
          background_color = nil,
          virtual_text = false,
        },
      },
    })

    local ok, telescope = pcall(require, "telescope")
    if ok then telescope.load_extension("flutter") end
  end,
})
