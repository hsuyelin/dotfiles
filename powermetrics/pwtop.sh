#!/usr/bin/env bash

# pwtop — energy-sorted process monitor with Catppuccin Mocha styling.
# Wraps powermetrics to produce a clean, colorized ranked table.
#
# Usage: pwtop [-i SECONDS] [-n COUNT] [--dry-run] [--help]

# ── Catppuccin Mocha palette ──────────────────────────────────────────────────
_C_MAUVE='\033[38;2;203;166;247m'     # #cba6f7
_C_RED='\033[38;2;243;139;168m'       # #f38ba8
_C_PEACH='\033[38;2;250;179;135m'     # #fab387
_C_YELLOW='\033[38;2;249;226;175m'    # #f9e2af
_C_GREEN='\033[38;2;166;227;161m'     # #a6e3a1
_C_LAVENDER='\033[38;2;180;190;254m'  # #b4befe
_C_TEXT='\033[38;2;205;214;244m'      # #cdd6f4
_C_SUBTEXT='\033[38;2;166;173;200m'   # #a6adc8
_C_OVERLAY='\033[38;2;108;112;134m'   # #6c7086
_C_SURFACE='\033[38;2;88;91;112m'     # #585b70
_C_BOLD='\033[1m'
_C_RESET='\033[0m'

# ── Defaults ──────────────────────────────────────────────────────────────────
_INTERVAL=3
_TOP_N=15
_DRY_RUN=0
_FRAMES=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

# ── Helpers ───────────────────────────────────────────────────────────────────
_usage() {
    printf '%bpwtop%b — energy-sorted process monitor\n\n' "$_C_BOLD" "$_C_RESET"
    printf 'Usage: pwtop [options]\n\n'
    printf '  %-24s %s\n' '-i, --interval N' "sample duration in seconds (default: $_INTERVAL)"
    printf '  %-24s %s\n' '-n, --top N'      "processes to display    (default: $_TOP_N)"
    printf '  %-24s %s\n' '    --dry-run'    "print a mock table without sampling"
    printf '  %-24s %s\n' '-h, --help'       "show this help"
}

_parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -i|--interval) _INTERVAL="$2"; shift 2 ;;
            -n|--top)      _TOP_N="$2";    shift 2 ;;
            --dry-run)     _DRY_RUN=1;     shift   ;;
            -h|--help)     _usage; exit 0 ;;
            *) printf 'Unknown option: %s\n' "$1" >&2; _usage >&2; exit 1 ;;
        esac
    done
}

_ensure_sudo() {
    [[ $EUID -eq 0 ]] && return
    sudo -v 2>/dev/null || {
        printf '%berror:%b sudo is required for powermetrics\n' "$_C_RED" "$_C_RESET" >&2
        exit 1
    }
}

_spin() {
    local pid="$1" label="$2" i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf '\r  %b%s%b  %b%s%b   ' \
            "$_C_MAUVE" "${_FRAMES[$((i % ${#_FRAMES[@]}))]}" "$_C_RESET" \
            "$_C_SUBTEXT" "$label" "$_C_RESET"
        sleep 0.08
        i=$(( i + 1 ))
    done
    printf '\r%70s\r' ''
}

_sample() {
    local outfile="$1"
    sudo powermetrics \
        --samplers tasks \
        --show-process-energy \
        -n 1 -i "$(( _INTERVAL * 1000 ))" \
        2>/dev/null | tee "$outfile" > /dev/null &
    local pm_pid=$!
    _spin "$pm_pid" "Sampling energy usage (${_INTERVAL}s)..."
    wait "$pm_pid"
}

