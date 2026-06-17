# mpv configuration

> An mpv player setup tuned for **macOS (Apple Silicon / arm64)**, optimized for 4K displays and anime/film viewing, with online subtitles, danmaku (bullet comments), Anime4K upscaling and an interpolation toggle.
>
> 中文版： [README.md](README.md)

---

## ✨ Features

| Area | Details |
|---|---|
| **Renderer** | `gpu-next` (libplacebo) + `high-quality` scalers, `deband` for banding, tuned for 4K panels |
| **HW decode** | `hwdec=auto-safe` — VideoToolbox on macOS, VAAPI/NVDEC on Linux |
| **Fonts** | Media info / subtitles / danmaku use **LXGW WenKai Mono Medium**; menus use **Source Han Sans SC Medium** (full CJK) |
| **Subtitles** | Warm-white `#FFF1E6` text + moderate dark outline, matching the orange theme, readability first |
| **OSC** | [ModernZ](https://github.com/Samillion/ModernZ) modern control bar, Simplified Chinese UI |
| **Danmaku** | [uosc_danmaku](https://github.com/Tony15246/uosc_danmaku), DanDanPlay source |
| **Online subs** | [sub-assrt](https://github.com/Sorrow446/mpv-sub-assrt) subtitle search |
| **Upscaling** | [Anime4K](https://github.com/bloc97/Anime4K) GLSL shaders, HQ and fast tiers |
| **Interpolation** | Custom script, one-key cycle: Off / Film / Anime / Ultra-smooth |
| **Thumbnails** | [thumbfast](https://github.com/po5/thumbfast) seekbar hover preview |
| **Logging** | Written to `log/mpv.log` for troubleshooting |

---

## 📁 Layout

```
mpv/
├── mpv.conf                 # main config (render/window/fonts/subs/OSD/log, incl. [linux] profile)
├── input.conf              # key & mouse bindings
├── script-opts/            # per-script options
│   ├── console.conf         # menu font (Source Han Sans SC Medium)
│   ├── stats.conf           # stats overlay font (LXGW Medium)
│   ├── modernz.conf         # OSC control bar
│   ├── modernz-locale.json  # OSC localization (zh strings completed)
│   ├── uosc_danmaku.conf    # danmaku
│   └── thumbfast.conf       # thumbnails
├── scripts/                # Lua scripts
│   ├── interp_switch.lua    # interpolation toggle (custom)
│   ├── modernz.lua / sub-assrt.lua / thumbfast.lua
│   └── uosc_danmaku/        # danmaku script (upstream, don't hand-edit)
├── shaders/                # Anime4K GLSL shaders
├── fonts/                  # OSC icon font
└── log/                    # runtime logs (git-ignored)
```

> Third-party scripts (`modernz.lua`, `thumbfast.lua`, `sub-assrt.lua`, `uosc_danmaku/`) are kept verbatim from upstream for easy updates.

---

## ⌨️ Keybindings

### Playback
| Key | Action |
|---|---|
| `Space` / middle click | Play / pause |
| `→` / `←` | Seek ±5s |
| `Shift+→` / `Shift+←` | Seek ±60s |
| `.` / `,` | Step frame forward / back |
| `[` / `]` | Slower / faster |
| `Backspace` | Reset speed |
| `PageUp` / `PageDown` | Next / previous chapter |
| `<` / `>` | Previous / next file |

### Volume
| Key | Action |
|---|---|
| `↑` / `↓` | Volume +5 / -5 |
| `m` | Toggle mute |

### Picture / window
| Key | Action |
|---|---|
| `Ctrl+=` / `Ctrl+-` | Zoom in / out |
| `Ctrl+0` | Reset zoom |
| `Ctrl+r` | Rotate (0/90/180/270) |
| `a` | Cycle aspect ratio |
| `f` / `Enter` / double click | Toggle fullscreen |
| `Esc` | Leave fullscreen |
| `Ctrl+t` | Keep window on top |
| `Alt+z` | Cycle OSD verbosity |

### Subtitle / audio
| Key | Action |
|---|---|
| `v` | Show / hide subtitles |
| `j` / `J` | Next / previous subtitle track |
| `z` / `Z` | Subtitle earlier / later 0.1s |
| `Ctrl+←` / `Ctrl+→` | Audio earlier / later 0.1s |
| `Alt+a` | Cycle audio track |
| `Alt+f` | Search subtitles online |

### Danmaku
| Key | Action |
|---|---|
| `Ctrl+d` | Search danmaku |
| `d` | Toggle danmaku |
| `Alt+d` | Danmaku master switch |

### Screenshot / info / menu
| Key | Action |
|---|---|
| `s` | Screenshot (with subs) |
| `S` | Screenshot (no subs/OSD) |
| `i` | Toggle statistics overlay |
| Right click | Context menu |

### Anime4K / interpolation
| Key | Action |
|---|---|
| `Alt+F1`–`Alt+F6` | HQ modes A/B/C/A+A/B+B/C+A |
| `Alt+F7`–`Alt+F12` | Fast modes A/B/C/A+A/B+B/C+A |
| `Alt+Del` | Clear all shaders |
| `n` | Cycle interpolation: Off → Film → Anime → Ultra-smooth |

---

## 🔤 Font dependencies

| Font | Used for | Install |
|---|---|---|
| LXGW WenKai Mono | Subtitles / OSD / danmaku / stats | [LXGW/LxgwWenKai](https://github.com/lxgw/LxgwWenKai) |
| Source Han Sans SC Medium | Menus | `brew install --cask font-source-han-sans-vf` (then instance Medium, see below) |

> Source Han Sans ships only as a variable font (VF); libass cannot select the Medium weight directly, so a static `Source Han Sans SC Medium` is instanced from the VF into `~/Library/Fonts`. To rebuild:
> ```bash
> python3 -c "from fontTools.ttLib import TTCollection; from fontTools.varLib.instancer import instantiateVariableFont as I; \
> c=TTCollection('~/Library/Fonts/SourceHanSans-VF.otf.ttc'); f=c.fonts[2]; I(f,{'wght':500},inplace=True); f.save('out.otf')"
> ```

---

## 🐧 Linux (experimental)

The base config is cross-platform thanks to `auto` detection. On Linux, apply the extra profile:

```bash
mpv --profile=linux <file>
```

For explicit HW decode: NVIDIA → `hwdec=nvdec-copy`, Intel/AMD → `hwdec=vaapi` (see the `[linux]` profile at the end of `mpv.conf`).

---

## 🙏 Credits

[mpv](https://mpv.io) · [ModernZ](https://github.com/Samillion/ModernZ) · [uosc_danmaku](https://github.com/Tony15246/uosc_danmaku) · [thumbfast](https://github.com/po5/thumbfast) · [Anime4K](https://github.com/bloc97/Anime4K) · [mpv-sub-assrt](https://github.com/Sorrow446/mpv-sub-assrt)
