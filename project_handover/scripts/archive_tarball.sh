#!/bin/bash

################################################################################
# File: archive_tarball.sh
# Description: Archive script for project handover package
#              Creates tar archives for different deployment scenarios
# Usage:
#   ./archive_tarball.sh all          # Archive all packages
#   ./archive_tarball.sh client all   # Archive all client packages
#   ./archive_tarball.sh client ubuntu # Archive client ubuntu package
#   ./archive_tarball.sh client windows# Archive client windows package
#   ./archive_tarball.sh server       # Archive server package
################################################################################

set -e

# Get script location
SCRIPT_PATH=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT_PATH)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
DATE_STAMP=$(date +%m.%d.%Y_%H.%M.%S)

###############################################################################
# Function: func_print_usage
# Description: Print usage information for the script
# Arguments: None
# Returns: None
###############################################################################
func_print_usage() {
    echo "Usage: $(basename $0) <type> [platform]"
    echo "  type: 'client/c', 'server/s' or 'all' (case insensitive)"
    echo "  platform: 'ubuntu/u', 'windows/w' or 'all' (required for client type)"
    echo "Examples:"
    echo "  $(basename $0) all            # Archive all packages"
    echo "  $(basename $0) client all     # Archive all client packages"
    echo "  $(basename $0) client ubuntu  # Archive client ubuntu package"
    echo "  $(basename $0) c w            # Archive client windows package"
    echo "  $(basename $0) server         # Archive server package"
}

###############################################################################
# Function: func_normalize_type
# Description: Normalize type argument to standard form
# Arguments:
#   $1 - Type argument (client/c/server/s)
# Returns: Prints normalized type (client/server) or empty if invalid
###############################################################################
func_normalize_type() {
    local input="${1,,}"  # Convert to lowercase
    case "$input" in
        client|c) echo "client" ;;
        server|s) echo "server" ;;
        *) echo "" ;;
    esac
}

###############################################################################
# Function: func_normalize_platform
# Description: Normalize platform argument to standard form
# Arguments:
#   $1 - Platform argument (ubuntu/u/windows/w)
# Returns: Prints normalized platform (ubuntu/windows) or empty if invalid
###############################################################################
func_normalize_platform() {
    local input="${1,,}"  # Convert to lowercase
    case "$input" in
        ubuntu|u) echo "ubuntu" ;;
        windows|w) echo "windows" ;;
        *) echo "" ;;
    esac
}

###############################################################################
# Function: func_validate_args
# Description: Validate command line arguments
# Arguments:
#   $1 - Type argument
#   $2 - Platform argument (optional)
# Returns: 0 if valid, 1 if invalid
###############################################################################
func_validate_args() {
    local type="${1,,}"  # Convert to lowercase

    if [ "$type" = "all" ]; then
        return 0
    fi

    local normalized_type=$(func_normalize_type "$1")
    if [ -z "$normalized_type" ]; then
        echo "Error: Invalid type. Must be 'client/c', 'server/s' or 'all'"
        return 1
    fi

    if [ "$normalized_type" = "client" ]; then
        local platform="${2,,}"
        if [ -z "$2" ]; then
            echo "Error: Client type requires platform (ubuntu/u, windows/w or all)"
            return 1
        elif [ "$platform" != "all" ] && [ -z "$(func_normalize_platform "$2")" ]; then
            echo "Error: Invalid platform. Must be 'ubuntu/u', 'windows/w' or 'all'"
            return 1
        fi
    elif [ "$normalized_type" = "server" ] && [ ! -z "$2" ]; then
        echo "Error: Server type doesn't accept platform argument"
        return 1
    fi

    return 0
}

###############################################################################
# Function: func_archive_client
# Description: Create client archive with specified platform
# Arguments:
#   $1 - Platform (ubuntu/windows)
# Returns: None
###############################################################################
func_archive_client() {
    local platform="$1"
    local archive_name="project_handover_${DATE_STAMP}.tar.gz"

    tar -czf "$archive_name" \
        --transform 's,^,project_handover/,' \
        --exclude='volumes/*' \
        --exclude='!volumes/.gitkeep' \
        --exclude='!volumes/WelcomeToVolumesRoot' \
        -C "$PROJECT_ROOT" \
        .env \
        "clientside/${platform}" \
        "clientside/volumes/.gitkeep" \
        "clientside/volumes/WelcomeToVolumesRoot"
}

###############################################################################
# Function: func_archive_server
# Description: Create server archive
# Arguments: None
# Returns: None
###############################################################################
func_archive_server() {
    local archive_name="project_handover_${DATE_STAMP}.tar.gz"

    tar -czf "$archive_name" \
        --transform 's,^,project_handover/,' \
        -C "$PROJECT_ROOT" \
        .env \
        serverside
}

###############################################################################
# Function: func_archive_all_client
# Description: Create archive with all client platforms
# Arguments: None
# Returns: None
###############################################################################
func_archive_all_client() {
    local archive_name="project_handover_${DATE_STAMP}.tar.gz"

    tar -czf "$archive_name" \
        --transform 's,^,project_handover/,' \
        --exclude='volumes/*' \
        --exclude='!volumes/.gitkeep' \
        --exclude='!volumes/WelcomeToVolumesRoot' \
        -C "$PROJECT_ROOT" \
        .env \
        "clientside/ubuntu" \
        "clientside/windows" \
        "clientside/volumes/.gitkeep" \
        "clientside/volumes/WelcomeToVolumesRoot"
}

###############################################################################
# Function: func_archive_all
# Description: Create archive with all packages
# Arguments: None
# Returns: None
###############################################################################
func_archive_all() {
    local archive_name="project_handover_${DATE_STAMP}.tar.gz"

    tar -czf "$archive_name" \
        --transform 's,^,project_handover/,' \
        --exclude='volumes/*' \
        --exclude='!volumes/.gitkeep' \
        --exclude='!volumes/WelcomeToVolumesRoot' \
        -C "$PROJECT_ROOT" \
        .env \
        "clientside/ubuntu" \
        "clientside/windows" \
        serverside \
        "clientside/volumes/.gitkeep" \
        "clientside/volumes/WelcomeToVolumesRoot"
}

###############################################################################
# Main function
# Description: Main entry point of the script
# Arguments: All command line arguments
# Returns: 0 on success, non-zero on failure
###############################################################################
main() {
    if [ $# -lt 1 ]; then
        func_print_usage
        exit 1
    fi

    # Validate arguments
    if ! func_validate_args "$@"; then
        func_print_usage
        exit 1
    fi

    # Process based on arguments
    case "${1,,}" in
        all)
            func_archive_all
            ;;
        client|c)
            case "${2,,}" in
                all)
                    func_archive_all_client
                    ;;
                *)
                    local platform=$(func_normalize_platform "$2")
                    func_archive_client "$platform"
                    ;;
            esac
            ;;
        server|s)
            func_archive_server
            ;;
    esac

    echo "Archive(s) created successfully!"
    return 0
}

# Execute main function with all script arguments
main "$@"