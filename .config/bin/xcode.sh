#!/bin/bash

# =============================================
#   Xcode Utility Script
#   Usage:
#     xcode --cache-clean
#     xcode --help
# =============================================

# Colors
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
CYAN="\033[0;36m"
RESET="\033[0m"

# --------------------------------------------------
# Help Function
# --------------------------------------------------
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

# --------------------------------------------------
# Cache Clean Function
# --------------------------------------------------
cache_clean() {
    echo ""
    echo -e "${CYAN}============================================${RESET}"
    echo -e "${CYAN}         Starting Xcode Cache Clean         ${RESET}"
    echo -e "${CYAN}============================================${RESET}"
    echo ""

    # Directories to clean
    CACHE_DIR="$HOME/Library/Caches/com.apple.dt.Xcode"
    DERIVED_DATA_DIR="$HOME/Library/Developer/Xcode/DerivedData"

    # Function to clean a directory
    clean_directory() {
        local dir_path="$1"
        local dir_name="$2"

        echo -e "${BLUE}==>${RESET} Attempting to clean ${dir_name}: ${YELLOW}$dir_path${RESET}"
        
        if [[ -d "$dir_path" ]]; then
            # Using find and -delete for potentially safer deletion, or a direct rm -rf
            # For simplicity and direct user request, we use the rm command here.
            /bin/rm -frd "$dir_path"
            
            if [[ $? -eq 0 ]]; then
                echo -e "    ${GREEN}✔ Successfully cleaned ${dir_name}.${RESET}"
            else
                echo -e "    ${RED}✘ Failed to clean ${dir_name}.${RESET}"
                return 1
            fi
        else
            echo -e "    ${YELLOW}Directory not found, skipping: ${dir_name}${RESET}"
        fi
        return 0
    }

    # Clean Caches
    clean_directory "$CACHE_DIR" "Xcode Caches"

    # Clean DerivedData
    clean_directory "$DERIVED_DATA_DIR" "DerivedData"

    echo ""
    echo -e "${CYAN}--------------------------------------------${RESET}"
    echo -e "${GREEN}✔ Xcode cache cleaning task completed${RESET}"
    echo -e "${CYAN}--------------------------------------------${RESET}"
    echo ""
}

# --------------------------------------------------
# Parse Arguments
# --------------------------------------------------
# Default to showing help if no arguments are provided
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

exit 0