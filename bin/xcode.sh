#!/usr/bin/env bash
set -euo pipefail

# =============================================
#   Xcode Utility Script
#   Usage:
#     xcode --cache-clean
#     xcode --help
# =============================================

GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
CYAN="\033[0;36m"
RESET="\033[0m"

show_help() {
  echo ""
  echo -e "${CYAN}============================================${RESET}"
  echo -e "${CYAN}          Xcode Utility Script Help         ${RESET}"
  echo -e "${CYAN}============================================${RESET}"
  echo ""
  echo -e "${YELLOW}Usage:${RESET} xcode [command]"
  echo ""
  echo -e "${YELLOW}Commands:${RESET}"
  echo -e "  ${GREEN}--cache-clean${RESET} : Cleans Xcode's DerivedData and Caches."
  echo -e "  ${GREEN}--help${RESET}        : Displays this help message."
  echo ""
  echo -e "${YELLOW}Example:${RESET}"
  echo -e "  xcode --cache-clean"
  echo ""
}

clean_directory() {
  local dir_path="$1"
  local dir_name="$2"

  echo -e "${BLUE}==>${RESET} Cleaning ${dir_name}: ${YELLOW}$dir_path${RESET}"
  if [[ -d "$dir_path" ]]; then
    /bin/rm -frd "$dir_path"
    echo -e "    ${GREEN}✔ Cleaned ${dir_name}.${RESET}"
  else
    echo -e "    ${YELLOW}Not found, skipping: ${dir_name}${RESET}"
  fi
}

cache_clean() {
  echo ""
  echo -e "${CYAN}============================================${RESET}"
  echo -e "${CYAN}         Starting Xcode Cache Clean         ${RESET}"
  echo -e "${CYAN}============================================${RESET}"
  echo ""

  clean_directory "$HOME/Library/Caches/com.apple.dt.Xcode" "Xcode Caches"
  clean_directory "$HOME/Library/Developer/Xcode/DerivedData" "DerivedData"

  echo ""
  echo -e "${CYAN}--------------------------------------------${RESET}"
  echo -e "${GREEN}✔ Xcode cache cleaning task completed${RESET}"
  echo -e "${CYAN}--------------------------------------------${RESET}"
  echo ""
}

main() {
  if [[ "$#" -eq 0 ]]; then
    show_help
    exit 0
  fi

  while [[ "$#" -gt 0 ]]; do
    case $1 in
      --cache-clean)
        cache_clean
        shift
        ;;
      --help)
        show_help
        shift
        ;;
      *)
        echo -e "${RED}✗ Unknown command:${RESET} $1"
        echo -e "   Use ${GREEN}xcode --help${RESET} for available commands."
        exit 1
        ;;
    esac
  done
}

main "$@"
