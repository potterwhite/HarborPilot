#!/bin/bash

# Copyright (c) 2026 Potter White
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

################################################################################
# File: ubuntu_only_entrance.sh
# Description: Container lifecycle manager (start/stop/restart/recreate/remove)
#              This is the single entry point for the handover client.
#              Sources shared functions from scripts/libs/.
################################################################################

set -e
if [ "${V}" == "1" ]; then
    set -x
fi

# Get script directory (resolve symlinks to get the real path)
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

# Source shared libraries
source "${SCRIPT_DIR}/scripts/libs/common/utils.sh"
source "${SCRIPT_DIR}/scripts/libs/common/ui.sh"
source "${SCRIPT_DIR}/scripts/libs/config.sh"
source "${SCRIPT_DIR}/scripts/libs/volumes.sh"
source "${SCRIPT_DIR}/scripts/libs/compose.sh"
source "${SCRIPT_DIR}/scripts/libs/container.sh"

main_show_help() {
    cat << EOF
Usage: $0 [COMMAND]

Commands:
    start     Start development environment
    stop      Stop development environment
    restart   Restart development environment
    recreate  Remove and recreate development environment
    remove    Remove development environment
    -h, --help    Show this help message

Example:
    $0 start     # Start the development environment
EOF
}

################################################################################
# Ensure host config exists (auto-create on first run)
################################################################################
_ensure_host_config() {
    local host_name
    host_name=$(hostname)

    # Check for existing host config (either naming convention)
    for host_file in "${ENTRY_CONFIGS_DIR}/3_hosts/${host_name}"*.env; do
        if [ -f "${host_file}" ]; then
            export HOST_CONFIG="${host_file}"
            return 0
        fi
    done

    # First run — create host config interactively
    # _create_host_config() sets HOST_CONFIG internally
    _create_host_config
}

################################################################################
# main_entry_1st_branch: Setup paths and ensure host config
################################################################################
main_entry_1st_setup() {
    # Setup paths (handover-specific: resolve relative to this script)
    export BUILD_SCRIPT_DIR="${SCRIPT_DIR}"
    export TOP_ROOT_DIR="${SCRIPT_DIR}"
    export TOP_CONFIGS_DIR="${SCRIPT_DIR}/configs"
    export ENTRY_DEFAULTS_DIR="${TOP_CONFIGS_DIR}/1_defaults"
    export ENTRY_CONFIGS_DIR="${TOP_CONFIGS_DIR}"
    export PLATFORM_ENV_SRC_DIR="${TOP_CONFIGS_DIR}/2_platforms"
    # Legacy fallback (only used when host config has no BASE_PLATFORM)
    export PLATFORM_ENV_DEST_PATH="${TOP_CONFIGS_DIR}/2_platforms/.env"

    # Ensure host config exists (first-run interactive)
    _ensure_host_config
}

################################################################################
# main_entry_2nd_branch: Load config layers and derive values
################################################################################
main_entry_2nd_load_config() {
    _load_config_layers

    # Derive FINAL_IMAGE_NAME (not in config.sh — handover-specific)
    if [ "${HAVE_HARBOR_SERVER}" == "TRUE" ]; then
        export FINAL_IMAGE_NAME="${REGISTRY_URL}/${IMAGE_NAME}:latest"
    else
        export FINAL_IMAGE_NAME="${IMAGE_NAME}:latest"
    fi
}

################################################################################
# main_entry_3rd_branch: Start command
################################################################################
main_entry_3rd_cmd_start() {
    main_entry_1st_setup
    main_entry_2nd_load_config
    0_check_registry_login
    volumes_init_if_needed
    container_start_interactive
}

################################################################################
# main_entry_4th_branch: Stop command
################################################################################
main_entry_4th_cmd_stop() {
    main_entry_1st_setup
    main_entry_2nd_load_config
    container_stop
}

################################################################################
# main_entry_5th_branch: Restart command
################################################################################
main_entry_5th_cmd_restart() {
    main_entry_1st_setup
    main_entry_2nd_load_config
    container_restart
}

################################################################################
# main_entry_6th_branch: Recreate command
################################################################################
main_entry_6th_cmd_recreate() {
    main_entry_1st_setup
    main_entry_2nd_load_config
    0_check_registry_login
    volumes_init_if_needed
    container_recreate
}

################################################################################
# main_entry_7th_branch: Remove command
################################################################################
main_entry_7th_cmd_remove() {
    main_entry_1st_setup
    main_entry_2nd_load_config
    container_remove
}

################################################################################
# main_entry: Master router
################################################################################
main_entry() {
    case "$1" in
        "start")
            main_entry_3rd_cmd_start
            ;;
        "stop")
            main_entry_4th_cmd_stop
            ;;
        "restart")
            main_entry_5th_cmd_restart
            ;;
        "recreate")
            main_entry_6th_cmd_recreate
            ;;
        "remove")
            main_entry_7th_cmd_remove
            ;;
        "-h"|"--help"|"")
            main_show_help
            ;;
        *)
            _error "Unknown command: $1"
            main_show_help
            exit 1
            ;;
    esac
}

main_entry "$@"
