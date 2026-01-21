#!/usr/bin/env bash
set -euo pipefail

# --------------------------------------------
# MrRSS update checker/downloader/installer (macOS)
# Repo: WCY-dt/MrRSS
# --------------------------------------------

REPO_OWNER="WCY-dt"
REPO_NAME="MrRSS"
GITHUB_API="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest"

DEFAULT_APP_CANDIDATES=(
  "/Applications/MrRSS.app"
  "./MrRSS.app"
)

ASSET_SUFFIX="darwin-universal-portable.zip"

# --------------------------------------------
# Cargo-style printing (indented + colored "==>")
# IMPORTANT: logs go to stderr to avoid polluting stdout data streams.
# --------------------------------------------
mrrss_info()  { printf "    \033[1;32m==>\033[0m %s\n" "$*" >&2; }
mrrss_warn()  { printf "    \033[1;33m==>\033[0m %s\n" "$*" >&2; }
mrrss_error() { printf "    \033[1;31m==>\033[0m %s\n" "$*" >&2; }

mrrss_disable_color() {
  mrrss_info()  { printf "    ==> %s\n" "$*" >&2; }
  mrrss_warn()  { printf "    ==> %s\n" "$*" >&2; }
  mrrss_error() { printf "    ==> %s\n" "$*" >&2; }
}

# --------------------------------------------
# Usage
# --------------------------------------------
usage() {
  cat <<'EOF'
Usage:
  mrrss_update.sh [options]

Options:
  --app <path>         Specify path to MrRSS.app
  --check-only         Only check latest version
  --current-only       Only show current installed version
  --no-color           Disable colored output
  -h, --help           Show help
EOF
}

# --------------------------------------------
# Globals set by parse_args()
# --------------------------------------------
APP_PATH=""
CHECK_ONLY=0
CURRENT_ONLY=0

# --------------------------------------------
# Atomic helpers
# --------------------------------------------
need_cmd() {
  command -v "$1" >/dev/null 2>&1 || { mrrss_error "Required command not found: $1"; exit 1; }
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

pick_python() {
  if have_cmd python3; then
    echo "python3"
  elif have_cmd python; then
    echo "python"
  else
    echo ""
  fi
}

ver_norm() { echo "$1" | sed -E 's/^v//'; }

ver_lt() {
  [[ "$(printf "%s\n%s\n" "$1" "$2" | sort -V | head -n1)" == "$1" ]] && [[ "$1" != "$2" ]]
}

prompt_yes_no() {
  local ans
  read -r -p "$1 [y/N]: " ans
  ans="$(printf "%s" "$ans" | tr '[:upper:]' '[:lower:]')"
  case "$ans" in
    y|yes) return 0 ;;
    *)     return 1 ;;
  esac
}

# For tag_name only (simple, stable)
json_get_string() {
  sed -nE "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"([^\"]+)\".*/\1/p" | head -n 1
}

# Robust JSON parsing (no jq). Reads JSON from stdin.
extract_asset_url_by_suffix_json() {
  local suffix="$1"
  local py
  py="$(pick_python)"
  [[ -n "$py" ]] || { mrrss_error "python3/python is required to parse GitHub JSON (jq is not used)."; exit 1; }

  "$py" -c '
import sys, json
suffix = sys.argv[1]
raw = sys.stdin.read().strip()
if not raw:
    sys.exit(0)
data = json.loads(raw)
for a in data.get("assets", []):
    name = (a.get("name") or "")
    url = (a.get("browser_download_url") or "")
    if name.endswith(suffix) and url:
        print(url)
        sys.exit(0)
' "$suffix"
}

debug_list_assets_json() {
  local py
  py="$(pick_python)"
  [[ -n "$py" ]] || return 0

  "$py" -c '
import sys, json
raw = sys.stdin.read().strip()
if not raw:
    sys.exit(0)
data = json.loads(raw)
for a in data.get("assets", []):
    n = a.get("name") or ""
    if n:
        print(n)
'
}

# --------------------------------------------
# Argument parsing
# --------------------------------------------
parse_args() {
  APP_PATH=""
  CHECK_ONLY=0
  CURRENT_ONLY=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --app) APP_PATH="${2:-}"; shift 2 ;;
      --check-only) CHECK_ONLY=1; shift ;;
      --current-only) CURRENT_ONLY=1; shift ;;
      --no-color) mrrss_disable_color; shift ;;
      -h|--help) usage; exit 0 ;;
      *) mrrss_error "Unknown option: $1"; usage; exit 2 ;;
    esac
  done
}

