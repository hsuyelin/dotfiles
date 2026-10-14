vim.pack.add({ "https://github.com/folke/snacks.nvim" })

require("snacks").setup({
  image = {
    enabled = true,
    formats = { "png", "jpg", "jpeg", "gif", "bmp", "webp", "tif", "tiff", "svg", "heic", "avif" },
    doc = { enabled = false }, -- markview/peek already handle Markdown previews.
  },
})
