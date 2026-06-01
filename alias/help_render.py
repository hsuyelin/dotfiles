#!/usr/bin/env python3
"""CJK-aware table row renderer for help_lib.zsh.
stdin : JSON array of entry objects
argv  : <lang> <key_col> <desc_col>
"""
import json, sys, unicodedata

lang     = sys.argv[1]
key_col  = int(sys.argv[2])
desc_col = int(sys.argv[3])

C = '\033[0;36m'   # cyan (key)
R = '\033[0m'      # reset
D = '\033[2m'      # dim  (note)


def vw(s: str) -> int:
    """Return visual (terminal column) width of s."""
    return sum(
        2 if unicodedata.east_asian_width(c) in ('W', 'F') else 1
        for c in s
    )


def trunc(s: str, max_w: int) -> str:
    """Truncate s so vw(result) <= max_w, appending '…' if cut."""
    cur, buf = 0, []
    for ch in s:
        cw = 2 if unicodedata.east_asian_width(ch) in ('W', 'F') else 1
        if cur + cw > max_w - 1:
            buf.append('…')
            break
        buf.append(ch)
        cur += cw
    return ''.join(buf)


def pad(s: str, w: int) -> str:
    """Right-pad s with spaces until vw(result) == w."""
    return s + ' ' * max(0, w - vw(s))


sep_row  = '├' + '─' * (key_col + 2) + '┼' + '─' * (desc_col + 2) + '┤'
sep_full = '├' + '─' * (key_col + desc_col + 5) + '┤'

rendered = []
for entry in json.load(sys.stdin):
    t = entry.get('type', '')
    if t == 'row':
        key  = trunc(entry.get('key', ''), key_col)
        desc = trunc(entry.get(lang, entry.get('en', '')), desc_col)
        rendered.append(('row', f'│ {C}{pad(key, key_col)}{R} │ {pad(desc, desc_col)} │'))
    elif t == 'note':
        note_w = key_col + desc_col + 1
        note   = trunc(entry.get(lang, entry.get('en', '')), note_w)
        rendered.append(('note', f'│ {D}· {pad(note, note_w)}{R} │'))

for i, (typ, line) in enumerate(rendered):
    print(line)
    if i < len(rendered) - 1:
        next_typ = rendered[i + 1][0]
        print(sep_full if (typ == 'note' or next_typ == 'note') else sep_row)
