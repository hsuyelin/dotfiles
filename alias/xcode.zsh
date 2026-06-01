# ── Xcode build helpers ───────────────────────────────────────────────────────
# xclean / xbuild / xarchive / xinstall / xhelp
#
# --workspace is optional: omit for pure Swift Package Manager projects.
# --scheme and --configuration are required for build commands.

# ---------------------------------------------------------------------------
# Logging (Cargo-style: right-aligned bold verb + message)
# ---------------------------------------------------------------------------

_xlog()  { printf '\033[1;32m%12s\033[0m  %s\n' "$1" "$2"; }
_xwarn() { printf '\033[1;33m%12s\033[0m  %s\n' "$1" "$2"; }
_xerr()  { printf '\033[1;31m%12s\033[0m  %s\n' "error" "$1" >&2; }
_xhint() { printf '\033[2m%14s  %s\033[0m\n' "" "$1" >&2; }

# ---------------------------------------------------------------------------
# Dependency check — call at the top of every public function.
# Verifies xcodebuild (Xcode) and xcbeautify (brew) are available.
# ---------------------------------------------------------------------------

_xcode_require() {
    local missing=0

    if ! command -v xcodebuild >/dev/null 2>&1; then
        _xerr "xcodebuild not found"
        _xhint "Install Xcode from the App Store or run: xcode-select --install"
        missing=1
    fi

    if ! command -v xcbeautify >/dev/null 2>&1; then
        _xerr "xcbeautify not found"
        _xhint "Install with: brew install xcbeautify"
        missing=1
    fi

    return "$missing"
}

# ---------------------------------------------------------------------------
# Generic y/N prompt with timeout.
# Usage: _xcode_ask <prompt> [timeout_secs]   (default timeout: 10s)
# Returns 0 on y/Y, 1 on n/N or timeout.
# ---------------------------------------------------------------------------

_xcode_ask() {
    local reply timeout="${2:-10}"
    printf '\n\033[1m%s\033[0m  \033[2m[y/N]  (%ss, default N)\033[0m ' "$1" "$timeout"
    if ! IFS= read -r -t "$timeout" reply 2>/dev/null; then
        printf 'N\n'
        return 1
    fi
    [[ "$reply" == [yY] ]]
}

# ---------------------------------------------------------------------------
# Shared argument parser (sets workspace / scheme / configuration in caller)
# ---------------------------------------------------------------------------

_xcode_parse_args() {
    workspace=""
    scheme=""
    configuration=""

    while [ $# -gt 0 ]; do
        case "$1" in
            --workspace)     workspace="$2";     shift 2 ;;
            --scheme)        scheme="$2";        shift 2 ;;
            --configuration) configuration="$2"; shift 2 ;;
            *)
                printf 'Unknown option: %s\n' "$1" >&2
                return 1
                ;;
        esac
    done

    [ -z "$scheme" ]        && printf 'Missing required option: --scheme\n'        >&2 && return 1
    [ -z "$configuration" ] && printf 'Missing required option: --configuration\n' >&2 && return 1

    return 0
}

# ---------------------------------------------------------------------------
# xclean
# ---------------------------------------------------------------------------

xclean() {
    _xcode_require || return 1
    local workspace="" scheme="" configuration=""

    _xcode_parse_args "$@" || {
        printf 'Usage: xclean [--workspace <name>] --scheme <name>'
        printf ' --configuration <name>\n'
        return 1
    }

    local cmd=(xcodebuild)
    [ -n "$workspace" ] && cmd+=(-workspace "${workspace}.xcworkspace")
    cmd+=(-scheme "$scheme" -sdk iphoneos -configuration "$configuration" clean)

    "${cmd[@]}" | xcbeautify
}

# ---------------------------------------------------------------------------
# xbuild
# ---------------------------------------------------------------------------

