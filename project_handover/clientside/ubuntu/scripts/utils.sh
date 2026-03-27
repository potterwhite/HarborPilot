#!/bin/bash

################################################################################
# File: utils.sh
# Description: Common utility functions shared across all modules
################################################################################

# Colors
export UTILS_COLOR_RED='\033[0;31m'
export UTILS_COLOR_GREEN='\033[0;32m'
export UTILS_COLOR_YELLOW='\033[1;33m'
export UTILS_COLOR_BLUE='\033[0;34m'
export UTILS_COLOR_NC='\033[0m'

utils_print_msg() {
    local msg="$1"
    local color="${2:-$UTILS_COLOR_GREEN}"
    echo -e "${color}${msg}${UTILS_COLOR_NC}"
}

utils_print_error() {
    utils_print_msg "ERROR: $1" "${UTILS_COLOR_RED}"
}

utils_print_success() {
    utils_print_msg "SUCCESS: $1" "${UTILS_COLOR_GREEN}"
}

utils_print_warning() {
    utils_print_msg "WARNING: $1" "${UTILS_COLOR_YELLOW}"
}

utils_print_info() {
    utils_print_msg "INFO: $1" "${UTILS_COLOR_BLUE}"
}

utils_prompt_yes_no() {
    local message="$1"
    local default="${3:-Y}"
    local answer
    
    if [ "$default" = "Y" ]; then
        read -p "${message} [Y/n]: " answer
        [[ ! "$answer" =~ ^[Nn]$ ]]
    else
        read -p "${message} [y/N]: " answer
        [[ "$answer" =~ ^[Yy]$ ]]
    fi
}

utils_get_script_dir() {
    local source="${BASH_SOURCE[0]}"
    while [ -h "${source}" ]; do
        local dir="$(cd -P "$(dirname "${source}")" && pwd)"
        source="$(readlink "${source}")"
        [[ "${source}" != /* ]] && source="${dir}/${source}"
    done
    echo "$(cd -P "$(dirname "${source}")" && pwd)"
}