# --------------------------------------------
# Local app detection/version
# --------------------------------------------
find_app_path() {
  if [[ -n "${APP_PATH}" ]]; then
    echo "${APP_PATH}"
    return
  fi

  local p
  for p in "${DEFAULT_APP_CANDIDATES[@]}"; do
    [[ -d "$p" ]] && { echo "$p"; return; }
  done

  echo ""
}

read_local_version_from_plist() {
  local app="$1"
  local plist="$app/Contents/Info.plist"

  [[ -f "$plist" ]] || { echo ""; return; }
  /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$plist" 2>/dev/null || true
}

get_local_installation() {
  # Outputs: "APP_PATH|LOCAL_VER" (LOCAL_VER may be empty) to stdout
  local app local_ver
  app="$(find_app_path)"
  local_ver=""
  if [[ -n "$app" ]]; then
    local_ver="$(read_local_version_from_plist "$app" | tr -d '\r\n' || true)"
  fi
  printf "%s|%s" "$app" "$local_ver"
}

# --------------------------------------------
# Remote release detection
# --------------------------------------------
fetch_latest_release_json() {
  need_cmd curl
  mrrss_info "Fetching latest release from GitHub API: $GITHUB_API ..."
  local json
  json="$(curl -fsSL "$GITHUB_API")"

  if ! printf "%s" "$json" | grep -q '"tag_name"'; then
    mrrss_error "GitHub API response does not contain tag_name"
    mrrss_error "Response (first 200 chars): $(printf "%s" "$json" | head -c 200)"
    exit 1
  fi

  # JSON goes to stdout
  printf "%s" "$json"
}

get_latest_release() {
  # Outputs ONLY: "LATEST_TAG|LATEST_VER|ASSET_URL|OUT_FILE" to stdout
  local json latest_tag latest_ver asset_url out_file

  mrrss_info "Checking latest version..."
  json="$(fetch_latest_release_json)"

  latest_tag="$(printf "%s" "$json" | json_get_string tag_name | tr -d '\r\n')"
  [[ -n "$latest_tag" ]] || { mrrss_error "Failed to parse latest tag_name from GitHub API"; exit 1; }

  latest_ver="$(ver_norm "$latest_tag")"
  mrrss_info "Latest version: v$latest_ver"

  asset_url="$(printf "%s" "$json" | extract_asset_url_by_suffix_json "$ASSET_SUFFIX" || true)"
  mrrss_info "Asset url: $asset_url"

  if [[ -z "$asset_url" ]]; then
    mrrss_error "No release asset matched suffix: $ASSET_SUFFIX"
    mrrss_info "Available assets:"
    printf "%s" "$json" | debug_list_assets_json | sed 's/^/        - /' >&2
    exit 1
  fi

  out_file="MrRSS-${latest_ver}-${ASSET_SUFFIX}"
  printf "%s|%s|%s|%s" "$latest_tag" "$latest_ver" "$asset_url" "$out_file"
}

# --------------------------------------------
# Download & install
# --------------------------------------------
download_file() {
  local url="$1"
  local out="$2"

  [[ -n "$url" ]] || { mrrss_error "Download URL is empty"; exit 1; }
  [[ -n "$out" ]] || { mrrss_error "Output file name is empty"; exit 1; }

  mrrss_info "Downloading: $url"
  curl -fL --progress-bar "$url" -o "$out"
  mrrss_info "Saved to: $out"
}

