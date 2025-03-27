#!/bin/bash
# =============================================================================
# Workspace Setup Script
# =============================================================================
# Description: Sets up the development workspace environment and structure
# Author: Your Organization
# Created: 2024-03-19
# Last Modified: 2024-03-19
# Version: 1.0
# =============================================================================

set -e

# Function: Create directory with proper permissions
func_utils_create_directory() {
    local dir_path="$1"
    local dir_owner="$2"
    local dir_perms="$3"

    echo "Creating directory: ${dir_path}"
    if [ -z "${dir_path}" ]; then
        echo "ERROR: Directory path is empty"
        exit 1
    fi

    echo "Parameters:"
    echo "  Path: ${dir_path}"
    echo "  Owner: ${dir_owner}"
    echo "  Permissions: ${dir_perms}"

    mkdir -p "${dir_path}"
    chown "${dir_owner}:${dir_owner}" "${dir_path}"
    chmod "${dir_perms}" "${dir_path}"
}

# Function: Initialize workspace structure
init_workspace() {
    echo "Initializing workspace structure..."

    func_utils_create_directory "/development" "developer" "755"
    # Setup user and group
    chown -R "developer:developer" "/development"

    # Create main directories
    func_utils_create_directory "/development/i_src" "developer" "755"
    func_utils_create_directory "/development/ii_build" "developer" "755"
    func_utils_create_directory "/development/iii_logs" "developer" "755"
    func_utils_create_directory "/development/iv_temp" "developer" "755"

    # Create additional development directories
    func_utils_create_directory "/development/v_docs" "developer" "755"
    func_utils_create_directory "/development/vi_tools" "developer" "755"

    echo "Workspace initialization completed."
}

# Main execution
main() {
    echo -e "\nStarting workspace setup..."
    init_workspace
    echo -e "Workspace setup completed successfully.\n"
}

main "$@"