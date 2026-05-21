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

# ---------------------------------------------------------------------------
# Dependency check — call at the top of every public function.
# Verifies xcodebuild (Xcode) and xcbeautify (brew) are available.
# ---------------------------------------------------------------------------

_xcode_require() {
    local missing=0

    if ! command -v xcodebuild >/dev/null 2>&1; then
        _xerr "xcodebuild not found"
        printf '         Install Xcode from the App Store or run:\n' >&2
        printf '           xcode-select --install\n' >&2
        missing=1
    fi

    if ! command -v xcbeautify >/dev/null 2>&1; then
        _xerr "xcbeautify not found"
        printf '         Install with: brew install xcbeautify\n' >&2
        missing=1
    fi

    return "$missing"
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

    local cmd=(xcodebuild)
    [ -n "$workspace" ] && cmd+=(-workspace "${workspace}.xcworkspace")
    cmd+=(-scheme "$scheme" -sdk iphoneos -configuration "$configuration" build)

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
                printf '     %s\n' "${items[$j]}"
            fi
        done
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
                _XCODE_SELECTED=$sel
                unfunction _xmenu_render
                return 0
                ;;
            q|Q)
                unfunction _xmenu_render
                return 1
                ;;
        esac

        printf '\033[%dA' "$total"
        _xmenu_render
    done
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

    # ── Discover devices ──────────────────────────────────────────────────
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

        if (( in_dev )); then
            dev_labels+=("$line"); dev_ids+=("$id")
        elif (( in_sim )); then
            sim_labels+=("$line"); sim_ids+=("$id")
        fi
    done <<< "$raw"

    if [ ${#dev_labels[@]} -eq 0 ] && [ ${#sim_labels[@]} -eq 0 ]; then
        _xerr "no devices or simulators found"
        return 1
    fi

    # Merge: real devices first, simulators second, with section headers
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

    # ── Select target ─────────────────────────────────────────────────────
    printf '\n\033[1mSelect target\033[0m'
    printf '  \033[2m(↑↓ move   Enter confirm   q quit)\033[0m\n'

    local _XCODE_SELECTED=1
    _xcode_menu "${labels[@]}" || {
        printf '\n'; _xwarn "Aborted" ""; return 0
    }

    local idx=$_XCODE_SELECTED
    local sel_label="${labels[$idx]}"
    local sel_id="${ids[$idx]}"
    local sel_type="${types[$idx]}"

    printf '\n'
    _xlog "Target" "$sel_label"

    # ── Build ─────────────────────────────────────────────────────────────
    local sdk dest
    if [[ "$sel_type" == "simulator" ]]; then
        sdk="iphonesimulator"
        dest="platform=iOS Simulator,id=${sel_id}"
    else
        sdk="iphoneos"
        dest="id=${sel_id}"
    fi

    local derived_data
    derived_data=$(mktemp -d) || { _xerr "mktemp failed"; return 1; }

    local build_cmd=(xcodebuild)
    [ -n "$workspace" ] && build_cmd+=(-workspace "${workspace}.xcworkspace")
    build_cmd+=(
        -scheme          "$scheme"
        -configuration   "$configuration"
        -sdk             "$sdk"
        -destination     "$dest"
        -derivedDataPath "$derived_data"
        build
    )

    _xlog "Building" "${scheme} (${configuration} | ${sdk})"
    "${build_cmd[@]}" | xcbeautify
    # shellcheck disable=SC2154  # pipestatus is zsh-specific (lowercase, 1-based)
    local build_status=${pipestatus[1]}

    if [ "$build_status" -ne 0 ]; then
        _xerr "build failed (exit ${build_status})"
        rm -rf "$derived_data"
        return 1
    fi

    # ── Locate .app ───────────────────────────────────────────────────────
    local app_path
    app_path=$(find "$derived_data/Build/Products" \
        -name "*.app" -maxdepth 3 -type d | head -1)

    if [ -z "$app_path" ]; then
        _xerr ".app not found under $derived_data/Build/Products"
        rm -rf "$derived_data"
        return 1
    fi

    # ── Install ───────────────────────────────────────────────────────────
    _xlog "Installing" "$(basename "$app_path")"

    if [[ "$sel_type" == "simulator" ]]; then
        local sim_state
        sim_state=$(xcrun simctl list devices 2>/dev/null \
            | grep "$sel_id" \
            | grep -o 'Booted\|Shutdown' \
            | head -1)

        if [[ "$sim_state" != "Booted" ]]; then
            _xlog "Booting" "simulator ..."
            xcrun simctl boot "$sel_id" 2>/dev/null || true
        fi

        xcrun simctl install "$sel_id" "$app_path" || {
            _xerr "simctl install failed"
            rm -rf "$derived_data"
            return 1
        }

        open -a Simulator 2>/dev/null || true

    else
        local ok=0
        xcrun devicectl device install app \
            --device "$sel_id" "$app_path" 2>/dev/null \
            && ok=1

        if [ "$ok" -eq 0 ] && command -v ios-deploy >/dev/null 2>&1; then
            ios-deploy --bundle "$app_path" --id "$sel_id" && ok=1
        fi

        if [ "$ok" -eq 0 ]; then
            _xerr "install failed: no working install tool found"
            printf '         Requires Xcode 15+ (devicectl) or ios-deploy\n' >&2
            rm -rf "$derived_data"
            return 1
        fi
    fi

    # ── Extract bundle ID + offer launch (simulator only) ─────────────────
    local bundle_id
    bundle_id=$(/usr/libexec/PlistBuddy \
        -c "Print CFBundleIdentifier" \
        "${app_path}/Info.plist" 2>/dev/null) || bundle_id=""

    rm -rf "$derived_data"
    _xlog "Installed" "${bundle_id:-$(basename "$app_path")}"

    if [[ "$sel_type" == "simulator" ]] && [ -n "$bundle_id" ]; then
        printf '\n\033[1mLaunch app?\033[0m  [y/N] '
        local reply
        read -r reply
        if [[ "$reply" == [yY] ]]; then
            xcrun simctl launch "$sel_id" "$bundle_id"
        fi
    fi

    _xlog "Finished" ""
}

# ---------------------------------------------------------------------------
# xhelp — cheatsheet for all x* functions
# ---------------------------------------------------------------------------

xhelp() {
    local bold=$'\033[1m'
    local cyan=$'\033[0;36m'
    local yellow=$'\033[0;33m'
    local reset=$'\033[0m'
    local sep='────────────────────────────'

    echo ""
    printf '%sXcode Helpers Cheatsheet%s\n' "$bold" "$reset"
    echo "$sep"

    _xhelp_section()  { printf '\n%s  %s%s\n'       "$yellow" "$1" "$reset"; }
    _xhelp_synopsis() { printf '  %s%-12s%s  %s\n'  "$cyan"   "$1" "$reset" "$2"; }
    _xhelp_note()     { printf "    %s\n" "$1"; }

    _xhelp_section "xclean"
    _xhelp_synopsis "xclean" \
        "[--workspace <name>] --scheme <name> --configuration <name>"
    _xhelp_note "Clean build artifacts for the scheme."

    _xhelp_section "xbuild"
    _xhelp_synopsis "xbuild" \
        "[--workspace <name>] --scheme <name> --configuration <name>"
    _xhelp_note "Build for iphoneos SDK; output piped through xcbeautify."

    _xhelp_section "xarchive"
    _xhelp_synopsis "xarchive" \
        "[--workspace <name>] --scheme <name>"
    _xhelp_synopsis "" \
        "--configuration <name> --archive-path <path>"
    _xhelp_note "Archive the scheme to the given path."

    _xhelp_section "xinstall"
    _xhelp_synopsis "xinstall" \
        "[--workspace <name>] --scheme <name> --configuration <name>"
    _xhelp_note "Interactively pick a device or simulator (↑↓ + Enter),"
    _xhelp_note "build the app, and install it — no Xcode required."
    _xhelp_note "Device install uses devicectl (Xcode 15+) or ios-deploy."

    echo ""
    echo "$sep"
    echo ""

    unfunction _xhelp_section _xhelp_synopsis _xhelp_note
}
