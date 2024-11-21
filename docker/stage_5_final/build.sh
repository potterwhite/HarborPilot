################################################################################
# File: docker/stage_5_final/build.sh
#
# Description: Build script for stage 5 final integration
#              Handles the building of the final Docker image
#
# Author: ${PROJECT_MAINTAINER}
# Created: 2024-11-21
# Last Modified: 2024-11-21
#
# Copyright (c) 2024 ${PROJECT_COPYRIGHT}
# License: ${PROJECT_LICENSE}
################################################################################

#!/bin/bash
set -e

BUILD_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${BUILD_SCRIPT_DIR}/../../" && pwd)"

# Load .env file
source "${ROOT_DIR}/.env"

# Configuration
DOCKER_IMAGE_NAME="embedded-dev"
DOCKER_IMAGE_TAG="stage5"

# Function: Replace template variables using sed
# Arguments:
#   $1: Template file path
#   $2: Output file path
#   $3: Variable prefix (optional, default: empty)
replace_template_vars() {
    local template_file="$1"
    local output_file="$2"
    local prefix="${3:-}"
    local sed_commands=""

    # Create sed commands for each environment variable
    while IFS='=' read -r name value; do
        # Skip if name contains spaces or is empty
        [[ $name =~ [[:space:]] ]] && continue
        [[ -z $name ]] && continue

        # Add prefix to variable name if specified
        local placeholder_name="${prefix}${name}"

        # Build sed command with proper escaping
        sed_commands="${sed_commands} -e 's|{{${placeholder_name}}}|${value}|g'"
    done < <(env | sort)

    # Execute sed command
    eval "sed ${sed_commands} \"${template_file}\" > \"${output_file}\""
}

# Function: Generate configuration files from templates
generate_configs() {
    echo "=== Generating configuration files from templates ==="

    # Debug: Print all relevant environment variables
    echo "=== Environment Variables ==="
    env | grep -E "^(ENABLE_|DEFAULT_|USER_|GROUP_|SSH_|GDB_|CORE_|MAX_)" || true

    # Function to process a template file
    process_template() {
        local template="$1"
        local output="$2"

        echo "Processing template: $template"
        echo "Output file: $output"

        # Clear output file first
        > "$output"

        # Read template file line by line
        while IFS= read -r line; do
            # Extract variable name between ${ and }
            if [[ $line =~ \$\{([^}]*)\} ]]; then
                var_name="${BASH_REMATCH[1]}"
                var_value="${!var_name}"
                # Debug: Print variable replacement
                echo "Replacing ${var_name} with value: ${var_value:-<empty>}"
                # Replace in the line
                line=${line//\$\{$var_name\}/${var_value:-}}
            fi
            echo "$line" >> "$output"
        done < "$template"
    }

    # Process both config files
    process_template \
        "${BUILD_SCRIPT_DIR}/configs/entrypoint.conf.template" \
        "${BUILD_SCRIPT_DIR}/configs/entrypoint.conf"

    process_template \
        "${BUILD_SCRIPT_DIR}/configs/workspace.conf.template" \
        "${BUILD_SCRIPT_DIR}/configs/workspace.conf"
}

# Function: Cleanup temporary files
cleanup() {
    echo "Cleaning up temporary files..."
    # rm -f "${BUILD_SCRIPT_DIR}/configs/workspace.conf"
    # rm -f "${BUILD_SCRIPT_DIR}/configs/entrypoint.conf"
}

