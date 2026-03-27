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
#              This is the single entry point - all logic is in scripts/*.sh
################################################################################

set -e
if [ "${V}" == "1" ]; then
    set -x
fi

# Get script directory (works both when sourced and executed)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/scripts/utils.sh"

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
# main_entry_1st_branch: Load all modules (prerequisite for all commands)
################################################################################
main_entry_1st_load_modules() {
    source "${SCRIPT_DIR}/scripts/01_env_loader.sh"
    source "${SCRIPT_DIR}/scripts/02_docker_check.sh"
    source "${SCRIPT_DIR}/scripts/03_volumes_init.sh"
    source "${SCRIPT_DIR}/scripts/04_compose_generator.sh"
    source "${SCRIPT_DIR}/scripts/05_container_lifecycle.sh"
}

################################################################################
# main_entry_2nd_branch: Start command
################################################################################
main_entry_2nd_cmd_start() {
    main_entry_1st_load_modules
    
    env_loader_1st_load_all
    docker_check_2nd_do_checks
    volumes_init_3rd_init_if_needed
    container_lifecycle_5th_9th_start_interactive
}

################################################################################
# main_entry_3rd_branch: Stop command
################################################################################
main_entry_3rd_cmd_stop() {
    main_entry_1st_load_modules
    
    env_loader_1st_load_all
    container_lifecycle_5th_stop
}

################################################################################
# main_entry_4th_branch: Restart command
################################################################################
main_entry_4th_cmd_restart() {
    main_entry_1st_load_modules
    
    env_loader_1st_load_all
    container_lifecycle_5th_restart
}

################################################################################
# main_entry_5th_branch: Recreate command
################################################################################
main_entry_5th_cmd_recreate() {
    main_entry_1st_load_modules
    
    env_loader_1st_load_all
    container_lifecycle_5th_recreate
}

################################################################################
# main_entry_6th_branch: Remove command
################################################################################
main_entry_6th_cmd_remove() {
    main_entry_1st_load_modules
    
    env_loader_1st_load_all
    container_lifecycle_5th_remove
}

################################################################################
# main_entry: Master router
################################################################################
main_entry() {
    case "$1" in
        "start")
            main_entry_2nd_cmd_start
            ;;
        "stop")
            main_entry_3rd_cmd_stop
            ;;
        "restart")
            main_entry_4th_cmd_restart
            ;;
        "recreate")
            main_entry_5th_cmd_recreate
            ;;
        "remove")
            main_entry_6th_cmd_remove
            ;;
        "-h"|"--help"|"")
            main_entry_1st_load_modules
            main_show_help
            ;;
        *)
            utils_print_error "Unknown command: $1"
            main_entry_1st_load_modules
            main_show_help
            exit 1
            ;;
    esac
}

main_entry "$@"
