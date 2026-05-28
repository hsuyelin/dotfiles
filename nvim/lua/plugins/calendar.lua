local gh = function(r) return 'https://github.com/' .. r end

vim.pack.add({ gh('wsdjeg/calendar.nvim') })

-- ── Data paths ───────────────────────────────────────────────────────────────

local cache_dir  = vim.fn.stdpath('data') .. '/calendar-chinese-days'
local cache_file = cache_dir .. '/holidays.json'
local state_file = cache_dir .. '/state.json'
local todos_dir  = cache_dir .. '/todos'
local json_url   = 'https://raw.githubusercontent.com/lanceliao/china-holiday-calender/master/holidayAPI.json'

-- ── State helpers ─────────────────────────────────────────────────────────────
-- state.json tracks fetch failures so we retry up to 3×/day without data loss.
-- Shape: { failed=bool, failed_date="YYYY-MM-DD", daily_attempts=N }

local function read_state()
    local f = io.open(state_file, 'r')
    if not f then return {} end
    local raw = f:read('*a'); f:close()
    local ok, s = pcall(vim.json.decode, raw)
    return (ok and type(s) == 'table') and s or {}
end

local function write_state(s)
    vim.fn.mkdir(cache_dir, 'p')
    local out = io.open(state_file, 'w')
    if out then out:write(vim.json.encode(s)); out:close() end
end

-- True when the JSON cache is absent or older than 90 days.
local function data_stale()
    local stat = vim.uv.fs_stat(cache_file)
    if not stat then return true end
    return (os.time() - stat.mtime.sec) > 90 * 24 * 3600
end

-- True when a previous fetch failed and we still have retries left today.
local function should_retry()
    local s = read_state()
    if not s.failed then return false end
    local today = os.date('%Y-%m-%d')
    if s.failed_date ~= today then return true end   -- new day → fresh retries
    return (s.daily_attempts or 0) < 3
end

-- ── Async fetch ──────────────────────────────────────────────────────────────

-- holiday_set is module-level; cleared to nil on successful fresh fetch.
local _holiday_set = nil

local function async_fetch()
    vim.fn.mkdir(cache_dir, 'p')
    local tmp = cache_file .. '.tmp'
    vim.system(
        { 'curl', '-sL', '--connect-timeout', '10', '-o', tmp, json_url },
        {},
        function(result)
            vim.schedule(function()
                local today = os.date('%Y-%m-%d')
                if result.code == 0 then
                    -- Validate before replacing cached data
                    local f = io.open(tmp, 'r')
                    local raw = f and f:read('*a') or ''
                    if f then f:close() end
                    local ok, data = pcall(vim.json.decode, raw)
                    if ok and type(data) == 'table' and type(data.Years) == 'table' then
                        os.rename(tmp, cache_file)
                        _holiday_set = nil              -- force reload on next access
                        local s = read_state()
                        s.failed = false; s.failed_date = nil; s.daily_attempts = 0
                        write_state(s)
                    else
                        pcall(os.remove, tmp)
                        local s = read_state()
                        s.failed = true
                        if s.failed_date ~= today then
                            s.failed_date = today; s.daily_attempts = 1
                        else
                            s.daily_attempts = (s.daily_attempts or 0) + 1
                        end
                        write_state(s)
                        vim.notify(
                            string.format('[calendar] 节假日数据无效，今日第 %d 次失败', s.daily_attempts),
                            vim.log.levels.WARN
                        )
                    end
                else
                    pcall(os.remove, tmp)
                    local s = read_state()
                    s.failed = true
                    if s.failed_date ~= today then
                        s.failed_date = today; s.daily_attempts = 1
                    else
                        s.daily_attempts = (s.daily_attempts or 0) + 1
                    end
                    write_state(s)
                    vim.notify(
                        string.format('[calendar] 节假日数据拉取失败，今日第 %d 次失败（最多重试 3 次/天）',
                            s.daily_attempts),
                        vim.log.levels.WARN
                    )
                end
            end)
        end
    )
end

if data_stale() or should_retry() then async_fetch() end

-- ── Load holiday set ─────────────────────────────────────────────────────────
-- "YYYY-MM-DD" → { name = "节日名", memo = "详细说明" }
-- EndDate is INCLUSIVE in this API.