# Function: Build Docker image
build_image() {
    echo "Building final Docker image..."

    # Verify config files exist before build
    if [ ! -f "${BUILD_SCRIPT_DIR}/configs/entrypoint.conf" ] || \
       [ ! -f "${BUILD_SCRIPT_DIR}/configs/workspace.conf" ]; then
        echo "ERROR: Configuration files not found!"
        exit 1
    fi

    docker build \
        --progress=plain \
        --no-cache \
        --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
        --build-arg VERSION="${PROJECT_VERSION}" \
        --build-arg PROJECT_MAINTAINER="${PROJECT_MAINTAINER}" \
        --build-arg PROJECT_EMAIL="${PROJECT_EMAIL}" \
        --build-arg PROJECT_COPYRIGHT="${PROJECT_COPYRIGHT}" \
        --build-arg PROJECT_LICENSE="${PROJECT_LICENSE}" \
        --build-arg DEV_USERNAME="${DEV_USERNAME}" \
        --build-arg DEV_UID="${DEV_UID}" \
        --build-arg DEV_GID="${DEV_GID}" \
        --build-arg DEV_GROUP="${DEV_GROUP}" \
        --build-arg WORKSPACE_ROOT="${WORKSPACE_ROOT}" \
        --build-arg WORKSPACE_SOURCE_DIR="${WORKSPACE_SOURCE_DIR}" \
        --build-arg WORKSPACE_BUILD_DIR="${WORKSPACE_BUILD_DIR}" \
        --build-arg WORKSPACE_LOGS_DIR="${WORKSPACE_LOGS_DIR}" \
        --build-arg WORKSPACE_TEMP_DIR="${WORKSPACE_TEMP_DIR}" \
        --build-arg WORKSPACE_DEFAULT_PROJECT_NAME="${WORKSPACE_DEFAULT_PROJECT_NAME}" \
        --build-arg WORKSPACE_DEFAULT_BUILD_TYPE="${WORKSPACE_DEFAULT_BUILD_TYPE}" \
        --build-arg WORKSPACE_BUILD_THREADS="${WORKSPACE_BUILD_THREADS}" \
        --build-arg WORKSPACE_ENABLE_AUTO_SAVE="${WORKSPACE_ENABLE_AUTO_SAVE}" \
        --build-arg WORKSPACE_ENABLE_ERROR_REPORTING="${WORKSPACE_ENABLE_ERROR_REPORTING}" \
        --build-arg WORKSPACE_LOG_LEVEL="${WORKSPACE_LOG_LEVEL}" \
        --build-arg WORKSPACE_ENABLE_VSC_INTEGRATION="${WORKSPACE_ENABLE_VSC_INTEGRATION}" \
        --build-arg WORKSPACE_ENABLE_REMOTE_DEBUG="${WORKSPACE_ENABLE_REMOTE_DEBUG}" \
        --build-arg WORKSPACE_DEBUG_PORT="${WORKSPACE_DEBUG_PORT}" \
        --build-arg ENABLE_SSH="${ENABLE_SSH}" \
        --build-arg SSH_PORT="${SSH_PORT}" \
        --build-arg ENABLE_SYSLOG="${ENABLE_SYSLOG}" \
        --build-arg ENABLE_GDB_SERVER="${ENABLE_GDB_SERVER}" \
        --build-arg GDB_PORT="${GDB_PORT}" \
        --build-arg ENABLE_CORE_DUMPS="${ENABLE_CORE_DUMPS}" \
        --build-arg CORE_PATTERN="${CORE_PATTERN}" \
        --build-arg MAX_FILE_DESCRIPTORS="${MAX_FILE_DESCRIPTORS}" \
        --build-arg MAX_PROCESSES="${MAX_PROCESSES}" \
        --build-arg MEMORY_LIMIT="${MEMORY_LIMIT}" \
        -t "${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}" \
        -f "${BUILD_SCRIPT_DIR}/Dockerfile" \
        "${BUILD_SCRIPT_DIR}" 2>&1 | tee build_log.txt
}

# Main execution
main() {
    echo -e "build_script_dir: ${BUILD_SCRIPT_DIR}\n"
    echo -e "root_dir: ${ROOT_DIR}\n"

    # Generate configs from templates
    generate_configs

    # List files in configs directory
    echo "=== Files in configs directory ==="
    ls -la "${BUILD_SCRIPT_DIR}/configs/"
    echo "================================="

    # Build image
    build_image

    # Cleanup temporary files
    cleanup

    echo "Build completed successfully."
}

# Ensure cleanup runs even if script fails
trap cleanup EXIT

main "$@"