xbuild() {
    _xcode_require || return 1
    local workspace="" scheme="" configuration=""

    _xcode_parse_args "$@" || {
        printf 'Usage: xbuild [--workspace <name>] --scheme <name>'
        printf ' --configuration <name>\n'
        return 1
    }

    local _xt_sdk="iphoneos" _xt_dest="" _xt_type="" _xt_id="" _xt_label=""
    if _xcode_ask "Select target device/simulator?"; then
        _xcode_select_target
        local _rc=$?
        (( _rc == 2 )) && return 0
        (( _rc != 0 )) && return 1
    fi

    if _xcode_ask "Clean before building?"; then
        _xlog "Cleaning" "${scheme} (${configuration} | ${_xt_sdk})"
        local clean_cmd=(xcodebuild)
        [ -n "$workspace" ] && clean_cmd+=(-workspace "${workspace}.xcworkspace")
        clean_cmd+=(-scheme "$scheme" -sdk "$_xt_sdk" -configuration "$configuration" clean)
        "${clean_cmd[@]}" | xcbeautify
    fi

    _xlog "Building" "${scheme} (${configuration} | ${_xt_sdk})"
    local cmd=(xcodebuild)
    [ -n "$workspace" ] && cmd+=(-workspace "${workspace}.xcworkspace")
    cmd+=(-scheme "$scheme" -sdk "$_xt_sdk" -configuration "$configuration")
    [ -n "$_xt_dest" ] && cmd+=(-destination "$_xt_dest")
    cmd+=(build)
    "${cmd[@]}" | xcbeautify
}

# ---------------------------------------------------------------------------
# xarchive
# ---------------------------------------------------------------------------

xarchive() {
    _xcode_require || return 1
    local workspace="" scheme="" configuration="" archive_path=""

    while [ $# -gt 0 ]; do
        case "$1" in
            --workspace)     workspace="$2";     shift 2 ;;
            --scheme)        scheme="$2";        shift 2 ;;
            --configuration) configuration="$2"; shift 2 ;;
            --archive-path)  archive_path="$2";  shift 2 ;;
            *)
                printf 'Unknown option: %s\n' "$1" >&2
                printf 'Usage: xarchive [--workspace <name>] --scheme <name>'
                printf ' --configuration <name> --archive-path <path>\n'
                return 1
                ;;
        esac
    done

    [ -z "$scheme" ]        && printf 'Missing required option: --scheme\n'        >&2 && return 1
    [ -z "$configuration" ] && printf 'Missing required option: --configuration\n' >&2 && return 1
    [ -z "$archive_path" ]  && printf 'Missing required option: --archive-path\n'  >&2 && return 1

    if _xcode_ask "Clean before building?"; then
        _xlog "Cleaning" "${scheme} (${configuration})"
        local clean_cmd=(xcodebuild)
        [ -n "$workspace" ] && clean_cmd+=(-workspace "${workspace}.xcworkspace")
        clean_cmd+=(-scheme "$scheme" -sdk iphoneos -configuration "$configuration" clean)
        "${clean_cmd[@]}" | xcbeautify
    fi

    local cmd=(xcodebuild)
    [ -n "$workspace" ] && cmd+=(-workspace "${workspace}.xcworkspace")
    cmd+=(-scheme "$scheme" -sdk iphoneos -configuration "$configuration"
          archive -archivePath "$archive_path")

    "${cmd[@]}" | xcbeautify
}

# ---------------------------------------------------------------------------
# _xcode_menu <item1> <item2> ...
# Arrow-key picker. Sets _XCODE_SELECTED (1-based) on confirm.
# Returns 0 on confirm, 1 on cancel (q/Q).
# ---------------------------------------------------------------------------

