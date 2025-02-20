#!/bin/bash
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

func_1_1setup_env(){
    set -e

    BUILD_SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
    BUILD_SCRIPT_DIR="$(dirname "${BUILD_SCRIPT_PATH}")"
    CLIENTSIDE_DIR="$(dirname "${BUILD_SCRIPT_DIR}")"
    DOCKER_DIR="$(dirname "${CLIENTSIDE_DIR}")"
    LIBS_DIR="${DOCKER_DIR}/libs"
    TOP_ROOT_DIR="$(dirname "${DOCKER_DIR}")"
    HANDOVER_DIR="${TOP_ROOT_DIR}/project_handover"
    STAGE5_CONFIG_DIR="${BUILD_SCRIPT_DIR}/configs"
    STAGE5_SCRIPT_DIR="${BUILD_SCRIPT_DIR}/scripts"

    FILE_ENV_PATH="${HANDOVER_DIR}/.env"

    # Load .env file
    source "${FILE_ENV_PATH}"

    source "${LIBS_DIR}/bash_modules/env_opts.sh"

    # Configuration
    DOCKER_IMAGE_NAME="${IMAGE_NAME}"
    DOCKER_IMAGE_TAG="stage5"
}

# Function: Cleanup temporary files
func_1_2_cleanup() {
    echo "Cleaning up temporary files...Doing Nothing Now!"
}

# Function: Build Docker image
func_2_1_build_image() {
    echo "Building final Docker image..."

    # Verify config files exist before build
    if [ ! -f "${STAGE5_CONFIG_DIR}/entrypoint.conf" ] || \
       [ ! -f "${STAGE5_CONFIG_DIR}/workspace.conf" ]; then
        echo "ERROR: Configuration files not found!"
        exit 1
    fi

    docker build \
        --progress=plain \
        --no-cache \
        --network=host \
        --build-arg http_proxy="${http_proxy}"  \
        --build-arg https_proxy="${https_proxy}" \
        --build-arg no_proxy="${no_proxy}" \
        --build-arg HTTP_PROXY="${http_proxy}" \
        --build-arg HTTPS_PROXY="${https_proxy}" \
        --build-arg NO_PROXY="${no_proxy}" \
        --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
        --build-arg VERSION="${PROJECT_VERSION}" \
        --build-arg PROJECT_MAINTAINER="${PROJECT_MAINTAINER}" \
        --build-arg PROJECT_EMAIL="${PROJECT_EMAIL}" \
        --build-arg PROJECT_COPYRIGHT="${PROJECT_COPYRIGHT}" \
        --build-arg PROJECT_LICENSE="${PROJECT_LICENSE}" \
        --build-arg PROJECT_RELEASE_DATE="${PROJECT_RELEASE_DATE}" \
        --build-arg DEV_USERNAME="${DEV_USERNAME}" \
        --build-arg DEV_UID="${DEV_UID}" \
        --build-arg DEV_GID="${DEV_GID}" \
        --build-arg DEV_GROUP="${DEV_GROUP}" \
        --build-arg VOLUMES_ROOT="${VOLUMES_ROOT}" \
        --build-arg WORKSPACE_ROOT="${WORKSPACE_ROOT}" \
        --build-arg WORKSPACE_1ST_SOURCE_SUBDIR="${WORKSPACE_1ST_SOURCE_SUBDIR}" \
        --build-arg WORKSPACE_2ND_BUILD_SUBDIR="${WORKSPACE_2ND_BUILD_SUBDIR}" \
        --build-arg WORKSPACE_3RD_LOGS_SUBDIR="${WORKSPACE_3RD_LOGS_SUBDIR}" \
        --build-arg WORKSPACE_4TH_TEMP_SUBDIR="${WORKSPACE_4TH_TEMP_SUBDIR}" \
        --build-arg WORKSPACE_5TH_DOCS_SUBDIR="${WORKSPACE_5TH_DOCS_SUBDIR}" \
        --build-arg WORKSPACE_6TH_TOOLS_SUBDIR="${WORKSPACE_6TH_TOOLS_SUBDIR}" \
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
        --build-arg CLIENT_SSH_PORT="${CLIENT_SSH_PORT}" \
        --build-arg ENABLE_SYSLOG="${ENABLE_SYSLOG}" \
        --build-arg ENABLE_GDB_SERVER="${ENABLE_GDB_SERVER}" \
        --build-arg GDB_PORT="${GDB_PORT}" \
        --build-arg ENABLE_CORE_DUMPS="${ENABLE_CORE_DUMPS}" \
        --build-arg CORE_PATTERN="${CORE_PATTERN}" \
        --build-arg MAX_FILE_DESCRIPTORS="${MAX_FILE_DESCRIPTORS}" \
        --build-arg MAX_PROCESSES="${MAX_PROCESSES}" \
        --build-arg MEMORY_LIMIT="${MEMORY_LIMIT}" \
        --build-arg IMAGE_NAME="${IMAGE_NAME}" \
        -t "${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}" \
        -f "${BUILD_SCRIPT_DIR}/Dockerfile" \
        "${BUILD_SCRIPT_DIR}" 2>&1 | tee "${BUILD_SCRIPT_DIR}/build_log.txt"

    # check if docker build failed and halt the script if it did
    exit_status=${PIPESTATUS[0]}
    if [ $exit_status -ne 0 ]; then
        echo "In ${BUILD_SCRIPT_PATH}, Docker build failed with exit status: $exit_status"
        exit $exit_status
    fi
}

# Main execution
main() {
    func_1_1setup_env

    # func_utils_process_templates ${FILE_ENV_PATH} ${STAGE5_CONFIG_DIR} ${STAGE5_CONFIG_DIR}
    func_utils_process_templates ${FILE_ENV_PATH} ${STAGE5_SCRIPT_DIR} ${STAGE5_SCRIPT_DIR}

    # Build image
    func_2_1_build_image

    # Cleanup temporary files
    func_1_2_cleanup

    echo "Build completed successfully."
}

# Ensure func_1_2_cleanup runs even if script fails
trap func_1_2_cleanup EXIT

main "$@"