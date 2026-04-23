local gh = function(r) return 'https://github.com/' .. r end

vim.pack.add({
  gh('sphamba/smear-cursor.nvim'),
})

require("smear_cursor").setup({
  smear_between_buffers = true,
  smear_between_neighbor_lines = true,
  scroll_buffer_space = true,
  legacy_computing_symbols_support = true,
  smear_insert_mode = true,
  cursor_color = "#d3cdc3",
  stiffness = 0.8,
  trailing_stiffness = 0.6,
  stiffness_insert_mode = 0.7,
  trailing_stiffness_insert_mode = 0.7,
  damping = 0.95,
  damping_insert_mode = 0.95,
  distance_stop_animating = 0.5,
})
