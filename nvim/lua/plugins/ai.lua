local gh = function(r) return 'https://github.com/' .. r end

vim.pack.add({
  gh('monkoose/neocodeium'),
  gh('folke/sidekick.nvim'),
  gh('404pilo/aicommits.nvim'),
})

-- neocodeium: defer to after startup
vim.schedule(function()
  local neocodeium = require("neocodeium")
  neocodeium.setup({
    enabled = true,
    silent = true,
    filetypes = {
      help = false,
      gitrebase = false,
      ["."] = false,
      ["cpp"] = false,
    },
  })
  vim.keymap.set("i", "<Tab>", function()
    if neocodeium.visible() then
      neocodeium.accept()
    else
      return "<Tab>"
    end
  end, { expr = true, silent = true })
end)

require("sidekick").setup({
  cli = {
    mux = {
      backend = "zellij",
      enabled = false,
    },
  },
})

vim.keymap.set({ "i" }, "<tab>", function()
  if not require("sidekick").nes_jump_or_apply() then
    return "<Tab>"
  end
end, { expr = true, desc = "Goto/Apply Next Edit Suggestion" })
vim.keymap.set({ "n", "x", "i", "t" }, "<c-.>", function()
  require("sidekick.cli").focus()
end, { desc = "Sidekick Switch Focus" })
vim.keymap.set({ "n", "v" }, "<leader>aa", function()
  require("sidekick.cli").toggle({ focus = true })
end, { desc = "Sidekick Toggle CLI" })
vim.keymap.set({ "n", "v" }, "<leader>ac", function()
  require("sidekick.cli").toggle({ name = "claude", focus = true })
end, { desc = "Sidekick Claude Toggle" })
vim.keymap.set({ "n", "v" }, "<leader>ag", function()
  require("sidekick.cli").toggle({ name = "codex", focus = true })
end, { desc = "Sidekick Grok Toggle" })
vim.keymap.set({ "n", "v" }, "<leader>ap", function()
  require("sidekick.cli").select_prompt()
end, { desc = "Sidekick Ask Prompt" })

require("aicommits").setup()