local function load_holiday_set()
    if _holiday_set then return _holiday_set end
    _holiday_set = {}

    local f = io.open(cache_file, 'r')
    if not f then return _holiday_set end
    local raw = f:read('*a'); f:close()
    if not raw or raw == '' then return _holiday_set end

    local ok, data = pcall(vim.json.decode, raw)
    if not ok or type(data) ~= 'table' or type(data.Years) ~= 'table' then
        return _holiday_set
    end

    for _, year_holidays in pairs(data.Years) do
        if type(year_holidays) == 'table' then
            for _, h in ipairs(year_holidays) do
                local name = type(h.Name)      == 'string' and h.Name      or nil
                local sd   = type(h.StartDate) == 'string' and h.StartDate or nil
                local ed   = type(h.EndDate)   == 'string' and h.EndDate   or nil
                local memo = type(h.Memo)      == 'string' and h.Memo      or ''
                if name and sd and ed then
                    local sy, sm, sday = sd:match('(%d%d%d%d)-(%d%d)-(%d%d)')
                    local ey, em, eday = ed:match('(%d%d%d%d)-(%d%d)-(%d%d)')
                    if sy and ey then
                        local t  = os.time({ year=tonumber(sy), month=tonumber(sm),
                                             day=tonumber(sday), hour=12 })
                        local te = os.time({ year=tonumber(ey), month=tonumber(em),
                                             day=tonumber(eday), hour=12 })
                        while t <= te do
                            local dt  = os.date('*t', t)
                            local key = string.format('%04d-%02d-%02d', dt.year, dt.month, dt.day)
                            _holiday_set[key] = { name = name, memo = memo }
                            t = t + 86400
                        end
                    end
                end
            end
        end
    end

    return _holiday_set
end

-- ── Quick preview popup ──────────────────────────────────────────────────────

local _popup_win = -1
local _popup_buf = -1

local function close_popup()
    if vim.api.nvim_win_is_valid(_popup_win) then
        pcall(vim.api.nvim_win_close, _popup_win, true)
    end
    if vim.api.nvim_buf_is_valid(_popup_buf) then
        pcall(vim.api.nvim_buf_delete, _popup_buf, { force = true })
    end
    _popup_win, _popup_buf = -1, -1
end

-- show_holiday_popup: always shows a popup (non-holiday → "无假期").
-- Positioned relative to the calendar window (bottom-left) so it's always visible
-- regardless of where the text cursor happens to be inside the buffer.
local function show_holiday_popup(year, month, day, name)
    close_popup()
    local date_line = string.format(' %d年%d月%d日 ', year, month, day)
    local name_line = string.format(' %s ', name)
    local width = math.max(
        vim.fn.strdisplaywidth(date_line),
        vim.fn.strdisplaywidth(name_line)
    )

    _popup_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(_popup_buf, 0, -1, false, { date_line, name_line })
    vim.api.nvim_buf_add_highlight(_popup_buf, -1, 'Title',           0, 0, -1)
    local hl = name == '（无假期）' and 'Comment' or 'DiagnosticError'
    vim.api.nvim_buf_add_highlight(_popup_buf, -1, hl, 1, 0, -1)

    -- Use relative='editor' so the popup is always on-screen, anchored near
    -- the bottom of the screen (independent of cursor position in the buffer).
    local screen_row = math.max(0, vim.o.lines - 6)
    local screen_col = 2
    _popup_win = vim.api.nvim_open_win(_popup_buf, false, {
        relative  = 'editor',
        row       = screen_row,
        col       = screen_col,
        width     = width,
        height    = 2,
        style     = 'minimal',
        border    = 'rounded',
        focusable = false,
    })
    vim.defer_fn(close_popup, 4000)
    vim.api.nvim_create_autocmd(
        { 'CursorMoved', 'CursorMovedI', 'WinLeave' },
        { once = true, callback = close_popup }
    )
end

-- ── Day detail window (Enter) ────────────────────────────────────────────────

local WEEKDAY = { '日', '一', '二', '三', '四', '五', '六' }

