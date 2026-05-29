# Shared rendering engine for *help functions.
# Requires: jq  (brew install jq)
#
# Public API:
#   _help_usage  <cmd>
#   _help_list   <json_file>
#   _help_show   <json_file> [--module <id>] [--lang <en|zh>]

_help_require_jq() {
    command -v jq >/dev/null 2>&1 && return 0
    printf '\033[0;31merror:\033[0m jq is required — install with: brew install jq\n' >&2
    return 1
}

_help_usage() {
    local cmd="$1"
    local b=$'\033[1m' c=$'\033[0;36m' d=$'\033[2m' r=$'\033[0m'
    printf '\n%sUsage:%s %s%s%s <command> [options]\n\n' "$b" "$r" "$b" "$cmd" "$r"
    printf '%sCommands:%s\n' "$b" "$r"
    printf '  %s%-32s%s %s\n' "$c" "list"                   "$r" "list all modules"
    printf '  %s%-32s%s %s\n' "$c" "show"                   "$r" "show all (default)"
    printf '  %s%-32s%s %s\n' "$c" "show --lang zh"         "$r" "show in Chinese"
    printf '  %s%-32s%s %s\n' "$c" "show --module <name>"   "$r" "show one module"
    printf '  %s%-32s%s %s\n' "$c" "--help, -h"             "$r" "show this message"
    printf '\n%sExamples:%s\n' "$b" "$r"
    printf '  %s list\n'                          "$cmd"
    printf '  %s show\n'                          "$cmd"
    printf '  %s show --lang zh\n'                "$cmd"
    printf '  %s show --module lsp\n'             "$cmd"
    printf '  %s show --module lsp --lang zh\n\n' "$cmd"
}

_help_list() {
    local json_file="$1"; shift
    _help_require_jq || return 1

    local lang="en"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --lang) lang="$2"; shift 2 ;;
            *)      shift ;;
        esac
    done

    local b=$'\033[1m' c=$'\033[0;36m' r=$'\033[0m'

    local term_w
    term_w=$(tput cols 2>/dev/null || echo 100)
    local id_col=20
    local title_col=$(( term_w - id_col - 7 ))
    (( title_col < 30 )) && title_col=30

    local kb dc
    printf -v kb '%*s' $(( id_col    + 2 )) ''; kb=${kb// /─}
    printf -v dc '%*s' $(( title_col + 2 )) ''; dc=${dc// /─}

    local header_id header_title
    if [[ "$lang" == "zh" ]]; then
        header_id="模块"; header_title="说明"
    else
        header_id="Module"; header_title="Description"
    fi

    echo ""
    printf '┌%s┬%s┐\n' "$kb" "$dc"

    command jq -r --arg lang "$lang" \
        '.modules[] | [.id, (.title[$lang] // .title.en)] | @tsv' "$json_file" \
        | python3 -c "
import sys, unicodedata

id_col    = $id_col
title_col = $title_col
B = '\033[1m'; C = '\033[0;36m'; R = '\033[0m'
sep = '├' + '─' * (id_col + 2) + '┼' + '─' * (title_col + 2) + '┤'

def vw(s):
    return sum(2 if unicodedata.east_asian_width(c) in ('W','F') else 1 for c in s)

def trunc(s, w):
    cur, buf = 0, []
    for ch in s:
        cw = 2 if unicodedata.east_asian_width(ch) in ('W','F') else 1
        if cur + cw > w - 1: buf.append('…'); break
        buf.append(ch); cur += cw
    return ''.join(buf)

def pad(s, w):
    return s + ' ' * max(0, w - vw(s))

hdr_id, hdr_title = sys.argv[1], sys.argv[2]
print(f'│ {B}{pad(hdr_id, id_col)}{R} │ {pad(hdr_title, title_col)} │')
print(sep)

rows = []
for line in sys.stdin:
    parts = line.rstrip('\n').split('\t', 1)
    mid  = parts[0]
    desc = trunc(parts[1] if len(parts) > 1 else '', title_col)
    rows.append(f'│ {C}{pad(mid, id_col)}{R} │ {pad(desc, title_col)} │')

for i, row in enumerate(rows):
    print(row)
    if i < len(rows) - 1:
        print(sep)
" "$header_id" "$header_title"

    printf '└%s┴%s┘\n' "$kb" "$dc"
    echo ""
}

_help_show() {
    local json_file="$1"; shift
    _help_require_jq || return 1

    local lang="en" module=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --lang)   lang="$2";   shift 2 ;;
            --module) module="$2"; shift 2 ;;
            *)        shift ;;
        esac
    done

    local b=$'\033[1m' y=$'\033[0;33m' d=$'\033[2m' r=$'\033[0m'

    local term_w
    term_w=$(tput cols 2>/dev/null || echo 100)
    local key_col=26
    local desc_col=$(( term_w - key_col - 7 ))
    (( desc_col < 28 )) && desc_col=28

    _hrule() {
        local L="$1" M="$2" R="$3"
        local kb dc
        printf -v kb '%*s' $(( key_col  + 2 )) ''; kb=${kb// /─}
        printf -v dc '%*s' $(( desc_col + 2 )) ''; dc=${dc// /─}
        printf '%s%s%s%s%s\n' "$L" "$kb" "$M" "$dc" "$R"
    }

    _sep_line() {
        local title="$1"
        local table_w=$(( key_col + desc_col + 7 ))
        local prefix="  ── "
        local title_vw
        title_vw=$(python3 -c "
import sys, unicodedata
s = sys.argv[1]
print(sum(2 if unicodedata.east_asian_width(c) in ('W','F') else 1 for c in s))
" "$title")
        local avail=$(( table_w - ${#prefix} - title_vw - 2 ))
        (( avail < 2 )) && avail=2
        local bar; printf -v bar '%*s' "$avail" ''; bar=${bar// /─}
        printf '%s%s%s %s\n' "$y" "${prefix}${title}" "$r" "$bar"
    }

    local title subtitle
    title=$(   command jq -r ".title.${lang}    // .title.en"             "$json_file")
    subtitle=$(command jq -r ".subtitle.${lang} // .subtitle.en // empty" "$json_file")

    echo ""
    if [[ -n "$subtitle" ]]; then
        printf '%s%s%s  %s%s%s\n' "$b" "$title" "$r" "$d" "$subtitle" "$r"
    else
        printf '%s%s%s\n' "$b" "$title" "$r"
    fi

    local jq_filter
    if [[ -n "$module" ]]; then
        jq_filter=".modules[] | select(.id == \"$module\")"
    else
        jq_filter=".modules[]"
    fi

    local found=0
    while IFS= read -r mod; do
        found=1
        local mod_title
        mod_title=$(printf '%s' "$mod" | command jq -r ".title.${lang} // .title.en")

        echo ""
        _sep_line "$mod_title"
        _hrule "┌" "┬" "┐"

        printf '%s' "$mod" \
            | command jq -c '.entries' \
            | python3 "${XDG_CONFIG_HOME}/alias/help_render.py" \
                "$lang" "$key_col" "$desc_col"

        _hrule "└" "┴" "┘"
    done < <(command jq -c "$jq_filter" "$json_file" 2>/dev/null)

    if (( found == 0 )) && [[ -n "$module" ]]; then
        local caller_name="${funcstack[2]:-help}"
        printf '\n  \033[0;31merror:\033[0m module "%s" not found — run: %s list\n\n' \
            "$module" "$caller_name"
        return 1
    fi

    echo ""
    unfunction _hrule _sep_line 2>/dev/null
}
