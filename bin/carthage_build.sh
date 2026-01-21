#!/bin/bash

# ================================
#   Carthage Build Wrapper
#   Usage:
#     carthage_build --package-name HMAudioKit
#     carthage_build --package-name HMAudioKit --log-path ~/Downloads/build.log
#     carthage_build --package-name HMAudioKit --no-xcframeworks
# ================================

# Colors
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
CYAN="\033[0;36m"
RESET="\033[0m"

PACKAGE_NAME=""
LOG_PATH=""
USE_XCFRAMEWORKS=true   # default enabled

# ------------------------------
# Parse Arguments
# ------------------------------
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

# ------------------------------
# Validation
# ------------------------------
if [[ -z "$PACKAGE_NAME" ]]; then
    echo -e "${RED}✗ Error: --package-name is required${RESET}"
    exit 1
fi

# ------------------------------
# Pre-build Cleanup (新添加的部分)
# ------------------------------
echo -e "${BLUE}==>${RESET} Cleaning up unnecessary xcschemes in Pods..."
find Pods -name '*.xcscheme' \
    '!' -name "${PACKAGE_NAME}.xcscheme" \
    '!' -name "${PACKAGE_NAME}-Unit-Tests.xcscheme" \
    | xargs rm -rf

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✔ Cleanup completed.${RESET}"
else
    echo -e "${YELLOW}⚠ Cleanup skipped or no files found.${RESET}"
fi

echo ""
echo -e "${CYAN}========================================${RESET}"
echo -e "${CYAN}            Carthage Builder            ${RESET}"
echo -e "${CYAN}========================================${RESET}"
echo ""

# ------------------------------
# Build command assembly
# ------------------------------
CMD="carthage build \"$PACKAGE_NAME\" --no-skip-current --platform iOS"

if [[ -n "$LOG_PATH" ]]; then
    CMD="$CMD --log-path \"$LOG_PATH\""
fi

if [[ "$USE_XCFRAMEWORKS" = true ]]; then
    CMD="$CMD --use-xcframeworks"
fi

# ------------------------------
# Display Build Configuration
# ------------------------------
echo -e "${BLUE}==>${RESET} Package Name      : ${GREEN}$PACKAGE_NAME${RESET}"
echo -e "${BLUE}==>${RESET} Log Path          : ${YELLOW}${LOG_PATH:-(default)}${RESET}"
echo -e "${BLUE}==>${RESET} Use XCFrameworks  : ${GREEN}$USE_XCFRAMEWORKS${RESET}"
echo ""
echo -e "${CYAN}----------------------------------------${RESET}"
echo -e "${BLUE}==>${RESET} Command to execute:"
echo -e "    ${YELLOW}$CMD${RESET}"
echo -e "${CYAN}----------------------------------------${RESET}"
echo ""

# ------------------------------
# Execute Build
# ------------------------------
echo -e "${BLUE}==>${RESET} Starting Carthage build..."
echo ""
eval $CMD

STATUS=$?

if [[ $STATUS -eq 0 ]]; then
    echo ""
    echo -e "${GREEN}✔ Build finished successfully!${RESET}"
else
    echo ""
    echo -e "${RED}✘ Build failed (exit code: $STATUS)${RESET}"
fi

echo ""

