#!/bin/bash

# =============================================
#   Homebrew Package Export Script
#   Usage:
#     brew_export
#     brew_export --output-dir ~/backup/brew
# =============================================

# Colors
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
CYAN="\033[0;36m"
RESET="\033[0m"

# Default export directory
OUTPUT_DIR="$HOME/.config/brew"

# --------------------------------------------------
# Parse Arguments
# --------------------------------------------------
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        *)
            echo -e "${RED}✗ Unknown argument:${RESET} $1"
            exit 1
            ;;
    esac
done

FORMULAE_FILE="$OUTPUT_DIR/brew_formulae.txt"
CASKS_FILE="$OUTPUT_DIR/brew_casks.txt"

echo ""
echo -e "${CYAN}============================================${RESET}"
echo -e "${CYAN}             Homebrew Exporter              ${RESET}"
echo -e "${CYAN}============================================${RESET}"
echo ""

# --------------------------------------------------
# Ensure Directory Exists
# --------------------------------------------------
echo -e "${BLUE}==>${RESET} Output Directory : ${YELLOW}$OUTPUT_DIR${RESET}"

if [[ ! -d "$OUTPUT_DIR" ]]; then
    echo -e "    ${YELLOW}Directory does not exist. Creating...${RESET}"
    mkdir -p "$OUTPUT_DIR"
else
    echo -e "    ${GREEN}Directory exists.${RESET}"
fi

# --------------------------------------------------
# Prepare Output Files
# --------------------------------------------------
prepare_file() {
    local file_path="$1"
    if [[ -f "$file_path" ]]; then
        echo -e "${BLUE}==>${RESET} Removing existing file: ${YELLOW}$file_path${RESET}"
        rm -f "$file_path"
    fi
}

prepare_file "$FORMULAE_FILE"
prepare_file "$CASKS_FILE"

# --------------------------------------------------
# Export Formulae
# --------------------------------------------------
echo ""
echo -e "${BLUE}==>${RESET} Exporting Formulae..."
brew list --formula | sort > "$FORMULAE_FILE"

if [[ $? -eq 0 ]]; then
    echo -e "    ${GREEN}✔ Formulae exported to:${RESET} $FORMULAE_FILE"
else
    echo -e "    ${RED}✘ Failed to export formulae${RESET}"
fi

# --------------------------------------------------
# Export Casks
# --------------------------------------------------
echo ""
echo -e "${BLUE}==>${RESET} Exporting Casks..."
brew list --cask | sort > "$CASKS_FILE"

if [[ $? -eq 0 ]]; then
    echo -e "    ${GREEN}✔ Casks exported to:${RESET} $CASKS_FILE"
else
    echo -e "    ${RED}✘ Failed to export casks${RESET}"
fi

echo ""
echo -e "${CYAN}--------------------------------------------${RESET}"
echo -e "${GREEN}✔ All export tasks completed successfully${RESET}"
echo -e "${CYAN}--------------------------------------------${RESET}"
echo ""

