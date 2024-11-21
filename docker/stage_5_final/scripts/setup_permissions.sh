#!/bin/bash
# =============================================================================
# Permissions Setup Script
# =============================================================================
# Description: Configures user permissions and security settings
# Author: Your Organization
# Created: 2024-03-19
# Last Modified: 2024-03-19
# Version: 1.0
# =============================================================================

set -e

# Source configuration files
source /etc/entrypoint.conf

# Function: Setup system permissions and limits
setup_permissions() {
    echo "Starting permissions setup..."

    # Setup user and group
    echo "Setting up user and group..."
    groupadd -g "${GROUP_ID}" "${DEFAULT_GROUP}" || true
    useradd -u "${USER_ID}" -g "${GROUP_ID}" -m "${DEFAULT_USER}" || true

    # Configure resource limits
    echo "Configuring resource limits..."
    if [ -n "${MAX_FILE_DESCRIPTORS}" ]; then
        echo "Setting max file descriptors to: ${MAX_FILE_DESCRIPTORS}"
        # Move to entrypoint.sh
        # ulimit -n "${MAX_FILE_DESCRIPTORS}"
    fi

    if [ -n "${MAX_PROCESSES}" ]; then
        echo "Setting max processes to: ${MAX_PROCESSES}"
        # Move to entrypoint.sh
        # ulimit -u "${MAX_PROCESSES}"
    fi

    # Configure core dumps
    echo "Configuring core dumps..."
    if [ "${ENABLE_CORE_DUMPS}" = "true" ] && [ -n "${CORE_PATTERN}" ]; then
        echo "Core dumps will be configured at container runtime"
        # Move to entrypoint.sh
        # echo "${CORE_PATTERN}" > /proc/sys/kernel/core_pattern
    fi
}

# Main execution
setup_permissions