-- interp_switch.lua
-- Cycle through frame-interpolation presets with a single key.
-- Each preset bundles the interpolation flag, the temporal scaler (tscale)
-- and its blur value, picked to suit different content types.

local mp = require("mp")
local options = require("mp.options")

-- User options (script-opts/interp_switch.conf):
--   language: "auto" | "en" | "zh"  (auto picks zh when $LANG looks Chinese)
local opts = { language = "auto" }
options.read_options(opts, "interp_switch")

-- Ordered presets. `id` is a stable key used to look up localized labels;
-- `blur` is a float so it must be set via a type-aware API.
local PRESETS = {
    { id = "off",    interp = false, tscale = "oversample", blur = 0.0 },
    -- Film: oversample ignores blur, keep it at 0.0.
    { id = "film",   interp = true,  tscale = "oversample", blur = 0.0 },
    -- Anime: sphinx + mild blur stays smooth without softening line art.
    { id = "anime",  interp = true,  tscale = "sphinx",     blur = 0.65 },
    -- Ultra-smooth: bicubic with slight negative blur to counter softness.
    { id = "smooth", interp = true,  tscale = "bicubic",    blur = -0.40 },
}

-- Localized strings. Add a new language by appending another table here.
local TEXTS = {
    en = {
        prefix = "Interpolation: ",
        fail   = "Interpolation switch failed: ",
        names  = {
            off    = "Off",
            film   = "Film",
            anime  = "Anime",
            smooth = "Ultra-smooth",
        },
    },
    zh = {
        prefix = "插帧模式: ",
        fail   = "插帧切换失败: ",
        names  = {
            off    = "关闭插帧",
            film   = "电影模式",
            anime  = "动漫模式",
            smooth = "极致丝滑",
        },
    },
}

-- Resolve the active language: explicit option wins, otherwise sniff $LANG.
local function resolve_language()
    if TEXTS[opts.language] then
        return opts.language
    end
    local env = os.getenv("LANG") or os.getenv("LC_ALL") or ""
    if env:lower():find("zh") then
        return "zh"
    end
    return "en"
end

local texts = TEXTS[resolve_language()]
local current = 1

-- Apply a preset safely. set_property_* can fail if a value is rejected by
-- the core, so each call is guarded to avoid aborting the script on error.
local function apply_preset(preset)
    local label = texts.names[preset.id] or preset.id
    local ok = pcall(function()
        mp.set_property_bool("interpolation", preset.interp)
        mp.set_property("tscale", preset.tscale)
        mp.set_property_native("tscale-blur", preset.blur)
    end)

    if ok then
        mp.osd_message(texts.prefix .. label, 2)
    else
        mp.osd_message(texts.fail .. label, 2)
    end
end

-- Advance to the next preset, wrapping around the list.
local function cycle_interpolation()
    current = current % #PRESETS + 1
    apply_preset(PRESETS[current])
end

mp.register_script_message("cycle_interp", cycle_interpolation)