_xcode_menu() {
    local -a items=("$@")
    local total=${#items[@]}
    local sel=0
    local i

    # Find first selectable item (skip SEPARATOR: headers)
    for (( i = 1; i <= total; i++ )); do
        [[ "${items[$i]}" != SEPARATOR:* ]] && { sel=$i; break; }
    done
    [ "$sel" -eq 0 ] && return 1

    _xmenu_render() {
        local j
        for (( j = 1; j <= total; j++ )); do
            printf '\033[2K'
            if [[ "${items[$j]}" == SEPARATOR:* ]]; then
                printf '  \033[2;33m%s\033[0m\n' "${items[$j]#SEPARATOR:}"
            elif (( j == sel )); then
                printf '  \033[1;36m▶  %s\033[0m\n' "${items[$j]}"
            else
                printf '  \033[2m   %s\033[0m\n' "${items[$j]}"
            fi
        done
    }

    _xmenu_clear() {
        printf '\033[%dA' "$total"
        local _cl
        for (( _cl = 0; _cl < total; _cl++ )); do
            printf '\033[2K\n'
        done
        printf '\033[%dA' "$total"
    }

    printf '\n'
    _xmenu_render

    local key esc seq prev next
    while true; do
        read -rsk1 key
        case "$key" in
            $'\x1b')
                read -rsk1 -t 0.05 esc  2>/dev/null || esc=''
                if [[ "$esc" == '[' ]]; then
                    read -rsk1 -t 0.05 seq 2>/dev/null || seq=''
                    case "$seq" in
                        A)
                            prev=$sel
                            while (( prev > 1 )); do
                                (( prev-- ))
                                [[ "${items[$prev]}" != SEPARATOR:* ]] \
                                    && { sel=$prev; break; }
                            done
                            ;;
                        B)
                            next=$sel
                            while (( next < total )); do
                                (( next++ ))
                                [[ "${items[$next]}" != SEPARATOR:* ]] \
                                    && { sel=$next; break; }
                            done
                            ;;
                    esac
                fi
                ;;
            $'\n'|$'\r')
                _xmenu_clear
                _XCODE_SELECTED=$sel
                unfunction _xmenu_render _xmenu_clear
                return 0
                ;;
            q|Q)
                _xmenu_clear
                unfunction _xmenu_render _xmenu_clear
                return 1
                ;;
        esac

        printf '\033[%dA' "$total"
        _xmenu_render
    done
}

# ---------------------------------------------------------------------------
# _xcode_select_target
# Discover connected devices/simulators and let the user pick one.
#
# Callers MUST declare these locals before calling:
#   local _xt_sdk="" _xt_dest="" _xt_type="" _xt_id="" _xt_label=""
# The function writes directly into the caller's dynamic scope.
#
# Returns: 0 on selection, 1 on xcrun/no-devices error, 2 on user abort (q).
# ---------------------------------------------------------------------------

