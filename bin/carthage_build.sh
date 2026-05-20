#!/usr/bin/env bash
set -euo pipefail

# ================================
#   Carthage Build Wrapper
#   Usage:
#     carthage_build --package-name HMAudioKit
#     carthage_build --package-name HMAudioKit --log-path ~/Downloads/build.log
#     carthage_build --package-name HMAudioKit --no-xcframeworks
# ================================

GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
CYAN="\033[0;36m"
RESET="\033[0m"

PACKAGE_NAME=""
LOG_PATH=""
USE_XCFRAMEWORKS=true

parse_args() {
  while [[ "$#" -gt 0 ]]; do
    case $1 in
      --package-name)
        PACKAGE_NAME="$2"
        shift 2
        ;;
      --log-path)
        LOG_PATH="$2"
        shift 2
        ;;
      --no-xcframeworks)
        USE_XCFRAMEWORKS=false
        shift 1
        ;;
      *)
        echo -e "${RED}✗ Unknown argument:${RESET} $1"
        exit 1
        ;;
    esac
  done
}

validate_args() {
  if [[ -z "$PACKAGE_NAME" ]]; then
    echo -e "${RED}✗ Error: --package-name is required${RESET}"
    exit 1
  fi
}

cleanup_xcschemes() {
  echo -e "${BLUE}==>${RESET} Cleaning up unnecessary xcschemes in Pods..."
  find Pods -name '*.xcscheme' \
    '!' -name "${PACKAGE_NAME}.xcscheme" \
    '!' -name "${PACKAGE_NAME}-Unit-Tests.xcscheme" \
    -print0 | xargs -0 rm -rf
  echo -e "${GREEN}✔ Cleanup completed.${RESET}"
}

build() {
  local -a cmd=(
    carthage build "$PACKAGE_NAME"
    --no-skip-current
    --platform iOS
  )
  [[ -n "$LOG_PATH" ]] && cmd+=(--log-path "$LOG_PATH")
  [[ "$USE_XCFRAMEWORKS" = true ]] && cmd+=(--use-xcframeworks)

  echo ""
  echo -e "${CYAN}=======================================${RESET}"
  echo -e "${CYAN}          Carthage Builder             ${RESET}"
  echo -e "${CYAN}=======================================${RESET}"
  echo ""
  echo -e "${BLUE}==>${RESET} Package Name      : ${GREEN}$PACKAGE_NAME${RESET}"
  echo -e "${BLUE}==>${RESET} Log Path          : ${YELLOW}${LOG_PATH:-(default)}${RESET}"
  echo -e "${BLUE}==>${RESET} Use XCFrameworks  : ${GREEN}$USE_XCFRAMEWORKS${RESET}"
  echo ""
  echo -e "${CYAN}---------------------------------------${RESET}"
  echo -e "${BLUE}==>${RESET} Command: ${YELLOW}${cmd[*]}${RESET}"
  echo -e "${CYAN}---------------------------------------${RESET}"
  echo ""

  echo -e "${BLUE}==>${RESET} Starting Carthage build..."
  echo ""
  "${cmd[@]}" | xcbeautify
}

main() {
  parse_args "$@"
  validate_args
  cleanup_xcschemes
  build
}

main "$@"
