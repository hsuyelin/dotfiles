local gh = function(r) return 'https://github.com/' .. r end

vim.pack.add({ gh('wsdjeg/calendar.nvim') })

-- ── Data paths ───────────────────────────────────────────────────────────────

local cache_dir  = vim.fn.stdpath('data') .. '/calendar-chinese-days'
local cache_file = cache_dir .. '/holidays.json'
local obs_file   = cache_dir .. '/observances.json'
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
                        _obs_set     = nil              -- invalidate observance cache too
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

-- Forward declaration so load_holiday_set can call load_obs_set even though the
-- full Observances section appears later in the file.
local load_obs_set

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
                            _holiday_set[key] = {
                                name = name, memo = memo, kind = 'public',
                            }
                            t = t + 86400
                        end
                    end
                end
            end
        end
    end

    -- Merge observances. Public holidays take precedence on conflict.
    -- When both fall on the same day, keep the public entry and tag it
    -- with kind='both' plus the observance name for display purposes.
    for k, v in pairs(load_obs_set()) do
        if _holiday_set[k] then
            _holiday_set[k].kind     = 'both'
            _holiday_set[k].obs_name = v.name
        else
            _holiday_set[k] = v
        end
    end

    return _holiday_set
end

-- ── Observances ──────────────────────────────────────────────────────────────
-- Three categories merged into _holiday_set (public holidays take precedence).
--
--  FIXED_OBS      – fixed international/Chinese dates every year
--  VARIABLE_WEST  – Western holidays on the Nth weekday of a month
--  LUNAR_HOLIDAYS – Chinese traditional holidays, precomputed 2020-2041
--                   (generated from lunardate; laba2 = rare double 腊八 year)

local FIXED_OBS = {
    { m = 2,  d = 14, name = '情人节'    },
    { m = 3,  d =  8, name = '三八妇女节' },
    { m = 3,  d = 12, name = '植树节'    },
    { m = 4,  d =  1, name = '愚人节'    },
    { m = 5,  d =  4, name = '五四青年节' },
    { m = 6,  d =  1, name = '六一儿童节' },
    { m = 8,  d =  1, name = '八一建军节' },
    { m = 9,  d = 10, name = '教师节'    },
    { m = 10, d = 31, name = '万圣节'    },
    { m = 11, d = 11, name = '光棍节'    },
    { m = 12, d = 24, name = '平安夜'    },
    { m = 12, d = 25, name = '圣诞节'    },
}

-- nth: 1-indexed occurrence; wday: 1=Sun … 7=Sat (matches os.date)
local VARIABLE_WEST = {
    { m = 5,  nth = 2, wday = 1, name = '母亲节' },  -- 2nd Sunday of May
    { m = 6,  nth = 3, wday = 1, name = '父亲节' },  -- 3rd Sunday of June
    { m = 11, nth = 4, wday = 5, name = '感恩节' },  -- 4th Thursday of November
}

-- Gregorian dates of Chinese traditional holidays, derived from lunardate.
-- Organised by the Gregorian year in which each holiday falls.
-- Positional order: { yuanxiao, qixi, zhongyuan, chongyang [, laba [, laba2]] }
-- laba is absent in years where lunar 12/8 falls outside this Gregorian year.
-- laba2: rare case where two 腊八节 fall in the same Gregorian year.
local LUNAR_HOLIDAYS = {
    [2020] = {'02-08','08-25','09-02','10-25','01-02'},
    [2021] = {'02-26','08-14','08-22','10-14','01-20'},
    [2022] = {'02-15','08-04','08-12','10-04','01-10','12-30'},
    [2023] = {'02-05','08-22','08-30','10-23'},
    [2024] = {'02-24','08-10','08-18','10-11','01-18'},
    [2025] = {'02-12','08-29','09-06','10-29','01-07'},
    [2026] = {'03-03','08-19','08-27','10-18','01-26'},
    [2027] = {'02-20','08-08','08-16','10-08','01-15'},
    [2028] = {'02-09','08-26','09-03','10-26','01-04'},
    [2029] = {'02-27','08-16','08-24','10-16','01-22'},
    [2030] = {'02-17','08-05','08-13','10-05','01-11'},
    [2031] = {'02-06','08-24','09-01','10-24','01-01'},
    [2032] = {'02-25','08-12','08-20','10-12','01-20'},
    [2033] = {'02-14','08-01','08-09','10-01','01-08'},
    [2034] = {'03-05','08-20','08-28','10-20','01-27'},
    [2035] = {'02-22','08-10','08-18','10-09','01-16'},
    [2036] = {'02-11','08-28','09-05','10-27','01-05'},
    [2037] = {'03-01','08-17','08-25','10-17','01-23'},
    [2038] = {'02-18','08-07','08-15','10-07','01-12'},
    [2039] = {'02-07','08-26','09-03','10-26','01-02'},
    [2040] = {'02-26','08-14','08-22','10-14','01-21'},
    [2041] = {'02-15','08-03','08-11','10-03','01-10','12-30'},
}

