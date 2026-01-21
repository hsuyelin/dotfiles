---@class utils.dashboard
---@overload fun(opts?: utils.dashboard.Opts): utils.dashboard.Class
local M = setmetatable({}, {
	__call = function(M, opts)
		return M.open(opts)
	end,
})

M.sections = {}

---@alias utils.dashboard.Gen fun(utils.dashboard.Class) :utils.dashboard.Section
---@alias utils.dashboard.Section utils.dashboard.Gen|utils.dashboard.Section[]

---@return utils.dashboard.Section
function M.sections.header()
	---@param self utils.dashboard.Class
	return function(self)
		return { header = self.opts.present.header }
	end
end

---@return utils.dashboard.Section
function M.sections.keys()
	---@param self utils.dashboard.Class
	return function(self)
		return vim.deepcopy(self.opts.present.keys)
	end
end

---@return utils.dashboard.Section
function M.sections.startup()
	---@param opts utils.dashboard.Class
	return function(opts)
		opts = opts or {}
		M.lazy_stats = M.lazy_stats and M.lazy_stats.startuptime > 0 and M.lazy_stats or require("lazy.stats").stats()
		-- NOTE: don't know why the startuptime in my machine is always 0
		M.lazy_stats.startuptime = M.lazy_stats.startuptime ~= 0 and M.lazy_stats.startuptime
			or M.lazy_stats.times.LazyDone + M.lazy_stats.times.LazyStart
		local ms = (math.floor(M.lazy_stats.startuptime * 100 + 0.5) / 100)
		local icon = opts.icon or "⚡ "
		return {
			align = "center",
			text = {
				{ icon .. "Loaded ", hl = "footer" },
				{
					M.lazy_stats.loaded .. "/" .. M.lazy_stats.count,
					hl = "special",
				},
				{ " plugins in ", hl = "footer" },
				{ ms .. "ms", hl = "special" },
			},
		}
	end
end

