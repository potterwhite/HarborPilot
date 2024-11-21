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

# Source configuration files
source /etc/workspace.conf
source /etc/entrypoint.conf

# Function: Create directory with proper permissions
create_directory() {
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

    # Create main directories
    create_directory "${SOURCE_DIR}" "${DEFAULT_USER}" "755"
    create_directory "${BUILD_DIR}" "${DEFAULT_USER}" "755"
    create_directory "${LOGS_DIR}" "${DEFAULT_USER}" "755"
    create_directory "${TEMP_DIR}" "${DEFAULT_USER}" "755"

    # Create additional development directories
    create_directory "${WORKSPACE_ROOT}/tools" "${DEFAULT_USER}" "755"
    create_directory "${WORKSPACE_ROOT}/docs" "${DEFAULT_USER}" "755"

    echo "Workspace initialization completed."
}

# Function: Setup development environment
setup_dev_environment() {
    echo "Setting up development environment..."

    # Setup VSCode integration
    if [ "${ENABLE_VSC_INTEGRATION}" = true ]; then
        mkdir -p "${WORKSPACE_ROOT}/.vscode"
    fi

    # Configure remote debugging
    if [ "${ENABLE_REMOTE_DEBUG}" = true ]; then
        echo "Configuring remote debugging on port ${GDB_PORT}"
    fi

    # echo "Workspace setup completed successfully."
}

# Main execution
main() {
    echo -e "\nStarting workspace setup..."
    init_workspace
    setup_dev_environment
    echo -e "Workspace setup completed successfully.\n"
}

main "$@"