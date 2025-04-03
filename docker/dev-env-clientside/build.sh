#!/bin/bash
################################################################################
# File: docker/dev-env-clientside/build.sh
#
# Description: Build script for the embedded development environment
#              Builds Docker image for all stages and products
#
# Author: MrJamesLZAZ
# Created: 2024-11-21
# Last Modified: 2025-02-21
#
# Copyright (c) 2024 [Your Company/Name]
# License: MIT
################################################################################

func_1_1_setup_env(){
    set -e

    # Get script path and directory
    BUILD_SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
    BUILD_SCRIPT_DIR="$(dirname "${BUILD_SCRIPT_PATH}")"
    CLIENTSIDE_DIR=${BUILD_SCRIPT_DIR}
    DOCKER_DIR="$(dirname "${CLIENTSIDE_DIR}")"
    LIBS_DIR="${DOCKER_DIR}/libs"
    PRODUCT_SPECIFIC_DIR="${LIBS_DIR}/i_product-specific"
    CONFIG_DIR="${LIBS_DIR}/iii_configs"
    SCRIPT_DIR="${LIBS_DIR}/iv_scripts"
    UTILS_DIR="${LIBS_DIR}/v_utils"
    TOP_ROOT_DIR="$(dirname "${DOCKER_DIR}")"
    HANDOVER_DIR="${TOP_ROOT_DIR}/project_handover"

    echo "BUILD_SCRIPT_PATH: ${BUILD_SCRIPT_PATH}"
    echo "BUILD_SCRIPT_DIR: ${BUILD_SCRIPT_DIR}"
    echo "CLIENTSIDE_DIR: ${CLIENTSIDE_DIR}"
    echo "DOCKER_DIR: ${DOCKER_DIR}"
    echo "LIBS_DIR: ${LIBS_DIR}"
    echo "PRODUCT_SPECIFIC_DIR: ${PRODUCT_SPECIFIC_DIR}"
    echo "CONFIG_DIR: ${CONFIG_DIR}"
    echo "SCRIPT_DIR: ${SCRIPT_DIR}"
    echo "UTILS_DIR: ${UTILS_DIR}"
    echo "TOP_ROOT_DIR: ${TOP_ROOT_DIR}"
    echo "HANDOVER_DIR: ${HANDOVER_DIR}"

    FILE_ENV_PATH="${HANDOVER_DIR}/.env"
    echo "FILE_ENV_PATH: ${FILE_ENV_PATH}"
    # Source .env file if exists, otherwise use defaults
    if [ -f "${FILE_ENV_PATH}" ]; then
        source "${FILE_ENV_PATH}"
    else
        echo "Warning: .env not found, using defaults"
    fi

    # # Default product type (can be overridden via command line)
    # PRODUCT=${1:-$PRODUCT_TYPE}
    # if [ -z "$PRODUCT" ]; then
    #     PRODUCT="generic"
    # fi

    # # Define image name (example, adjust as needed)
    # IMAGE_NAME=${IMAGE_NAME:-${PRODUCT}-dev-env}

    # Collect all .env variables for build args
    # Note: Only include variables used in Dockerfile
    BUILD_ARGS=()
    while IFS='=' read -r name _; do
        [[ -z "$name" || "$name" =~ ^# ]] && continue
        # Skip if value is empty or not needed in Dockerfile
        value=$(eval echo "\$$name")
        if [ -n "$value" ]; then
            BUILD_ARGS+=(--build-arg "$name=$value")
        fi
    done < "${FILE_ENV_PATH}"

    # Add additional build options
    BUILD_ARGS+=(
        --progress=plain
        --network=host
        --no-cache
    )

    echo "......BUILD_ARGS: ${BUILD_ARGS[@]}"
}

func_1_2_preparation(){
    # # Create temporary directory structure
    # echo "Creating temporary directory structure..."
    # mkdir -p "${BUILD_SCRIPT_DIR}/libs/iv_scripts"

    # # Copy the required files
    # echo "Copying setup_base.sh..."
    # cp -rfav "${LIBS_DIR}" "${BUILD_SCRIPT_DIR}/"

    # # Verify the copy
    # if [ ! -f "${BUILD_SCRIPT_DIR}/libs/iv_scripts/setup_base.sh" ]; then
    #     echo "Error: Failed to copy setup_base.sh"
    #     exit 1
    # fi
    echo
}

func_2_1_build_docker_image(){
    # Build the Docker image
    echo "Building ${IMAGE_NAME}:${PROJECT_VERSION}..."
    docker build \
        "${BUILD_ARGS[@]}" \
        -t "${IMAGE_NAME}:${PROJECT_VERSION}" \
        -f "${BUILD_SCRIPT_DIR}/Dockerfile" \
        "${BUILD_SCRIPT_DIR}" 2>&1 | tee "${BUILD_SCRIPT_DIR}/build_log.txt"

    # Check if docker build failed and halt the script if it did
    exit_status=${PIPESTATUS[0]}
    if [ $exit_status -ne 0 ]; then
        echo "In ${BUILD_SCRIPT_PATH}, Docker build failed with exit status: $exit_status"
        exit $exit_status
    fi
}

# Add cleanup function
func_3_1_cleanup(){
    echo "Cleaning up temporary files..."
    rm -rf "${BUILD_SCRIPT_DIR}/libs"
}

main(){
    func_1_1_setup_env "$@"
    func_1_2_preparation
    func_2_1_build_docker_image "$@"
    func_3_1_cleanup
}

main "$@"