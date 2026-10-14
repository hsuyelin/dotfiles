local M = {}

local images = { png = true, jpg = true, jpeg = true, gif = true, webp = true, bmp = true, tif = true, tiff = true, svg = true, heic = true, avif = true }
local videos = { mp4 = true, mov = true, mkv = true, webm = true, avi = true, m4v = true }
local documents = { docx = true, odt = true, rtf = true, epub = true }

local function run(command, callback)
  if vim.fn.executable(command[1]) == 0 then
    vim.notify(command[1] .. " is required for media preview", vim.log.levels.ERROR)
    return
  end
  vim.system(command, { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        vim.notify((result.stderr or "preview failed"):gsub("%s+$", ""), vim.log.levels.ERROR)
      end
      callback(result.code == 0 and result.stdout or nil)
    end)
  end)
end

local function open_window(path)
  local width = math.max(20, math.floor(vim.o.columns * 0.8))
  local height = math.max(8, math.floor(vim.o.lines * 0.8))
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor", style = "minimal", border = "rounded",
    width = width, height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    title = " " .. vim.fn.fnamemodify(path, ":t") .. " ",
    title_pos = "center",
  })
  vim.bo[buf].bufhidden = "wipe"
  vim.keymap.set("n", "q", function()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end, { buffer = buf, silent = true })
  return buf, win, width - 2, height - 2
end

local function show_text(buf, content)
  if not vim.api.nvim_buf_is_valid(buf) then return end
  local lines = vim.split(content:gsub("\r\n", "\n"), "\n", { plain = true })
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
end
local function show_image(buf, path, generated)
  local image = require("snacks").image
  if not image.supports_terminal() then
    if generated then vim.fn.delete(path) end
    show_text(buf, "Image preview requires Kitty graphics support in this terminal.")
    return
  end
  -- Text in the buffer makes Snacks treat the image as an inline anchor,
  -- leaving the loading message visible and pushing the image below it.
  show_text(buf, "")
  image.buf.attach(buf, { src = path })
  if generated then
    vim.api.nvim_create_autocmd("BufWipeout", {
      buffer = buf, once = true,
      callback = function() vim.fn.delete(path) end,
    })
  end
end

function M.open(path)
  path = vim.fn.fnamemodify(path or vim.api.nvim_buf_get_name(0), ":p")
  if vim.fn.filereadable(path) ~= 1 then
    vim.notify("No readable file to preview: " .. path, vim.log.levels.WARN)
    return
  end
  local ext = path:match("%.([^./]+)$")
  ext = ext and ext:lower() or ""
  if not (images[ext] or videos[ext] or documents[ext] or ext == "pdf") then
    vim.notify("Unsupported media type: " .. ext, vim.log.levels.WARN)
    return
  end

  local buf, win = open_window(path)
  show_text(buf, "Loading " .. path .. " …")
  if images[ext] then
    show_image(buf, path)
  elseif documents[ext] then
    run({ "pandoc", "--from", ext, "--to", "plain", path }, function(output)
      if output then show_text(buf, output) end
    end)
  elseif not require("snacks").image.supports_terminal() then
    show_text(buf, "Image preview requires Kitty graphics support in this terminal.")
  elseif ext == "pdf" then
    local page, serial, current = 1, 0, nil
    local function render()
      serial = serial + 1
      local requested = serial
      local image = vim.fn.tempname() .. ".png"
      run({ "pdftoppm", "-f", tostring(page), "-l", tostring(page), "-singlefile", "-scale-to", "1200", "-png", path, image:sub(1, -5) }, function(output)
        if not output or not vim.api.nvim_win_is_valid(win) or requested ~= serial then
          vim.fn.delete(image)
          return
        end
        if current then
          require("snacks").image.placement.clean(buf)
          vim.fn.delete(current)
        end
        current = image
        show_image(buf, image)
      end)
    end
    vim.api.nvim_create_autocmd("BufWipeout", { buffer = buf, once = true, callback = function() if current then vim.fn.delete(current) end end })
    vim.keymap.set("n", "]", function() page = page + 1; render() end, { buffer = buf, desc = "Next PDF page" })
    vim.keymap.set("n", "[", function() page = math.max(1, page - 1); render() end, { buffer = buf, desc = "Previous PDF page" })
    render()
  else
    local image = vim.fn.tempname() .. ".png"
    run({ "ffmpeg", "-loglevel", "error", "-y", "-i", path, "-frames:v", "1", image }, function(output)
      if not output or not vim.api.nvim_win_is_valid(win) then
        vim.fn.delete(image)
        return
      end
      show_image(buf, image, true)
    end)
  end
end

vim.api.nvim_create_autocmd("BufReadCmd", {
  pattern = { "*.pdf", "*.docx", "*.odt", "*.rtf", "*.epub", "*.mp4", "*.mov", "*.mkv", "*.webm", "*.avi", "*.m4v" },
  callback = function(args)
    local path = vim.api.nvim_buf_get_name(args.buf)
    vim.bo[args.buf].buftype = "nofile"
    vim.bo[args.buf].bufhidden = "wipe"
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(args.buf) then M.open(path) end
    end)
  end,
})

return M