---@param opts {filter?: table<string, boolean>}?
---@return fun():string?
function M.oldfiles(opts)
	opts = vim.tbl_deep_extend("force", {
		filter = {
			[vim.fn.stdpath("data")] = false,
			[vim.fn.stdpath("cache")] = false,
			[vim.fn.stdpath("state")] = false,
		},
	}, opts or {})
	---@cast opts {filter: table<string, boolean>}
	local filters = {} ---@type {path:string, want:string}[]
	for path, want in pairs(opts.filter or {}) do
		table.insert(filters, { path = vim.fs.normalize(path), want = want })
	end
	local i = 1
	local oldfiles = vim.v.oldfiles
	local done = {} ---@type {[string]:boolean}
	return function()
		while oldfiles[i] do
			local path = vim.fs.normalize(oldfiles[i])
			local want = not done[path]
			if want then
				done[path] = true
				for _, filter in ipairs(filters) do
					if (path:sub(1, #filter.path) == filter.path) ~= filter.want then
						want = false
						break
					end
				end
			end
			i = i + 1
			if want and vim.uv.fs_stat(path) then
				return path
			end
		end
	end
end

---@param opts{limit:number?, cwd: string|boolean, filter:fun(string):boolean?}
---@return utils.dashboard.Section
function M.sections.recent_files(opts)
	return function()
		opts = opts or {}
		local limit = opts.limit or 5
		local root = opts.cwd or false
		root = opts.cwd and vim.fs.normalize(type(root) == "string" and root or root and vim.fn.getcwd() or "") or ""
		local ret = {} ---@type utils.dashboard.Section
		for file in M.oldfiles({ filter = { [root] = true } }) do
			if not opts.filter or opts.filter(file) then
				ret[#ret + 1] = {
					file = file,
					icon = "file",
					autokey = true,
					action = ":e " .. vim.fn.fnameescape(file),
				}
				if #ret >= limit then
					break
				end
			end
		end
		return ret
	end
end

---@param opts { limit?:number, dirs?: (string[]|fun():string[]), markers?:string[], filter?:(fun(dir:string):boolean?), action?: (fun(dir:string)) }
---@return utils.dashboard.Section
function M.sections.projects(opts)
	opts = opts or {}
	local limit = opts.limit or 5
	local dirs = opts.dirs or {}
	dirs = type(dirs) == "function" and dirs() or dirs --[[ @as string[] ]]
	dirs = vim.list_slice(dirs, 1, limit)

	if not opts.dirs then
		for file in M.oldfiles() do
			local dir = vim.fs.root(file, opts.markers or { ".project", ".git" })
			if dir and not vim.tbl_contains(dirs, dir) then
				table.insert(dirs, dir)
				if #dirs >= limit then
					break
				end
			end
		end
	end

	local ret = {} ---@type utils.dashboard.Section
	for _, dir in ipairs(dirs) do
		if not opts.filter or opts.filter(dir) then
			ret[#ret + 1] = {
				icon = "directory",
				file = dir,
				autokey = true,
				action = function()
					if opts.action then
						return opts.action(dir)
					end
					vim.fn.chdir(dir)
					-- TODO: implement sessions
				end,
			}
		end
	end
	return ret
end

---@class utils.dashboard.Text
---@field [1] string
---@field width? number
---@field align? "left" | "center" | "right"
---@field hl? string

---@class utils.dashboard.Line
---@field [number] utils.dashboard.Text
---@field width number

---@class utils.dashboard.Block
---@field [number] utils.dashboard.Line
---@field width number

---@alias utils.dashboard.Format.ctx {width?:number}

---@class utils.dashboard.Config
---@field sections? utils.dashboard.Section[]
---@field pane_gap? number
---@field width? number
---@field col? number
---@field row? number
---@field formats? table<string, utils.dashboard.Text|fun(item: utils.dashboard.Item, ctx:utils.dashboard.Format.ctx):utils.dashboard.Text>
local defaults = {
	pane_gap = 4,
	width = 60,
	col = nil,
	row = nil,
	autokeys = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", -- autokey sequence
	present = {
-- 		header = [[
-- ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
-- ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
-- ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
-- ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
-- ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
-- ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]],
		header = [[]],
		keys = {
			{ icon = " ", key = "f", desc = "Find File", action = ":Telescope find_files" },
			{ icon = " ", key = "s", desc = "Find Text", action = ":Telescope live_grep" },
			{ icon = " ", key = "r", desc = "Recent Files", action = ":Telescope oldfiles" },
			{ icon = " ", key = "c", desc = "Config", action = ":cd ~/.config/nvim" },
			{ icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy" },
			{ icon = " ", key = "q", desc = "Quit", action = ":quitall" },
		},
	},
	sections = {
		{ section = "header" },
		{ section = "keys", gap = 1, padding = 1 },
		{ section = "startup" },
	},
	formats = {
		icon = function(item)
			local icon = item.icon
			if item.icon == "file" or item.icon == "directory" then
				icon = M.icon(item.file, item.icon)
			end
			return { icon, hl = "icon", width = 2 }
		end,
		file = function(item, ctx)
			local fname = vim.fn.fnamemodify(item.file, ":~")
			fname = ctx.width and #fname > ctx.width and vim.fn.pathshorten(fname) or fname
			local dir = vim.fn.fnamemodify(fname, ":h")
			local file = vim.fn.fnamemodify(fname, ":t")
			if #fname > ctx.width and dir and file then
				file = file:sub(-(ctx.width - #dir - 2))
				fname = dir .. "/…" .. file
			end
			return dir and { { dir .. "/", hl = "dir" }, { file, hl = "file" } } or { { fname, hl = "file" } }
		end,
		header = { "%s", align = "center" },
	},
}

---@param name string
---@param cat? "file"|"filetype"|"extension"|"directory"
---@param opts? {fallback?:{file?:string, dir?: string}}
---@return string
function M.icon(name, cat, opts)
	opts = opts or {}
	opts.fallback = opts.fallback or {}
	local tries = {
		function()
			if cat == "directory" then
				return opts.fallback.dir or "󰉋 "
			end
			local Icon = require("nvim-web-devicons")
			if cat == "filetype" then
				Icon.get_icon_by_filetype(name, { default = false })
			elseif cat == "extension" then
				Icon.get_icon(nil, name, { default = false })
			elseif cat == "file" then
				local ext = name:match("%.(%w+)$")
				return Icon.get_icon(name, ext, { default = false })
			end
		end,
	}
	for _, fn in ipairs(tries) do
		local ok, icon = pcall(fn)
		if ok and icon then
			return icon
		end
	end
	return opts.fallback.file or "󰈔 "
end

---@class utils.dashboard.Opts: utils.dashboard.Config
---@field buf? number
---@field win? number

local wo = {
	colorcolumn = "",
	cursorcolumn = false,
	cursorline = false,
	foldmethod = "manual",
	list = false,
	number = false,
	relativenumber = false,
	---
	spell = false,
	winbar = "",
	wrap = false,
}

local bo = {
	bufhidden = "wipe",
	buftype = "nofile",
	buflisted = false,
	filetype = "dashboard",
	swapfile = false,
	undofile = false,
}

-- dealing with highlights
M.ns = vim.api.nvim_create_namespace("dashboard")
local links = {
	Header = "Title",
	Icon = "Special",
	Desc = "Special",
	Key = "Number",
	Footer = "Title",
	Special = "Special",
	File = "Special",
	Dir = "NonText",
}
local hl_groups = {}
for k, v in pairs(links) do
	local hl_name = "Dashboard" .. k
	hl_groups[k:lower()] = hl_name
	-- TODO: set it non-global
	vim.api.nvim_set_hl(0, hl_name, { link = v })
end

---@alias utils.dashboard.Action string|fun(self:utils.dashboard.Class)

---@class utils.dashboard.Item
---@field enabled? boolean|fun(opts:utils.dashboard.Opts):boolean if false, the section will be disabled
---@field title? string
---@field section? utils.dashboard.Item
---@field hidden? boolean
---@field autokey? boolean
---@field action? utils.dashboard.Action
---@field key? string
---@field indent? number
---@field align? "left" | "center" | "right"
---@field gap? number the number of empty lines between child items
---@field padding? number | {[1]:number, [2]:number} bottom or {bottom, top} padding
---@field file? string
---@field footer? string
---@field header? string
---@field icon? string
---@field text? string|utils.dashboard.Text[]
---@field [string] any

---@class utils.dashboard.Class
---@field win number
---@field buf number
---@field opts utils.dashboard.Opts
---@field augroup number
---@field panes? utils.dashboard.Item[][]
---@field icon? string
local D = {}

function D:init()
	vim.api.nvim_win_set_buf(self.win, self.buf)
	vim.o.ei = "all"
	-- setup wo
	for name, value in pairs(wo) do
		vim.api.nvim_set_option_value(name, value, { scope = "local", win = self.win })
	end
	-- setup bo
	for name, value in pairs(bo) do
		vim.api.nvim_set_option_value(name, value, { scope = "local", buf = self.buf })
	end
	vim.o.ei = ""
	if self:is_float() then
		vim.keymap.set("n", "<esc>", "<cmd>bd<cr>", { silent = true, buffer = self.buf })
	end
	vim.keymap.set("n", "q", "<cmd>bd<cr>", { silent = true, buffer = self.buf })
	vim.api.nvim_create_autocmd({ "WinResized", "VimResized" }, {
		group = self.augroup,
		callback = function()
			self:update()
		end,
	})
	vim.api.nvim_create_autocmd({ "BufWipeout", "BufDelete" }, {
		group = self.augroup,
		callback = function()
			vim.api.nvim_del_augroup_by_id(self.augroup)
		end,
	})
end

function D:update()
	if not (self.buf and vim.api.nvim_buf_is_valid(self.buf)) then
		return
	end
	self._size = self:size()
	self.items = self:resolve(self.opts.sections)
	self:layout()
	self:keys()
	self:render()
end

function D:keys()
	local autokeys = self.opts.autokeys:gsub("[hjklq]", "")
	for _, item in ipairs(self.items) do
		if item.key and not item.autokey then
			autokeys = autokeys:gsub(vim.pesc(item.key), "")
		end
	end
	for _, item in ipairs(self.items) do
		if item.autokey then
			item.key, autokeys = autokeys:sub(1, 1), autokeys:sub(2)
		end
		if item.key then
			vim.keymap.set("n", item.key, function()
				self:action(item.action)
			end, {
				buffer = self.buf,
				nowait = not item.autokey,
				silent = true,
				desc = "Dashboard Action",
			})
		end
	end
end

---@param action utils.dashboard.Action
function D:action(action)
	if self:is_float() then
		vim.api.nvim_win_close(self.win, true)
		self.win = nil
	end
	if type(action) == "string" then
		if action:find("^:") then
			return vim.cmd(action:sub(2))
		else
			local keys = vim.api.nvim_replace_termcodes(action, true, true, true)
			return vim.api.nvim_feedkeys(keys, "tm", true)
		end
	end
	action(self)
end

function D:layout()
	local max_panes =
		math.max(1, math.floor((self._size.width + self.opts.pane_gap) / (self.opts.width + self.opts.pane_gap)))
	self.panes = {} ----@type utils.dashboard.Item[][]
	for _, item in ipairs(self.items) do
		if not item.hidden then
			local pane = item.pane or 1
			pane = math.fmod(pane - 1, max_panes) + 1
			self.panes[pane] = self.panes[pane] or {}
			table.insert(self.panes[pane], item)
		end
	end
	for i = 1, math.max(unpack(vim.tbl_keys(self.panes))) do
		self.panes[i] = self.panes[i] or {}
	end
end

function D:render()
	self.col = self.opts.col
		or math.floor(self._size.width - (self.opts.width * #self.panes + self.opts.pane_gap * (#self.panes - 1)))
			/ 2

	local lines = {}
	local extmarks = {} ---@type { row: number, col: number, opts: vim.api.keyset.set_extmark }[]
	for p, pane in ipairs(self.panes) do
		local indent = (" "):rep(p == 1 and self.col or (self.opts.pane_gap or 0))
		local row = 0
		for _, item in ipairs(pane) do
			for _, line in ipairs(self:format(item)) do
				row = row + 1
				if p > 1 and not lines[row] then
					lines[row] = (" "):rep(self.col + (self.opts.pane_gap * self.opts.width) * (p - 1))
				elseif p == 1 and line.width > self.opts.width then
					lines[row] = (" "):rep(self.col - math.floor((line.width - self.opts.width) / 2))
				else
					lines[row] = (lines[row] or "") .. indent
				end
				for _, text in ipairs(line) do ---@type utils.dashboard.Text
					lines[row] = lines[row] .. text[1]
					if text.hl then
						table.insert(extmarks, {
							row = row - 1,
							col = #lines[row] - #text[1],
							opts = { hl_group = hl_groups[text.hl] or text.hl, end_col = #lines[row] },
						})
					end
				end
			end
		end
	end
	-- vertical position
	local above = math.max(math.floor((self._size.height - #lines) / 2), 0)
	for _ = 1, above do
		table.insert(lines, 1, "")
	end

	vim.bo[self.buf].modifiable = true
	vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, lines)
	vim.bo[self.buf].modifiable = false

	vim.api.nvim_buf_clear_namespace(self.buf, M.ns, 0, -1)
	for _, mark in ipairs(extmarks) do
		vim.api.nvim_buf_set_extmark(self.buf, M.ns, above + mark.row, mark.col, mark.opts)
	end
end

---@param item utils.dashboard.Item
---@return utils.dashboard.Block
function D:format(item)
	local width = item.indent or 0

	---@param fields string[]
	---@param opts {multi?:boolean, padding?: number, flex?: boolean}
	---@return utils.dashboard.Block
	local function find(fields, opts)
		local flex = opts.flex and math.max(0, self.opts.width - width) or nil
		local texts = {} ---@type utils.dashboard.Text[]
		for _, field in ipairs(fields) do
			if item[field] then
				vim.list_extend(texts, self:texts(self:format_field(item, field, flex)))
			end
			if not opts.multi then
				break
			end
		end
		local block = self:block(texts)
		block.width = block.width + (opts.padding or 0)
		width = width + block.width
		return block
	end

	local block = item.text and self:block(self:texts(item.text))
	local left = block and { width = 0 } or find({ "icon" }, { multi = false, padding = 1 })
	local right = block and { width = 0 } or find({ "key" }, { multi = false, padding = 1 })
	local center = block or find({ "header", "desc", "file", "title" }, { multi = true, flex = true })

	local ret = { width = 0 } ---@type utils.dashboard.Block

	local padding = self:padding(item)
	for i = 1, math.max(#center, #left, #right, 1) + padding[1] do
		ret[i] = { width = 0 }
		left[i] = left[i] or { width = 0 }
		right[i] = right[i] or { width = 0 }
		center[i] = center[i] or { width = 0 }
		self:align(left[i], left.width, "left")
		if item.indent then
			self:align(left[i], left[i].width + item.indent, "right")
		end
		self:align(right[i], right.width, "right")
		self:align(center[i], self.opts.width - left[i].width - right[i].width, item.align)
		vim.list_extend(ret[i], left[i] or { width = 0 })
		vim.list_extend(ret[i], center[i] or { width = 0 })
		vim.list_extend(ret[i], right[i] or { width = 0 })
	end
	for _ = 1, padding[2] do
		table.insert(ret, 1, { width = 0 })
	end
	return ret
end

---@param item utils.dashboard.Item
---@return {[1]: number,[2]: number }
function D:padding(item)
	-- NOTE: prevent gratuious warning from lus_ls
	local padding = item.padding or { 0, 0 }
	return type(padding) == "table" and padding or { padding, 0 }
	-- return item.padding and (type(item.padding) == "table" and item.padding or { item.padding, 0 }) or { 0, 0 }
end

---@param texts utils.dashboard.Text[]
---@return utils.dashboard.Block
function D:block(texts)
	local ret = { { width = 0 }, width = 0 } ---@type utils.dashboard.Block
	for _, text in ipairs(texts) do
		local lines = text[1]:find("\n") and vim.split(text[1], "\n") or { text[1] }
		for l, line in ipairs(lines) do
			if l > 1 then
				ret[#ret + 1] = { width = 0 }
			end
			local child = setmetatable({ line }, { __index = text })
			self:align(child)
			ret[#ret].width = ret[#ret].width + vim.api.nvim_strwidth(child[1])
			ret.width = math.max(ret.width, ret[#ret].width)
			table.insert(ret[#ret], child)
		end
	end
	return ret
end

---@param item utils.dashboard.Item
---@param field string
---@param width? number
---@return utils.dashboard.Text|utils.dashboard.Text[]
function D:format_field(item, field, width)
	local format = self.opts.formats[field]
	if format == nil then
		return { item[field], hl = field }
	elseif type(format) == "function" then
		return format(item, { width = width })
	else
		local text = format and vim.deepcopy(format) or { "%s" }
		text.hl = text.hl or field
		text[1] = text[1] == "%s" and item[field] or text[1]:format(item[field])
		return text
	end
end

---@param texts string|utils.dashboard.Text|utils.dashboard.Text[]
---@return utils.dashboard.Text[]
function D:texts(texts)
	texts = type(texts) == "string" and { { texts } } or texts
	texts = type(texts[1]) == "string" and { texts } or texts
	return texts --[[ @as utils.dashboard.Text[] ]]
end

---@param item utils.dashboard.Text|utils.dashboard.Line
---@param width? number
---@param align? "left" | "center" | "right"
---@return nil
function D:align(item, width, align)
	local len = 0
	if type(item[1]) == "string" then ---@cast item utils.dashboard.Text
		width, align, len = width or item.width, align or item.align, vim.api.nvim_strwidth(item[1])
	else ---@cast item utils.dashboard.Line
		if #item == 1 then -- only one text, so align that instead
			self:align(item[1], width, align)
			item.width = item[1].width
			return
		end
		len = item.width
	end

	if not width or width <= 0 or width == len then
		item.width = math.max(width or 0, len)
		return
	end

	align = align or "left"
	local before = align == "center" and math.floor((width - len) / 2) or align == "right" and width - len or 0
	local after = align == "center" and width - len - before or align == "left" and width - len or 0

	if type(item[1]) == "string" then ---@cast item utils.dashboard.Text
		item[1] = (" "):rep(before) .. item[1] .. (" "):rep(after)
	else ---@cast item utils.dashboard.Line
		if before > 0 then
			table.insert(item, 1, { (" "):rep(before) })
		end
		if after > 0 then
			table.insert(item, { (" "):rep(after) })
		end
	end
	item.width = math.max(width, len)
end

---@param item utils.dashboard.Item?
---@param results? utils.dashboard.Item[]
---@param parent? utils.dashboard.Item
function D:resolve(item, results, parent)
	-- print("resolving: " .. vim.inspect(item))
	results = results or {}
	if not item then
		return results
	end
	if type(item) == "table" and vim.tbl_isempty(item) then
		return results
	end
	if type(item) == "table" and parent then
		for _, prop in ipairs({ "pane", "indent" }) do
			item[prop] = item[prop] or parent[prop]
		end
	end
	if type(item) == "function" then
		return self:resolve(item(self), results, parent)
	elseif type(item) == "table" and self:is_enabled(item) then
		if not item.section and not item[1] then
			table.insert(results, item)
			return results
		end
		local first_child = #results + 1
		if item.section then
			local section = M.sections[item.section](item)
			self:resolve(section, results, item)
		end
		if item[1] then
			for _, child in ipairs(item) do
				self:resolve(child, results, item)
			end
		end

		-- add title
		if #results >= first_child and item.title then
			---@type utils.dashboard.Item
			local title = {
				icon = item.icon,
				title = item.title,
				pane = item.pane,
			}
			table.insert(results, first_child, title)
			first_child = first_child + 1
		end

		local first, last = first_child, #results

		if item.gap then -- add padding between child items
			for i = first, last - 1 do
				results[i].padding = item.gap
			end
		end

		if item.padding then
			local padding = self:padding(item)
			if padding[2] > 0 and results[first] then
				results[first].padding = padding[2]
			end
			if padding[1] > 0 and results[last] then
				results[last].padding = padding[1]
			end
		end
	end

	return results
end

---@param item utils.dashboard.Item
function D:is_enabled(item)
	local e = item.enabled
	if type(e) == "function" then
		return e(self.opts)
	end
	return e == nil or e
end

---@return { width: number, height: number }
function D:size()
	return {
		width = vim.api.nvim_win_get_width(self.win),
		height = vim.api.nvim_win_get_height(self.win),
	}
end

function D:is_float()
	return vim.api.nvim_win_get_config(self.win).relative ~= ""
end

---Open a new dashboard
---@param opts? utils.dashboard.Opts
---@return utils.dashboard.Class
function M.open(opts)
	local self = setmetatable({}, { __index = D })
	---@type utils.dashboard.Opts
	self.opts = vim.tbl_extend("force", defaults, opts or {})
	self.buf = self.opts.buf or vim.api.nvim_create_buf(false, true)
	self.buf = self.buf == 0 and vim.api.nvim_get_current_buf() or self.buf
	self.win = self.opts.win or 0
	self.win = self.win == 0 and vim.api.nvim_get_current_win() or self.win
	self.augroup = vim.api.nvim_create_augroup("utils_dashboard", { clear = true })
	self:init()
	self:update()
	return self
end

return M
