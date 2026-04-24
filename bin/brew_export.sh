#!/usr/bin/env bash
set -euo pipefail

# =============================================
#   Homebrew Package Export Script
#   Usage:
#     brew_export
#     brew_export --output-dir ~/backup/brew
# =============================================

GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
CYAN="\033[0;36m"
RESET="\033[0m"

OUTPUT_DIR=""

parse_args() {
  OUTPUT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/brew"

  while [[ "$#" -gt 0 ]]; do
    case $1 in
      --output-dir)
        OUTPUT_DIR="$2"
        shift 2
        ;;
      -h|--help)
        echo "Usage: brew_export [--output-dir <path>]"
        exit 0
        ;;
      *)
        echo -e "${RED}✗ Unknown argument:${RESET} $1"
        exit 1
        ;;
    esac
  done
}

prepare_file() {
  local file_path="$1"
  [[ -f "$file_path" ]] && rm -f "$file_path"
}

export_formulae() {
  local out="$1"
  echo -e "${BLUE}==>${RESET} Exporting Formulae..."
  brew list --formula | sort > "$out"
  echo -e "    ${GREEN}✔ Saved to:${RESET} $out"
}

export_casks() {
  local out="$1"
  echo -e "${BLUE}==>${RESET} Exporting Casks..."
  brew list --cask | sort > "$out"
  echo -e "    ${GREEN}✔ Saved to:${RESET} $out"
}

main() {
  parse_args "$@"

  local formulae_file="${OUTPUT_DIR}/brew_formulae.txt"
  local casks_file="${OUTPUT_DIR}/brew_casks.txt"

  echo ""
  echo -e "${CYAN}============================================${RESET}"
  echo -e "${CYAN}             Homebrew Exporter              ${RESET}"
  echo -e "${CYAN}============================================${RESET}"
  echo ""

  echo -e "${BLUE}==>${RESET} Output Directory: ${YELLOW}$OUTPUT_DIR${RESET}"
  mkdir -p "$OUTPUT_DIR"

  prepare_file "$formulae_file"
  prepare_file "$casks_file"

  echo ""
  export_formulae "$formulae_file"
  echo ""
  export_casks "$casks_file"

  echo ""
  echo -e "${CYAN}--------------------------------------------${RESET}"
  echo -e "${GREEN}✔ Export completed${RESET}"
  echo -e "${CYAN}--------------------------------------------${RESET}"
  echo ""
}

main "$@"
