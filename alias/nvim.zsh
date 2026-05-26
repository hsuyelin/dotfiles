# nvimhelp: print all custom Neovim keymaps with descriptions.
# leader = <space>   localleader = ,
nvimhelp() {
    local bold=$'\033[1m'
    local cyan=$'\033[0;36m'
    local yellow=$'\033[0;33m'
    local dim=$'\033[2m'
    local reset=$'\033[0m'
    local sep='──────────────────────────────────────────────'

    _nh_section() { printf '\n%s  %s%s\n' "$yellow" "$1" "$reset"; }
    _nh_row()     { printf '  %s%-26s%s  %s\n' "$cyan" "$1" "$reset" "$2"; }
    _nh_note()    { printf '  %s%-26s  %s%s\n' "$dim" "" "$1" "$reset"; }

    echo ""
    printf '%sNeovim Keymaps Cheatsheet%s' "$bold" "$reset"
    printf '  %sleader = <space>   localleader = ,%s\n' "$dim" "$reset"
    echo "$sep"

    # ── Global ────────────────────────────────────────────────────────────────
    _nh_section "Global (Normal mode unless marked)"
    _nh_row "jk"               "[INSERT] exit insert mode (alias for <Esc>)"
    _nh_row "<C-h/j/k/l>"      "navigate between splits (smart-splits)"
    _nh_row "<C-f>"             "find files (Telescope)"
    _nh_row "<C-b>"             "buffer picker (Telescope)"
    _nh_row "<C-c>"             "close current buffer"
    _nh_row "{ / }"            "previous / next buffer tab"
    _nh_row "<C-[> / <C-]>"    "previous / next vim tab"
    _nh_row "<C-i>"             "jump forward in jump list"
    _nh_row "<C-e>"             "[INSERT] open emoji picker"

    # ── Folding ────────────────────────────────────────────────────────────────
    _nh_section "Folding  (treesitter-based)"
    _nh_row "<tab>"             "toggle fold under cursor  (= za)"
    _nh_row "za"                "toggle fold open / closed"
    _nh_row "zo / zc"          "open / close fold"
    _nh_row "zO / zC"          "open / close fold recursively"
    _nh_row "zR"                "open ALL folds in buffer"
    _nh_row "zM"                "close ALL folds in buffer"
    _nh_row "zj / zk"          "jump to next / previous fold"
    _nh_row "[z / ]z"          "jump to start / end of current fold"

    # ── Flash (jump / search) ─────────────────────────────────────────────────
    _nh_section "Flash  (jump / search)"
    _nh_row "r"                 "flash jump — type 2-char label to teleport cursor"
    _nh_row "R"                 "flash treesitter search — jump by treesitter node"
    _nh_row "<C-r>"             "flash treesitter — highlight entire syntax tree"

    # ── mini.move (code movement) ─────────────────────────────────────────────
    _nh_section "mini.move  (move code blocks)"
    _nh_row "<M-h/j/k/l>"      "[VISUAL] move selection left / down / up / right"
    _nh_row "<M-h/j/k/l>"      "[NORMAL] move current line left / down / up / right"

    # ── Surround ──────────────────────────────────────────────────────────────
    _nh_section "Surround  (nvim-surround)"
    _nh_row "ys{motion}{char}"  "add surrounding around motion  e.g. ysiw("
    _nh_row "yss{char}"         "add surrounding around current line"
    _nh_row "ds{char}"          "delete surrounding  e.g. ds( removes parentheses"
    _nh_row "cs{old}{new}"      "change surrounding  e.g. cs'\" swaps quotes"
    _nh_row "S{char}"           "[VISUAL] surround selection"

    # ── Marks ─────────────────────────────────────────────────────────────────
    _nh_section "Marks  (marks.nvim)"
    _nh_row "m,"                "set next available mark on current line"
    _nh_row "m;"                "toggle mark on current line"
    _nh_row "m] / m["           "jump to next / previous mark"
    _nh_row "m:"                "preview mark in floating window"
    _nh_row "dm-"               "delete all marks in current buffer"

    # ── Comments ──────────────────────────────────────────────────────────────
    _nh_section "Comments  (ts-comments)"
    _nh_row "gcc"               "toggle comment on current line"
    _nh_row "gc{motion}"        "toggle comment over motion  e.g. gcap comments paragraph"
    _nh_row "gc"                "[VISUAL] toggle comment on selection"

    # ── LSP ───────────────────────────────────────────────────────────────────
    _nh_section "LSP  (active when language server attaches)"
    _nh_row "gd"                "go to definition"
    _nh_row "gD"                "go to type definition"
    _nh_row "gr"                "find all references (Telescope)"
    _nh_row "gi"                "go to implementation"
    _nh_row "go"                "workspace symbols — search all symbols project-wide"
    _nh_row "gl"                "document symbols — outline of current file"
    _nh_row "K"                 "hover documentation popup"
    _nh_row "ca"                "code action (quick fix, refactor, etc.)"
    _nh_row "<space>rn"         "rename symbol under cursor"
    _nh_row "<space>lti"        "toggle inlay hints (type annotations)"

    # ── Diagnostics / Trouble ─────────────────────────────────────────────────
    _nh_section "Diagnostics  (<space>x…)"
    _nh_row "<space>xx"         "toggle diagnostics panel (Trouble)"
    _nh_row "<space>xf"         "buffer diagnostics only"
    _nh_row "<space>xs"         "LSP references / definitions panel"
    _nh_row "<C-S-n> / <C-S-p>" "jump to next / previous diagnostic and focus"

    # ── Git ───────────────────────────────────────────────────────────────────
    _nh_section "Git  (<space>g…)"
    _nh_row "<space>gg"         "open Neogit (full git UI)"
    _nh_row "<space>gG"         "open Lazygit in a terminal tab"
    _nh_row "<space>gs"         "stage hunk under cursor"
    _nh_row "<space>gS"         "stage entire buffer"
    _nh_row "<space>gu"         "undo last staged hunk"
    _nh_row "<space>gx"         "reset hunk under cursor (discard changes)"
    _nh_row "<space>gj / gk"    "jump to next / previous hunk"
    _nh_row "<space>gh"         "preview hunk inline"
    _nh_row "<space>gH"         "preview hunk in popup window"
    _nh_row "<space>gb"         "git blame for entire file"
    _nh_row "<space>gB"         "git blame for current line (popup)"
    _nh_row "<space>gl"         "git status in neo-tree sidebar"
    _nh_row "<space>gdd"        "diff current file against HEAD"
    _nh_row "<space>gdf"        "file commit history (DiffviewFileHistory)"
    _nh_row "<space>gdc"        "close diffview"
    _nh_row "<space>gdt"        "toggle diffview file list"

    # ── File / Explorer ───────────────────────────────────────────────────────
    _nh_section "File  (<space>f…)"
    _nh_row "<space>fw"         "save all open files"
    _nh_row "<space>fl"         "open file explorer (neo-tree)"
    _nh_row "<space>fh"         "toggle neo-tree sidebar"
    _nh_row "<space>fF"         "reveal current file in neo-tree"
    _nh_row "<space>fr"         "recent files (Telescope oldfiles)"
    _nh_row "<space>fd"         "open netrw directory browser"
    _nh_row "<space>fyy"        "copy absolute path of current file to clipboard"
    _nh_row "<space>fyr"        "copy relative path to clipboard"
    _nh_row "<space>fyn"        "copy filename only to clipboard"

    # ── Neo-tree sidebar ──────────────────────────────────────────────────────
    _nh_section "Neo-tree  (keys active inside the sidebar)"
    _nh_row "<tab>"             "open file or expand directory"
    _nh_row "l / h"            "open (expand) / close node"
    _nh_row "<space>"           "toggle node open/closed"
    _nh_row "H"                 "navigate to parent directory"
    _nh_row "c"                 "set directory as root (cd into it)"
    _nh_row "O"                 "expand all child nodes recursively"
    _nh_row "C"                 "close all child nodes"
    _nh_row "> / <"            "widen / narrow the sidebar (±5 cols, min 15)"
    _nh_row "f / /"            "fuzzy finder inside the tree"
    _nh_row "."                 "toggle hidden files"
    _nh_row "A"                 "create new file"
    _nh_row "Ctrl+A"            "create new directory"
    _nh_row "R"                 "rename node"
    _nh_row "D"                 "delete node"
    _nh_row "M"                 "move node"
    _nh_row "Y"                 "copy to clipboard"
    _nh_row "P"                 "paste from clipboard"

    # ── Buffer ────────────────────────────────────────────────────────────────
    _nh_section "Buffer  (<space>b…)"
    _nh_row "<space>bb"         "buffer picker (Telescope)"
    _nh_row "<space>bh / bl"    "previous / next buffer"
    _nh_row "<space>bH / bL"    "move buffer left / right in tab bar"
    _nh_row "<space>bo"         "close all other buffers"
    _nh_row "<space>bp"         "pin / unpin buffer"
    _nh_row "<space>bP"         "visually pick buffer by letter"
    _nh_row "<space>bn"         "new empty buffer"
    _nh_row "<space>bc"         "close current buffer"

    # ── Tabs ──────────────────────────────────────────────────────────────────
    _nh_section "Tabs  (<space>t…)"
    _nh_row "<space>tn"         "new empty tab"
    _nh_row "<space>tc"         "close current tab"
    _nh_row "<space>tt"         "tab picker (telescope-tabs)"
    _nh_row "<space>t1-9"       "jump to tab by number"

    # ── Search ────────────────────────────────────────────────────────────────
    _nh_section "Search  (<space>a…)"
    _nh_row "<space><space>"    "command palette (Telescope commands)"
    _nh_row "<space>as"         "live grep — search text across entire project"
    _nh_row "<space>al / <space>/" "grep lines in current file → open in new tab"
    _nh_row "<space>aj"         "jump list — recent cursor locations"
    _nh_row "<space>ah"         "help tags search"
    _nh_row "<space>ak"         "keymap browser"
    _nh_row "<space>at"         "TODO / FIXME / HACK list"
    _nh_row "<space>ae"         "emoji picker"
    _nh_row "<space>am"         "notification history"
    _nh_row "<space>ac"         "colorscheme switcher"
    _nh_row "<space>an"         "clear search highlight"

    # ── Debug (DAP) ───────────────────────────────────────────────────────────
    _nh_section "Debug  (<space>d…)"
    _nh_row "<space>db"         "toggle breakpoint on current line"
    _nh_row "<space>du"         "toggle DAP UI panel"
    _nh_row "<space>dc"         "start debug session or continue"
    _nh_row "<space>dn"         "step over (next line, skip into calls)"
    _nh_row "<space>di"         "step into function call"
    _nh_row "<space>do"         "step out of current function"
    _nh_row "<space>dq"         "terminate debug session"
    _nh_row "<space>dl"         "toggle REPL"
    _nh_row "<space>dL"         "clear REPL"

    # ── Project ───────────────────────────────────────────────────────────────
    _nh_section "Project & Navigation  (<space>p / z / C)"
    _nh_row "<space>pp"         "switch project (telescope-project)"
    _nh_row "<space>pP"         "reset project root directory"
    _nh_row "<space>pa"         "add current directory as project"
    _nh_row "<space>z"          "zoxide directory jump (frecency-based)"
    _nh_row "<space>Cc"         "open config files picker"

    # ── Terminal ──────────────────────────────────────────────────────────────
    _nh_section "Terminal  (split pane, bottom)"
    _nh_row "<space>!"          "toggle terminal — open if hidden, hide if visible"
    _nh_note                    "inside terminal:"
    _nh_row "<space>!"          "[TERMINAL] hide terminal (same toggle key)"
    _nh_row "jk"                "[TERMINAL] exit to normal mode (stay in window)"
    _nh_row "<C-c>"             "[TERMINAL] close terminal window entirely"

    # ── Misc ──────────────────────────────────────────────────────────────────
    _nh_section "Misc"
    _nh_row "<space>aq"         "quit all windows"
    _nh_row "<space>P"          "open pack manager (PackUpdate UI)"
    _nh_row ":PackUpdate"       "update all plugins with live progress"
    _nh_row ":PackClean"        "remove unused plugin directories"
    _nh_row ":PackCheckUpdate"  "check which plugins have updates (no download)"
    _nh_row ":PackCheckHealth"  "run health checks, show only issues"

    echo ""
    echo "$sep"
    echo ""

    unfunction _nh_section _nh_row _nh_note
}