_xcode_select_target() {
    _xlog "Scanning" "available devices ..."

    local raw
    raw=$(xcrun xctrace list devices 2>/dev/null) || {
        _xerr "xcrun xctrace list devices failed"
        return 1
    }

    local -a dev_labels dev_ids sim_labels sim_ids
    local in_dev=0 in_sim=0 line

    while IFS= read -r line; do
        case "$line" in
            '== Devices ==')    in_dev=1; in_sim=0; continue ;;
            '== Simulators ==') in_sim=1; in_dev=0; continue ;;
            '=='*'==')          in_dev=0; in_sim=0; continue ;;
        esac

        [[ -z "${line// }" ]]        && continue
        [[ "$line" == *'(host)'* ]]  && continue

        local id
        id=$(printf '%s' "$line" \
            | grep -oE '\([A-Fa-f0-9][A-Fa-f0-9-]{6,}\)' \
            | tail -1 \
            | tr -d '()')
        [ -z "$id" ] && continue

        local label
        label=$(printf '%s' "$line" | sed "s/ (${id})$//")
        if (( in_dev )); then
            dev_labels+=("$label"); dev_ids+=("$id")
        elif (( in_sim )); then
            sim_labels+=("$label"); sim_ids+=("$id")
        fi
    done <<< "$raw"

    if [ ${#dev_labels[@]} -eq 0 ] && [ ${#sim_labels[@]} -eq 0 ]; then
        _xerr "no devices or simulators found"
        return 1
    fi

    local -a labels ids types
    if [ ${#dev_labels[@]} -gt 0 ]; then
        labels+=("SEPARATOR:── Real Devices ─────────────────────────────────")
        ids+=(""); types+=("separator")
        local j
        for (( j = 1; j <= ${#dev_labels[@]}; j++ )); do
            labels+=("${dev_labels[$j]}")
            ids+=("${dev_ids[$j]}")
            types+=("device")
        done
    fi
    if [ ${#sim_labels[@]} -gt 0 ]; then
        labels+=("SEPARATOR:── Simulators ──────────────────────────────────")
        ids+=(""); types+=("separator")
        local k
        for (( k = 1; k <= ${#sim_labels[@]}; k++ )); do
            labels+=("${sim_labels[$k]}")
            ids+=("${sim_ids[$k]}")
            types+=("simulator")
        done
    fi

    printf '\n\033[1mSelect target\033[0m'
    printf '  \033[2m(↑↓ move   Enter confirm   q quit)\033[0m\n'

    local _XCODE_SELECTED=1
    _xcode_menu "${labels[@]}" || {
        _xwarn "Aborted" "no target selected"; return 2
    }

    local idx=$_XCODE_SELECTED
    _xt_label="${labels[$idx]}"
    _xt_id="${ids[$idx]}"
    _xt_type="${types[$idx]}"

    printf '\n'
    _xlog "Target" "$_xt_label"

    if [[ "$_xt_type" == "simulator" ]]; then
        _xt_sdk="iphonesimulator"
        _xt_dest="platform=iOS Simulator,id=${_xt_id}"
    else
        _xt_sdk="iphoneos"
        _xt_dest="id=${_xt_id}"
    fi

    return 0
}

# ---------------------------------------------------------------------------
# xinstall — interactive device/simulator picker + build + install
# ---------------------------------------------------------------------------

xinstall() {
    _xcode_require || return 1
    local workspace="" scheme="" configuration=""

    while [ $# -gt 0 ]; do
        case "$1" in
            --workspace)     workspace="$2";     shift 2 ;;
            --scheme)        scheme="$2";        shift 2 ;;
            --configuration) configuration="$2"; shift 2 ;;
            --help|-h)
                printf 'Usage: xinstall [--workspace <name>] --scheme <name>'
                printf ' --configuration <name>\n'
                return 0
                ;;
            *)
                _xerr "unknown option: $1"
                return 1
                ;;
        esac
    done

    [ -z "$scheme" ] && {
        _xerr "missing required option: --scheme"; return 1
    }
    [ -z "$configuration" ] && {
        _xerr "missing required option: --configuration"; return 1
    }

    local skip_build=0
    _xcode_ask "Skip build (install existing .app)?" && skip_build=1

    local _xt_sdk="" _xt_dest="" _xt_type="" _xt_id="" _xt_label=""
    _xcode_select_target
    local _rc=$?
    (( _rc == 2 )) && return 0
    (( _rc != 0 )) && return 1

    # Resolve the actual .app product name — it may differ from the scheme name.
    # Primary: read PRODUCT_NAME from xcodebuild build settings.
    # Fallback: prompt the user; empty input is fatal.
    local app_name=""
    local _bs_args=()
    [ -n "$workspace" ] && _bs_args+=(-workspace "${workspace}.xcworkspace")
    _bs_args+=(-scheme "$scheme" -configuration "$configuration" -sdk "$_xt_sdk")
    app_name=$(xcodebuild -showBuildSettings "${_bs_args[@]}" 2>/dev/null \
        | awk -F' = ' '/^\s*PRODUCT_NAME\s*=/ {
            gsub(/^[[:space:]]+/, "", $2); print $2; exit
        }')

    if [ -z "$app_name" ]; then
        _xwarn "Warning" "could not read PRODUCT_NAME from build settings"
        printf '\n  \033[1mEnter app name\033[0m  \033[2m(without .app extension)\033[0m: '
        IFS= read -r app_name
        [ -z "$app_name" ] && { _xerr "app name is required"; return 1; }
    fi

    local app_path=""

    if (( skip_build )); then
        _xlog "Searching" "existing ${app_name}.app in DerivedData ..."
    else
        if _xcode_ask "Clean before building?"; then
            _xlog "Cleaning" "${scheme} (${configuration} | ${_xt_sdk})"
            local clean_cmd=(xcodebuild)
            [ -n "$workspace" ] && clean_cmd+=(-workspace "${workspace}.xcworkspace")
            clean_cmd+=(-scheme "$scheme" -sdk "$_xt_sdk" \
                        -configuration "$configuration" clean)
            "${clean_cmd[@]}" | xcbeautify
        fi

        local build_cmd=(xcodebuild)
        [ -n "$workspace" ] && build_cmd+=(-workspace "${workspace}.xcworkspace")
        build_cmd+=(
            -scheme        "$scheme"
            -configuration "$configuration"
            -sdk           "$_xt_sdk"
            -destination   "$_xt_dest"
            build
        )

        _xlog "Building" "${scheme} (${configuration} | ${_xt_sdk})"
        "${build_cmd[@]}" | xcbeautify
        # shellcheck disable=SC2154  # pipestatus is zsh-specific (lowercase, 1-based)
        local build_status=${pipestatus[1]}

        if [ "$build_status" -ne 0 ]; then
            _xerr "build failed (exit ${build_status})"
            return 1
        fi

        _xlog "Searching" "${app_name}.app in DerivedData ..."
    fi

    app_path=$(
        find "${HOME}/Library/Developer/Xcode/DerivedData" \
            -maxdepth 6 -iname "${app_name}.app" -type d 2>/dev/null \
        | while IFS= read -r p; do
            printf '%s\t%s\n' \
                "$(stat -f '%m' "$p" 2>/dev/null || printf '0')" "$p"
          done \
        | sort -rn | head -1 | cut -f2-
    )
    if [ -z "$app_path" ]; then
        _xerr "no .app found for '${app_name}' in DerivedData"
        return 1
    fi
    _xlog "Found" "$app_path"

    # ── Install ───────────────────────────────────────────────────────────
    _xlog "Installing" "$(basename "$app_path")"

    if [[ "$_xt_type" == "simulator" ]]; then
        local sim_state
        sim_state=$(xcrun simctl list devices 2>/dev/null \
            | grep "$_xt_id" \
            | grep -o 'Booted\|Shutdown' \
            | head -1)

        if [[ "$sim_state" != "Booted" ]]; then
            _xlog "Booting" "simulator ..."
            xcrun simctl boot "$_xt_id" 2>/dev/null || true
        fi

        xcrun simctl install "$_xt_id" "$app_path" || {
            _xerr "simctl install failed"
            return 1
        }

        open -a Simulator 2>/dev/null || true

    else
        local ok=0
        xcrun devicectl device install app \
            --device "$_xt_id" "$app_path" 2>/dev/null \
            && ok=1

        if [ "$ok" -eq 0 ] && command -v ios-deploy >/dev/null 2>&1; then
            ios-deploy --bundle "$app_path" --id "$_xt_id" && ok=1
        fi

        if [ "$ok" -eq 0 ]; then
            _xerr "install failed: no working install tool found"
            printf '         Requires Xcode 15+ (devicectl) or ios-deploy\n' >&2
            return 1
        fi
    fi

    # ── Extract bundle ID + offer launch (simulator only) ─────────────────
    local bundle_id
    bundle_id=$(/usr/libexec/PlistBuddy \
        -c "Print CFBundleIdentifier" \
        "${app_path}/Info.plist" 2>/dev/null) || bundle_id=""

    _xlog "Installed" "${bundle_id:-$(basename "$app_path")}"

    if [[ "$_xt_type" == "simulator" ]] && [ -n "$bundle_id" ]; then
        if _xcode_ask "Launch app?" 30; then
            xcrun simctl launch "$_xt_id" "$bundle_id"
        fi
    fi

    _xlog "Finished" ""
}

# ---------------------------------------------------------------------------
# xindex — generate buildServer.json + compile_commands.json for Neovim LSP
#   buildServer.json  → sourcekit-lsp  (Swift / ObjC gd / gr)
#   compile_commands.json → clangd     (ObjC / C / C++ gd / gr)
# ---------------------------------------------------------------------------

xindex() {
    if ! command -v xcode-build-server >/dev/null 2>&1; then
        _xerr "xcode-build-server not found"
        _xhint "Install with: brew install xcode-build-server"
        return 1
    fi
    _xcode_require || return 1

    local workspace="" scheme="" configuration="Debug" skip_build=0
    while [ $# -gt 0 ]; do
        case "$1" in
            --workspace)     workspace="$2";     shift 2 ;;
            --scheme)        scheme="$2";        shift 2 ;;
            --configuration) configuration="$2"; shift 2 ;;
            --skip-build)    skip_build=1;        shift   ;;
            --help|-h)
                printf 'Usage: xindex --workspace <path> --scheme <name> [--configuration <name>] [--skip-build]\n'
                printf '  --workspace      dir containing .xcworkspace, or path without extension\n'
                printf '                   e.g. Example  or  Example/ZeppDevice\n'
                printf '  --scheme         Xcode scheme name\n'
                printf '  --configuration  Debug (default) or Release\n'
                printf '  --skip-build     skip xcodebuild, reuse existing DerivedData\n'
                return 0 ;;
            *)
                _xerr "Unknown option: $1"
                _xhint "Usage: xindex --workspace <path> --scheme <name> [--configuration <name>] [--skip-build]"
                return 1 ;;
        esac
    done

    [ -z "$workspace" ] && _xerr "Missing --workspace" && return 1
    [ -z "$scheme" ]    && _xerr "Missing --scheme"    && return 1

    local ws_path="${workspace}.xcworkspace"
    if [ ! -d "$ws_path" ]; then
        if [ -d "$workspace" ]; then
            local found
            found="$(find "$workspace" -maxdepth 1 -name "*.xcworkspace" -type d | head -1)"
            [ -n "$found" ] && ws_path="$found" || { _xerr "No .xcworkspace found in: $workspace"; return 1; }
        else
            _xerr "Workspace not found: $ws_path"
            return 1
        fi
    fi

    # ── Step 1: build (generic simulator, no device selection needed) ─────────
    if (( skip_build )); then
        _xlog "Skipped" "build — reusing existing DerivedData"
    else
        _xlog "Building" "${scheme} (${configuration})"
        local build_cmd=(xcodebuild -workspace "$ws_path" -scheme "$scheme"
            -configuration "$configuration"
            -destination "generic/platform=iOS Simulator"
            build)
        "${build_cmd[@]}" | xcbeautify
        local build_rc="${pipestatus[1]}"
        if (( build_rc != 0 )); then
            _xerr "Build failed (exit $build_rc) — index not generated"
            return 1
        fi
        _xlog "Built" "${scheme}"
    fi

    # ── Step 2: buildServer.json (sourcekit-lsp — Swift / ObjC gd/gr) ─────────
    _xlog "Generating" "buildServer.json"
    if ! xcode-build-server config -workspace "$ws_path" -scheme "$scheme"; then
        _xerr "xcode-build-server config failed"
        return 1
    fi
    _xlog "Generated" "buildServer.json"

    # ── Step 3: compile_commands.json from the just-produced build log ─────────
    local ws_name dd_base log log_dir info
    ws_name="$(basename "$ws_path" .xcworkspace)"
    dd_base="$HOME/Library/Developer/Xcode/DerivedData"
    log=""
    for info in "$dd_base"/*/info.plist; do
        [ -f "$info" ] || continue
        grep -q "$ws_name" "$info" 2>/dev/null || continue
        log_dir="$(dirname "$info")/Logs/Build"
        [ -d "$log_dir" ] || continue
        log="$(ls -t "$log_dir"/*.xcactivitylog 2>/dev/null | head -1)"
        [ -n "$log" ] && break
    done

    if [ -z "$log" ]; then
        _xwarn "Skipped" "build log not found in DerivedData"
        _xhint "compile_commands.json was NOT generated"
    else
        _xlog "Parsing" "$(basename "$log")"
        if xcode-build-server parse -logArchive "$log" > compile_commands.json; then
            _xlog "Generated" "compile_commands.json"
        else
            _xwarn "Failed" "xcode-build-server parse returned error"
            _xhint "compile_commands.json may be incomplete"
        fi
    fi

    _xlog "Done" "run :LspRestart in Neovim"
}

# ---------------------------------------------------------------------------
# xbs-patch — Patch xcode-build-server to skip unsupported log formats.
# Usage: xbs-patch [--dry-run] [--help]
#
# Xcode 26+ uses ogArchive log format; xcode-build-server ≤1.3.0 crashes on
# it. This patch makes extract_compile_log skip unrecognised files gracefully.
# Safe to run multiple times (idempotent). Re-run after `brew upgrade
# xcode-build-server` if the error returns.
# ---------------------------------------------------------------------------

xbs-patch() {
    local dry_run=0

    for arg in "$@"; do
        case "$arg" in
            --help|-h)
                printf 'Usage: xbs-patch [--dry-run]\n'
                printf '\n'
                printf '  Patches xcode-build-server xcactivitylog.py to skip Xcode 26+\n'
                printf '  ogArchive log format instead of crashing with ValueError.\n'
                printf '  Safe to run multiple times. Re-run after brew upgrade.\n'
                return 0 ;;
            --dry-run) dry_run=1 ;;
        esac
    done

    local xbs_bin
    xbs_bin=$(command -v xcode-build-server 2>/dev/null)
    if [[ -z "$xbs_bin" ]]; then
        _xerr "xcode-build-server not found"
        _xhint "Install with: brew install xcode-build-server"
        return 1
    fi

    local xbs_real
    xbs_real=$(readlink -f "$xbs_bin" 2>/dev/null || realpath "$xbs_bin" 2>/dev/null || echo "$xbs_bin")

    local target
    target="$(dirname "$(dirname "$xbs_real")")/libexec/xcactivitylog.py"

    if [[ ! -f "$target" ]]; then
        _xerr "xcactivitylog.py not found at: $target"
        return 1
    fi

    _xlog "Target" "$target"

    if grep -q "ogArchive log format" "$target" 2>/dev/null; then
        _xlog "Already" "patch already applied — nothing to do"
        return 0
    fi

    if [[ $dry_run -eq 1 ]]; then
        _xlog "DryRun" "would patch $target"
        return 0
    fi

    python3 - "$target" <<'PYEOF'
import sys

path = sys.argv[1]
with open(path, "r") as f:
    content = f.read()

OLD = "def extract_compile_log(path):\n    for type, value in tokenizer(path):"
NEW = (
    "def extract_compile_log(path):\n"
    "    # Xcode 26+ uses ogArchive log format which is not SLF0-based; skip gracefully.\n"
    "    try:\n"
    "        tokens = list(tokenizer(path))\n"
    "    except ValueError as e:\n"
    "        import sys\n"
    "        print(f\"warning: skipping unsupported log format at {path}: {e}\", file=sys.stderr)\n"
    "        return\n"
    "    for type, value in tokens:"
)

if OLD not in content:
    print("error: patch target not found — already patched or upstream changed", file=sys.stderr)
    sys.exit(2)

with open(path, "w") as f:
    f.write(content.replace(OLD, NEW, 1))
PYEOF

    local rc=$?
    case $rc in
        0) _xlog "Patched" "$target" ;;
        2) _xwarn "Skipped" "patch target not found — may already be applied or upstream changed" ;;
        *) _xerr "python3 patch script failed (exit $rc)"; return 1 ;;
    esac
}

# ---------------------------------------------------------------------------
# xhelp — Xcode helpers reference.
# Usage: xhelp [list | show [--module <id>] [--lang zh]] [--help]
# ---------------------------------------------------------------------------

xhelp() {
    local _i18n="${XDG_CONFIG_HOME}/alias/i18n/xcode.json"
    case "$1" in
        list)      shift; _help_list "$_i18n" "$@" ;;
        --help|-h) _help_usage "xhelp" ;;
        show)      shift; _help_show "$_i18n" "$@" ;;
        *)         _help_show "$_i18n" "$@" ;;
    esac
}
