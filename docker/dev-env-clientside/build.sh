#!/bin/bash
################################################################################
# File: docker/dev-env-clientside/build.sh
#
# Description: Build script for the embedded development environment
#              Builds Docker image for all stages and products
#
# Author: PotterWhite
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
    PLATFORM_ENV_PATH="${HANDOVER_DIR}/.env"
    PLATFORM_INDEPENDENT_ENV_PATH="${HANDOVER_DIR}/.env-independent"

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
    echo "PLATFORM_INDEPENDENT_ENV_PATH: ${PLATFORM_INDEPENDENT_ENV_PATH}"

    # PLATFORM_INDEPENDENT_ENV_PATH
    if [ -e "${PLATFORM_INDEPENDENT_ENV_PATH}" ] ; then
        source "${PLATFORM_INDEPENDENT_ENV_PATH}"
    else
        echo "Fatal: ${PLATFORM_INDEPENDENT_ENV_PATH} and not found, exit"
        # exit 1
    fi

    echo "PLATFORM_ENV_PATH: ${PLATFORM_ENV_PATH}"
    # PLATFORM_ENV_PATH
    if [ -e "${PLATFORM_ENV_PATH}" ] ; then
        source "${PLATFORM_ENV_PATH}"
    else
        echo "Fatal: ${PLATFORM_ENV_PATH} and not found, using defaults"
        # exit 1
    fi

    BUILD_DATE="$(TZ=$TIMEZONE date +"%Y-%m-%dT%H:%M:%S%z")"

    # Collect all .env variables for build args
    # Note: Only include variables used in Dockerfile
    env_files=("${PLATFORM_INDEPENDENT_ENV_PATH}" "${PLATFORM_ENV_PATH}") # 替换为你的文件路径
    for file in "${env_files[@]}"; do
        if [ -f "$file" ]; then
            while IFS='=' read -r name _; do
                [[ -z "$name" || "$name" =~ ^# ]] && continue
                value=$(eval echo "\$$name")
                if [ -n "$value" ]; then
                    BUILD_ARGS+=(--build-arg "$name=$value")
                fi
            done < "$file"
        else
            echo "警告：文件 $file 不存在，跳过"
        fi
    done

    BUILD_ARGS+=(--build-arg "BUILD_DATE=${BUILD_DATE}")

    ################################
    # BUILD_ARGS=()
    # while IFS='=' read -r name _; do
    #     [[ -z "$name" || "$name" =~ ^# ]] && continue
    #     # Skip if value is empty or not needed in Dockerfile
    #     value=$(eval echo "\$$name")
    #     if [ -n "$value" ]; then
    #         BUILD_ARGS+=(--build-arg "$name=$value")
    #     fi
    # done < "${FILE_ENV_PATH}"

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
        --no-cache \
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