-- Names matching the positional order in LUNAR_HOLIDAYS rows.
local _LUNAR_NAMES = { '元宵节', '七夕', '中元节', '重阳节', '腊八节', '腊八节' }

-- Returns which calendar-day the Nth occurrence of wday falls on in (year, month).
local function nth_weekday_day(year, month, nth, wday)
    local first = os.date(
        '*t', os.time({ year = year, month = month, day = 1, hour = 12 })
    ).wday
    local offset = (wday - first + 7) % 7
    return 1 + offset + (nth - 1) * 7
end

-- Build flat { ["YYYY-MM-DD"] = { name, kind='obs', memo='' } } for one year.
local function build_year_obs(year)
    local t = {}
    for _, v in ipairs(FIXED_OBS) do
        local key = string.format('%04d-%02d-%02d', year, v.m, v.d)
        t[key] = { name = v.name, kind = 'obs', memo = '' }
    end
    for _, v in ipairs(VARIABLE_WEST) do
        local day = nth_weekday_day(year, v.m, v.nth, v.wday)
        local key = string.format('%04d-%02d-%02d', year, v.m, day)
        t[key] = { name = v.name, kind = 'obs', memo = '' }
    end
    local lunar = LUNAR_HOLIDAYS[year]
    if lunar then
        for i, name in ipairs(_LUNAR_NAMES) do
            if lunar[i] then
                local key = string.format('%04d-%s', year, lunar[i])
                t[key] = { name = name, kind = 'obs', memo = '' }
            end
        end
    end
    return t
end

-- _obs_set: flat merged table, populated once per session.
-- Cache file covers current year + next year; recomputed when either is missing.
local _obs_set = nil

load_obs_set = function()
    if _obs_set then return _obs_set end

    local today_y = os.date('*t').year
    local need    = { tostring(today_y), tostring(today_y + 1) }

    local from_file, covered = {}, false
    local f = io.open(obs_file, 'r')
    if f then
        local raw = f:read('*a'); f:close()
        local ok, data = pcall(vim.json.decode, raw)
        if ok and type(data) == 'table'
                and data[need[1]] ~= nil and data[need[2]] ~= nil then
            covered = true
            for _, yr_data in pairs(data) do
                for k, v in pairs(yr_data) do from_file[k] = v end
            end
        end
    end

    if covered then
        _obs_set = from_file
        return _obs_set
    end

    -- Compute both years and persist synchronously (pure arithmetic, fast).
    local computed = {}
    for _, ys in ipairs(need) do
        computed[ys] = build_year_obs(tonumber(ys))
    end
    vim.fn.mkdir(cache_dir, 'p')
    local out = io.open(obs_file, 'w')
    if out then out:write(vim.json.encode(computed)); out:close() end

    _obs_set = {}
    for _, yr_data in pairs(computed) do
        for k, v in pairs(yr_data) do _obs_set[k] = v end
    end
    return _obs_set
end

-- ── Calendar state (must be declared before popup helpers that reference it) ─

