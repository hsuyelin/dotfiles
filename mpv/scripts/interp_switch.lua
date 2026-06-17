-- interp_switch.lua
-- Cycle through frame-interpolation presets with a single key.
-- Each preset bundles the interpolation flag, the temporal scaler (tscale)
-- and its blur value, picked to suit different content types.

local mp = require("mp")

-- Ordered list of presets; `blur` is a float so it must be set via a
-- type-aware API (set_property_native) rather than the string-based one.
local PRESETS = {
    { name = "关闭插帧", interp = false, tscale = "oversample", blur = 0.0 },
    -- Film: oversample ignores blur, keep it at 0.0.
    { name = "电影模式", interp = true, tscale = "oversample", blur = 0.0 },
    -- Anime: sphinx + mild blur stays smooth without softening line art.
    { name = "动漫模式", interp = true, tscale = "sphinx", blur = 0.65 },
    -- Ultra-smooth: bicubic with slight negative blur to counter softness.
    { name = "极致丝滑", interp = true, tscale = "bicubic", blur = -0.40 },
}

local current = 1

-- Apply a preset safely. set_property_* can fail if a value is rejected by
-- the core, so each call is guarded to avoid aborting the script on error.
local function apply_preset(preset)
    local ok = pcall(function()
        mp.set_property_bool("interpolation", preset.interp)
        mp.set_property("tscale", preset.tscale)
        mp.set_property_native("tscale-blur", preset.blur)
    end)

    if ok then
        mp.osd_message("插帧模式: " .. preset.name, 2)
    else
        mp.osd_message("插帧切换失败: " .. preset.name, 2)
    end
end

-- Advance to the next preset, wrapping around the list.
local function cycle_interpolation()
    current = current % #PRESETS + 1
    apply_preset(PRESETS[current])
end

mp.register_script_message("cycle_interp", cycle_interpolation)
