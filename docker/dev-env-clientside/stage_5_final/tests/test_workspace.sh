################################################################################
# File: docker/stage_5_final/tests/test_workspace.sh
#
# Description: Test script for workspace setup verification
#              Validates workspace directory structure and permissions
#
# Author: MrJamesLZAZ
# Created: 2024-11-21
# Last Modified: 2024-11-21
#
# Copyright (c) 2024 [Your Company/Name]
# License: MIT
################################################################################

#!/bin/bash
set -e

# Source configuration
source /etc/workspace.conf

# Test workspace directory structure
test_workspace_structure() {
    echo "Testing workspace directory structure..."
    for dir in "${SOURCE_DIR}" "${BUILD_DIR}" "${LOGS_DIR}" "${TEMP_DIR}"; do
        if [ ! -d "$dir" ]; then
            echo "ERROR: Directory $dir does not exist"
            exit 1
        fi
    done
}

# Main execution
main() {
    test_workspace_structure
    echo "All workspace tests passed successfully."
}

main "$@"