local _today = os.date('*t')
local _cal   = {
    year  = _today.year,
    month = _today.month,
    day   = _today.day,
    win   = -1,
    buf   = -1,   -- set after first view.open; used by highlight_day recolor hook
}

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
-- Appears to the right of the calendar floating window when possible;
-- falls back to bottom-left of screen if the calendar win is gone.
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

    -- Compute position: right of the calendar window, same top row.
    local pop_row, pop_col
    if vim.api.nvim_win_is_valid(_cal.win) then
        local cfg = vim.api.nvim_win_get_config(_cal.win)
        pop_row = cfg.row
        pop_col = cfg.col + cfg.width + 2   -- 2-column gap between calendar and popup
        -- Clamp so the popup never exceeds the right edge of the screen
        pop_col = math.min(pop_col, vim.o.columns - width - 2)
    else
        pop_row = math.max(0, vim.o.lines - 6)
        pop_col = 2
    end

    _popup_win = vim.api.nvim_open_win(_popup_buf, false, {
        relative  = 'editor',
        row       = pop_row,
        col       = pop_col,
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
        if holiday.kind == 'both' then
            table.insert(lines, '假期：' .. holiday.name)
            table.insert(lines, '节日：' .. holiday.obs_name)
        elseif holiday.kind == 'obs' then
            table.insert(lines, '节日：' .. holiday.name)
        else
            table.insert(lines, '假期：' .. holiday.name)
        end
        if holiday.memo ~= '' then
            table.insert(lines, '')
            for _, ml in ipairs(vim.split(holiday.memo, '\n', { plain = true })) do
                if ml ~= '' then table.insert(lines, ml) end
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

-- ── Observance mark colours ──────────────────────────────────────────────────
-- kind='obs'  → yellow   (international observance only)
-- kind='both' → orange   (public holiday + observance on the same day)
-- kind='public' keeps the default DiagnosticError (red) mark from calendar.nvim.

vim.api.nvim_set_hl(0, 'CalendarObs',  { fg = '#FFD700', bold = true })
vim.api.nvim_set_hl(0, 'CalendarBoth', { fg = '#FF8C00', bold = true })

-- Runs after calendar.nvim's set_mark() to recolour obs/both day marks.
-- Uses the same grid-position formula as view.lua so we can locate the exact
-- extmark and update its highlight in-place (no position conflicts).
local function recolor_obs_marks(buf, year, month)
    local cal_ns = vim.api.nvim_get_namespaces()['calendar.nvim']
    if not cal_ns then return end

    local grid = require('calendar.model').build_month_grid(year, month)
    local set  = load_holiday_set()
    local icon = require('calendar.config').get().mark_icon

    local is_cm = false
    for row, week in ipairs(grid) do
        for col, val in ipairs(week) do
            local d = tonumber(val)
            if is_cm and d == 1 then
                is_cm = false
            elseif not is_cm and d == 1 then
                is_cm = true
            end
            if is_cm and d then
                local key = string.format('%04d-%02d-%02d', year, month, d)
                local h   = set[key]
                if h and h.kind ~= 'public' then
                    local line = (row - 1) * 2 + 4
                    local cs   = d < 10
                        and (col - 1) * 4 + 4
                        or  (col - 1) * 4 + 3
                    local new_base = h.kind == 'obs'
                        and 'CalendarObs' or 'CalendarBoth'
                    -- Find the mark extmark calendar.nvim placed at this cell.
                    local ems = vim.api.nvim_buf_get_extmarks(
                        buf, cal_ns, {line, cs}, {line, cs}, {details = true}
                    )
                    for _, em in ipairs(ems) do
                        local id, opts = em[1], em[4]
                        local vt = opts and opts.virt_text
                        if vt and #vt > 0 and vt[1][1] == icon then
                            -- Rebuild highlight list: replace base colour but
                            -- preserve today/current highlights (indices 2+).
                            local orig = vt[1][2]
                            local hl
                            if type(orig) == 'table' then
                                hl = { new_base }
                                for i = 2, #orig do
                                    hl[#hl + 1] = orig[i]
                                end
                            else
                                hl = new_base
                            end
                            vim.api.nvim_buf_set_extmark(
                                buf, cal_ns, line, cs, {
                                    id            = id,
                                    virt_text     = {{ icon, hl }},
                                    virt_text_pos = opts.virt_text_pos or 'overlay',
                                }
                            )
                        end
                    end
                end
            end
        end
    end
end

-- ── Patch view ──────────────────────────────────────────────────────────────

local _view = require('calendar.view')
if not _view._patched then
    _view._patched = true
    local _orig_open      = _view.open
    local _orig_highlight = _view.highlight_day
    local _buf_patched    = false

    -- Keep _cal.day in sync; recolour obs/both marks after every set_mark call.
    -- _cal.buf is -1 on the very first open (set below), so we skip silently
    -- and let _view.open handle the initial recolour explicitly.
    _view.highlight_day = function(day)
        _cal.day = day
        _orig_highlight(day)
        if _cal.buf ~= -1 and vim.api.nvim_buf_is_valid(_cal.buf) then
            recolor_obs_marks(_cal.buf, _cal.year, _cal.month)
        end
    end

    _view.open = function(y, m, d)
        _cal.year, _cal.month, _cal.day = y, m, d or _cal.day
        local b, w = _orig_open(y, m, d)
        _cal.win = w
        _cal.buf = b
        -- Explicit recolour for the initial open: _cal.buf was -1 when
        -- highlight_day ran inside _orig_open, so marks are still red.
        recolor_obs_marks(b, y, m)

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
                    local key = string.format(
                        '%04d-%02d-%02d', _cal.year, _cal.month, _cal.day
                    )
                    local h    = load_holiday_set()[key]
                    local name = '（无假期）'
                    if h then
                        name = h.kind == 'both'
                            and (h.name .. ' · ' .. h.obs_name)
                            or  h.name
                    end
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
                        local day = tonumber(vim.fn.expand('<cword>'))
                        if not day then return end
                        local key = string.format(
                            '%04d-%02d-%02d', _cal.year, _cal.month, day
                        )
                        local h = load_holiday_set()[key]
                        if h then
                            local name = h.kind == 'both'
                                and (h.name .. ' · ' .. h.obs_name)
                                or  h.name
                            show_holiday_popup(_cal.year, _cal.month, day, name)
                        end
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