# Parse powermetrics output → tab-delimited "energy<TAB>pid<TAB>name", sorted desc.
# Handles both "Energy Impact" and "Power (mW)" column labels across macOS versions.
_parse() {
    awk '
        /^Name[[:space:]]/ && (/Energy Impact/ || /Power \(mW\)/) {
            pid_col = index($0, "PID")
            e_col   = (index($0, "Energy Impact")) \
                        ? index($0, "Energy Impact") \
                        : index($0, "Power (mW)")
            in_sec  = 1; blank = 0
            next
        }
        in_sec && /^\*\*\*/ { in_sec = 0; next }
        in_sec && /^$/ { if (blank) in_sec = 0; blank = 1; next }
        in_sec { blank = 0 }
        in_sec && pid_col > 0 && e_col > 0 && /^[A-Za-z0-9\.]/ {
            name = substr($0, 1, pid_col - 1)
            sub(/[[:space:]]+$/, "", name)
            pid_raw = substr($0, pid_col, e_col - pid_col)
            gsub(/[[:space:]]/, "", pid_raw)
            split(substr($0, e_col), ef)
            energy = ef[1] + 0
            if (energy > 0 && name != "")
                printf "%.2f\t%s\t%s\n", energy, pid_raw, name
        }
    ' "$1" | sort -t$'\t' -k1 -rn
}

_mock_data() {
    printf '350.20\t125\tWindowServer\n'
    printf '142.80\t98312\tcom.apple.WebKit.GPU\n'
    printf '89.50\t73421\tGoogle Chrome Helper\n'
    printf '51.30\t1024\tSpotlight\n'
    printf '22.10\t512\tcoreaudiod\n'
    printf '8.40\t201\tkernel_task\n'
    printf '3.20\t890\tlogd\n'
}

_energy_color() {
    local val="${1%%.*}"  # integer part for comparison
    if   [[ $val -ge 100 ]]; then printf '%s' "$_C_RED"
    elif [[ $val -ge 50  ]]; then printf '%s' "$_C_PEACH"
    elif [[ $val -ge 20  ]]; then printf '%s' "$_C_YELLOW"
    elif [[ $val -ge 5   ]]; then printf '%s' "$_C_GREEN"
    else                          printf '%s' "$_C_SUBTEXT"
    fi
}

_render() {
    local data="$1" label="$2"
    local R=3 N=36 P=8 E=14
    local width=$(( R + 2 + N + 2 + P + 2 + E + 2 ))
    local sep
    sep=$(printf '%*s' "$width" '' | tr ' ' '─')

    printf '\n'
    printf '  %b%bEnergy Process Monitor%b  %b%s%b\n' \
        "$_C_BOLD" "$_C_LAVENDER" "$_C_RESET" "$_C_SUBTEXT" "$label" "$_C_RESET"
    printf '  %b%s%b\n\n' "$_C_SURFACE" "$sep" "$_C_RESET"

    printf '  %b%-*s  %-*s  %*s  %*s%b\n' \
        "$_C_OVERLAY" \
        $R '#'  $N 'PROCESS'  $P 'PID'  $E 'ENERGY IMPACT' \
        "$_C_RESET"
    printf '  %b%s%b\n' "$_C_SURFACE" "$sep" "$_C_RESET"

    local rank=1
    while IFS=$'\t' read -r energy pid name; do
        [[ $rank -gt $_TOP_N ]] && break
        local col
        col=$(_energy_color "$energy")
        printf '  %b%-*d%b  %b%-*s%b  %b%*s%b  %b%*s%b\n' \
            "$_C_SUBTEXT" $R  "$rank"   "$_C_RESET" \
            "$_C_TEXT"    $N  "$name"   "$_C_RESET" \
            "$_C_OVERLAY" $P  "$pid"    "$_C_RESET" \
            "$col"        $E  "$energy" "$_C_RESET"
        rank=$(( rank + 1 ))
    done <<< "$data"

    printf '  %b%s%b\n\n' "$_C_SURFACE" "$sep" "$_C_RESET"
}

main() {
    _parse_args "$@"

    if [[ $_DRY_RUN -eq 1 ]]; then
        _render "$(_mock_data)" "dry-run"
        exit 0
    fi

    _ensure_sudo

    local tmp
    tmp=$(mktemp)
    trap 'rm -f "$tmp"' EXIT

    _sample "$tmp"

    local data
    data=$(_parse "$tmp")

    if [[ -z "$data" ]]; then
        printf '%bwarn:%b no energy data found — try increasing the sample interval\n' \
            "$_C_YELLOW" "$_C_RESET" >&2
        exit 1
    fi

    _render "$data" "${_INTERVAL}s sample"
}

main "$@"
