# ∂mpv 配置

> 面向 **macOS（Apple Silicon / arm64）** 调优的 mpv 播放器配置，兼顾 4K 显示器与动漫/影视观看体验；附带在线字幕、弹幕、Anime4K 超分与插帧切换等增强。
>
> English version: [README.en.md](README.en.md)

---

## ✨ 特性

| 模块 | 说明 |
|---|---|
| **渲染** | `gpu-next`（libplacebo）+ `high-quality` 高质量缩放，`deband` 抑制色带，专为 4K 面板调优 |
| **硬解** | `hwdec=auto-safe`，macOS 走 VideoToolbox，Linux 自动选 VAAPI/NVDEC |
| **字体** | 字幕/弹幕用**霞鹜文楷等宽 Medium**，统计信息也用 LXGW；界面/菜单用**思源黑体 SC Medium**（uosc 走 `osd-font`） |
| **字幕** | 暖白 `#FFF1E6` + 适度深色描边，可读性优先 |
| **OSC** | [uosc](https://github.com/tomasklaen/uosc) 现代化控制栏 + 上下文菜单，简体中文界面 |
| **弹幕** | [uosc_danmaku](https://github.com/Tony15246/uosc_danmaku)，弹弹play 弹幕源 |
| **在线字幕** | [sub-assrt](https://github.com/Sorrow446/mpv-sub-assrt) 伪射手字幕搜索 |
| **超分** | [Anime4K](https://github.com/bloc97/Anime4K) GLSL 着色器，高画质/低开销两档 |
| **插帧** | 自定义脚本一键循环：关闭 / 电影 / 动漫 / 极致丝滑 |
| **缩略图** | [thumbfast](https://github.com/po5/thumbfast) 进度条悬停预览 |
| **日志** | 输出到 `log/mpv.log`，便于排查 |

---

## 📁 目录结构

```
mpv/
├── mpv.conf                 # 主配置（渲染/窗口/字体/字幕/OSD/日志，含 [linux] profile）
├── input.conf              # 键鼠绑定
├── script-opts/            # 各脚本配置
│   ├── uosc.conf            # OSC / 界面（含弹幕按钮）
│   ├── console.conf         # 命令控制台字体（思源黑体 SC Medium）
│   ├── stats.conf           # 统计信息字体（LXGW Medium）
│   ├── uosc_danmaku.conf    # 弹幕
│   └── thumbfast.conf       # 缩略图
├── scripts/                # Lua 脚本
│   ├── interp_switch.lua    # 插帧切换（自定义）
│   ├── uosc/                # OSC 控制栏（上游，请勿手改）
│   ├── uosc_danmaku/        # 弹幕脚本（上游，请勿手改）
│   └── sub-assrt.lua / thumbfast.lua
├── shaders/                # Anime4K GLSL 着色器
├── fonts/                  # uosc 图标 / 纹理字体
└── log/                    # 运行日志（git 忽略）
```

> 第三方脚本（`uosc/`、`thumbfast.lua`、`sub-assrt.lua`、`uosc_danmaku/`）保持上游原样，方便后续升级。

---

## ⌨️ 快捷键

### 播放控制
| 按键 | 功能 |
|---|---|
| `Space` / 鼠标中键 | 播放 / 暂停 |
| `→` / `←` | 快进 / 快退 5 秒 |
| `Shift+→` / `Shift+←` | 快进 / 快退 60 秒 |
| `.` / `,` | 逐帧前进 / 后退 |
| `[` / `]` | 减速 / 加速 |
| `Backspace` | 恢复正常速度 |
| `PageUp` / `PageDown` | 下/上一章节 |
| `<` / `>` | 上/下一个文件 |

### 音量
| 按键 | 功能 |
|---|---|
| `↑` / `↓` | 音量 +5 / -5 |
| `m` | 静音切换 |

### 画面 / 窗口
| 按键 | 功能 |
|---|---|
| `Ctrl+=` / `Ctrl+-` | 放大 / 缩小 |
| `Ctrl+0` | 重置缩放 |
| `Ctrl+r` | 旋转画面（0/90/180/270） |
| `a` | 切换纵横比 |
| `f` / `Enter` / 双击左键 | 全屏切换 |
| `Esc` | 退出全屏 |
| `Ctrl+t` | 窗口置顶 |
| `Alt+z` | 切换 OSD 详细程度 |

### 字幕 / 音轨
| 按键 | 功能 |
|---|---|
| `v` | 显示 / 隐藏字幕 |
| `j` / `J` | 下/上一字幕轨 |
| `z` / `Z` | 字幕提前 / 延后 0.1s |
| `Ctrl+←` / `Ctrl+→` | 音频提前 / 延后 0.1s |
| `Alt+a` | 切换音轨 |
| `Alt+f` | 在线搜索字幕 |

### 弹幕
| 按键 | 功能 |
|---|---|
| `Ctrl+d` | 搜索弹幕 |
| `d` | 显示 / 隐藏弹幕 |
| `Alt+d` | 弹幕总开关菜单 |

### 截图 / 信息 / 菜单
| 按键 | 功能 |
|---|---|
| `s` | 截图（含字幕） |
| `S` | 截图（不含字幕/OSD） |
| `i` | 切换统计信息浮层 |
| 鼠标右键 | 上下文菜单 |

### Anime4K 超分 / 插帧
| 按键 | 功能 |
|---|---|
| `Alt+F1`~`Alt+F6` | 高画质模式 A/B/C/A+A/B+B/C+A |
| `Alt+F7`~`Alt+F12` | 低开销模式 A/B/C/A+A/B+B/C+A |
| `Alt+Del` | 清除全部着色器 |
| `n` | 循环插帧模式：关闭 → 电影 → 动漫 → 极致丝滑 |

---

## 🔤 字体依赖

| 字体 | 用途 | 安装 |
|---|---|---|
| 霞鹜文楷等宽 (LXGW WenKai Mono) | 字幕 / OSD / 弹幕 / 统计信息 | [LXGW/LxgwWenKai](https://github.com/lxgw/LxgwWenKai) |
| 思源黑体 SC Medium (Source Han Sans SC) | uosc 界面 / 菜单（`osd-font`） | `brew install --cask font-source-han-sans-vf`（再实例化出 Medium，见下） |

> 思源黑体官方仅提供可变字体（VF），libass 无法直接选中 Medium 字重，因此从 VF 实例化出静态 `Source Han Sans SC Medium` 安装到 `~/Library/Fonts`。若需重建：
> ```bash
> python3 -c "from fontTools.ttLib import TTCollection; from fontTools.varLib.instancer import instantiateVariableFont as I; \
> c=TTCollection('~/Library/Fonts/SourceHanSans-VF.otf.ttc'); f=c.fonts[2]; I(f,{'wght':500},inplace=True); f.save('out.otf')"
> ```

---

## 🐧 Linux（实验性）

基础配置已通过 `auto` 检测做到跨平台。在 Linux 上额外应用：

```bash
mpv --profile=linux <file>
```

如需指定硬解：NVIDIA 用 `hwdec=nvdec-copy`，Intel/AMD 用 `hwdec=vaapi`（见 `mpv.conf` 末尾 `[linux]` profile）。

---

## 🙏 致谢

[mpv](https://mpv.io) · [uosc](https://github.com/tomasklaen/uosc) · [uosc_danmaku](https://github.com/Tony15246/uosc_danmaku) · [thumbfast](https://github.com/po5/thumbfast) · [Anime4K](https://github.com/bloc97/Anime4K) · [mpv-sub-assrt](https://github.com/Sorrow446/mpv-sub-assrt)