install_zip_to_applications() {
  local zip="$1"

  need_cmd unzip
  need_cmd mktemp
  need_cmd find
  need_cmd rm
  need_cmd ditto
  need_cmd sudo

  local tmp app
  tmp="$(mktemp -d)"

  mrrss_info "Extracting..."
  unzip -q "$zip" -d "$tmp"

  app="$(find "$tmp" -maxdepth 4 -type d -name "MrRSS.app" -print -quit || true)"
  [[ -n "$app" ]] || { mrrss_error "MrRSS.app not found in zip"; rm -rf "$tmp"; exit 1; }

  mrrss_info "Installing to /Applications (sudo required)"
  sudo -v

  # Force overwrite if already installed.
  sudo rm -rf /Applications/MrRSS.app
  sudo ditto "$app" /Applications/MrRSS.app

  rm -rf "$tmp"
  mrrss_info "Installed: /Applications/MrRSS.app"
}

# --------------------------------------------
# Decision flow helpers
# --------------------------------------------
handle_current_only() {
  local app="$1" local_ver="$2"
  if [[ -n "$local_ver" ]]; then
    mrrss_info "Current version: v$(ver_norm "$local_ver")"
    [[ -n "$app" ]] && mrrss_info "App path: $app"
  else
    mrrss_warn "MrRSS is not installed (or version could not be read)"
  fi
}

handle_not_installed_flow() {
  local asset_url="$1" out_file="$2"
  mrrss_warn "Local installation not detected"
  if prompt_yes_no "Download and install latest version to /Applications?"; then
    download_file "$asset_url" "$out_file"
    install_zip_to_applications "$out_file"
  else
    mrrss_info "No action taken"
  fi
}

handle_up_to_date_flow() { mrrss_info "Already up to date"; }

handle_update_available_flow() {
  local local_norm="$1" latest_ver="$2" asset_url="$3" out_file="$4"
  mrrss_warn "Update available: v$local_norm -> v$latest_ver"
  if prompt_yes_no "Download update?"; then
    download_file "$asset_url" "$out_file"
    if prompt_yes_no "Install to /Applications (sudo required)?"; then
      install_zip_to_applications "$out_file"
    else
      mrrss_info "Install skipped"
    fi
  else
    mrrss_info "Download cancelled"
  fi
}

handle_local_newer_flow() {
  local local_norm="$1" latest_ver="$2"
  mrrss_warn "Local version appears newer than latest release: v$local_norm > v$latest_ver"
}

# --------------------------------------------
# Main
# --------------------------------------------
main() {
  parse_args "$@"

  local app local_ver
  IFS="|" read -r app local_ver <<<"$(get_local_installation)"

  if [[ "$CURRENT_ONLY" -eq 1 ]]; then
    handle_current_only "$app" "$local_ver"
    exit 0
  fi

  local latest_tag latest_ver asset_url out_file
  IFS="|" read -r latest_tag latest_ver asset_url out_file <<<"$(get_latest_release)"

  if [[ "$CHECK_ONLY" -eq 1 ]]; then
    exit 0
  fi

  if [[ -z "$local_ver" ]]; then
    handle_not_installed_flow "$asset_url" "$out_file"
    exit 0
  fi

  local local_norm
  local_norm="$(ver_norm "$local_ver")"
  mrrss_info "Current version: v$local_norm"

  if [[ "$local_norm" == "$latest_ver" ]]; then
    handle_up_to_date_flow
    exit 0
  fi

  if ver_lt "$local_norm" "$latest_ver"; then
    handle_update_available_flow "$local_norm" "$latest_ver" "$asset_url" "$out_file"
    exit 0
  fi

  handle_local_newer_flow "$local_norm" "$latest_ver"
}

main "$@"