local function open_day_detail(year, month, day)
    local date_key  = string.format('%04d-%02d-%02d', year, month, day)
    local holiday   = load_holiday_set()[date_key]
    local todo_file = todos_dir .. '/' .. date_key .. '.txt'

    local wday  = os.date('*t', os.time({ year = year, month = month, day = day, hour = 12 })).wday
    local title = string.format('%d年%d月%d日  周%s', year, month, day, WEEKDAY[wday])
    local sep   = string.rep('─', vim.fn.strdisplaywidth(title))

    local lines = {}
    table.insert(lines, title)
    table.insert(lines, sep)
    if holiday then
        table.insert(lines, '假期：' .. holiday.name)
        if holiday.memo ~= '' then
            table.insert(lines, '')
            for _, mline in ipairs(vim.split(holiday.memo, '\n', { plain = true })) do
                if mline ~= '' then table.insert(lines, mline) end
            end
        end
    else
        table.insert(lines, '（非节假日）')
    end
    table.insert(lines, sep)
    table.insert(lines, '待办 Todo:')

    local todo_start = #lines + 1   -- 1-indexed first editable line

    local tf = io.open(todo_file, 'r')
    if tf then
        for l in tf:lines() do table.insert(lines, l) end
        tf:close()
    end
    if #lines < todo_start then
        table.insert(lines, '- [ ] ')
    end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].filetype   = 'markdown'
    vim.bo[buf].modifiable = true

    local max_w = 0
    for _, l in ipairs(lines) do
        max_w = math.max(max_w, vim.fn.strdisplaywidth(l))
    end
    local width  = math.min(math.max(max_w + 4, 44), vim.o.columns - 6)
    local height = math.min(math.max(#lines + 2, 10), vim.o.lines - 6)
    local win_cfg = {
        relative  = 'editor',
        row       = math.floor((vim.o.lines   - height) / 2),
        col       = math.floor((vim.o.columns - width)  / 2),
        width = width, height = height,
        style     = 'minimal',
        border    = 'rounded',
        focusable = true,
    }
    if vim.fn.has('nvim-0.9') == 1 then
        win_cfg.title     = ' ' .. date_key .. ' '
        win_cfg.title_pos = 'center'
    end
    local win = vim.api.nvim_open_win(buf, true, win_cfg)
    vim.api.nvim_win_set_cursor(win, { todo_start, 0 })

    local function save_todos()
        local all   = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local saved = {}
        for i = todo_start, #all do table.insert(saved, all[i]) end
        while #saved > 0 and saved[#saved]:match('^%s*$') do table.remove(saved) end
        vim.fn.mkdir(todos_dir, 'p')
        local out = io.open(todo_file, 'w')
        if out then
            for _, l in ipairs(saved) do out:write(l .. '\n') end
            out:close()
        end
    end

    local function close_detail()
        vim.cmd('stopinsert')
        save_todos()
        if vim.api.nvim_win_is_valid(win) then pcall(vim.api.nvim_win_close, win, true) end
        if vim.api.nvim_buf_is_valid(buf) then pcall(vim.api.nvim_buf_delete, buf, { force = true }) end
    end

    local kmo = { noremap = true, silent = true }
    local function km(mode, lhs, cb, desc)
        vim.api.nvim_buf_set_keymap(buf, mode, lhs, '',
            vim.tbl_extend('force', kmo, { callback = cb, desc = desc }))
    end

    km('n', 'q',     close_detail,                   'Close detail')
    km('n', '<Esc>', close_detail,                   'Close detail')
    km('n', '<C-s>', save_todos,                     'Save todos')
    km('i', '<C-s>', close_detail,                   'Save and close')
    km('n', 'o',     function()
        local cur   = vim.api.nvim_win_get_cursor(win)[1]
        local after = math.max(cur, todo_start - 1)
        vim.api.nvim_buf_set_lines(buf, after, after, false, { '- [ ] ' })
        vim.api.nvim_win_set_cursor(win, { after + 1, 6 })
        vim.cmd('startinsert!')
    end, 'New todo item')
end

-- ── Extension registration ──────────────────────────────────────────────────

local chinese_days_ext = {}
function chinese_days_ext.get(year, month)
    local set    = load_holiday_set()
    local marks  = {}
    local prefix = string.format('%04d-%02d-', year, month)
    for key in pairs(set) do
        if key:sub(1, 8) == prefix then
            table.insert(marks, {
                year  = year,
                month = month,
                day   = tonumber(key:sub(9, 10)),
            })
        end
    end
    return marks
end

chinese_days_ext.actions = {}
require('calendar.extensions').register('chinese_days', chinese_days_ext)

-- ── Patch view ──────────────────────────────────────────────────────────────

local _today = os.date('*t')
local _cal   = { year = _today.year, month = _today.month, day = _today.day }

local _view = require('calendar.view')
if not _view._patched then
    _view._patched = true
    local _orig_open      = _view.open
    local _orig_highlight = _view.highlight_day
    local _buf_patched    = false

    -- Keep _cal.day in sync with every navigation move.
    _view.highlight_day = function(day)
        _cal.day = day
        _orig_highlight(day)
    end

    _view.open = function(y, m, d)
        _cal.year, _cal.month, _cal.day = y, m, d or _cal.day
        local b, w = _orig_open(y, m, d)

        if not _buf_patched then
            _buf_patched = true

            -- Year navigation
            vim.api.nvim_buf_set_keymap(b, 'n', 'J', '', {
                desc     = 'Next year',
                callback = function() _view.open(_cal.year + 1, _cal.month) end,
            })
            vim.api.nvim_buf_set_keymap(b, 'n', 'K', '', {
                desc     = 'Previous year',
                callback = function() _view.open(_cal.year - 1, _cal.month) end,
            })

            -- p: quick preview popup for the SELECTED day (not cursor position).
            -- <Space> conflicts with mapleader; p is unused in the calendar buffer.
            -- Always shows a popup — "（无假期）" on non-holiday days — so the user
            -- gets clear feedback that the key works.
            vim.api.nvim_buf_set_keymap(b, 'n', 'p', '', {
                desc     = 'Preview holiday for selected day',
                callback = function()
                    local key     = string.format('%04d-%02d-%02d', _cal.year, _cal.month, _cal.day)
                    local holiday = load_holiday_set()[key]
                    local name    = holiday and holiday.name or '（无假期）'
                    show_holiday_popup(_cal.year, _cal.month, _cal.day, name)
                end,
            })

            -- Mouse click: run original handler then show holiday popup
            local orig_mouse
            for _, km in ipairs(vim.api.nvim_buf_get_keymap(b, 'n')) do
                if km.lhs == '<LeftMouse>' then orig_mouse = km.callback; break end
            end
            if orig_mouse then
                vim.api.nvim_buf_set_keymap(b, 'n', '<LeftMouse>', '', {
                    desc     = 'Click day / show holiday',
                    callback = function()
                        orig_mouse()
                        if vim.api.nvim_get_current_buf() ~= b then return end
                        local day     = tonumber(vim.fn.expand('<cword>'))
                        if not day then return end
                        local key     = string.format('%04d-%02d-%02d', _cal.year, _cal.month, day)
                        local holiday = load_holiday_set()[key]
                        if holiday then
                            show_holiday_popup(_cal.year, _cal.month, day, holiday.name)
                        end
                        -- Mouse click on non-holiday: no popup (click is already visual feedback)
                    end,
                })
            end
        end

        return b, w
    end
end

-- ── Patch on_action (Enter) ─────────────────────────────────────────────────
-- view.lua's <Enter> passes calendar.day — the plugin's internally tracked
-- selected day, which is independent of cursor position.

local _ext = require('calendar.extensions')
_ext.on_action = function(year, month, day)
    open_day_detail(year, month, day)
end

-- ── Setup ────────────────────────────────────────────────────────────────────

require('calendar').setup({
    locale             = 'zh-CN',
    mark_icon          = '●',
    show_adjacent_days = true,
    keymap = {
        next_month     = 'L',
        previous_month = 'H',
        next_day       = 'l',
        previous_day   = 'h',
        next_week      = 'j',
        previous_week  = 'k',
        today          = 't',
        close          = 'q',
    },
    highlights = {
        current       = 'Visual',
        today         = 'Todo',
        mark          = 'DiagnosticError',
        adjacent_days = 'Comment',
    },
})

require('which-key').add({
    { '<leader>aC', function() vim.cmd('Calendar') end, desc = '日历 (Calendar)' },
})
