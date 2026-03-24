#!/bin/bash
################################################################################
# File: docker/dev-env-clientside/build.sh
#
# Description: Build script for the embedded development environment
#              Builds Docker image for all stages and products
#
# Author: PotterWhite
# Created: 2024-11-21
# Last Modified: 2026-03-18
#
# Copyright (c) 2024 [Your Company/Name]
# License: MIT
#
# Three-Layer Config Loading Order:
#   Layer 1: configs/defaults/*.env  — global defaults (all platforms inherit)
#   Layer 2: configs/platform-independent/common.env  — project constants
#   Layer 3: configs/platforms/<platform>.env  — platform-specific overrides
#
# The .env and .env-independent symlinks in project_handover/ still work as
# before; build.sh now also loads all defaults first so platform files only
# need to declare what differs.
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
    CONFIGS_DIR="${TOP_ROOT_DIR}/configs"
    DEFAULTS_DIR="${CONFIGS_DIR}/defaults"
    HANDOVER_DIR="${TOP_ROOT_DIR}/project_handover"
    PLATFORM_ENV_PATH="${HANDOVER_DIR}/.env"
    PLATFORM_INDEPENDENT_ENV_PATH="${HANDOVER_DIR}/.env-independent"

    echo "BUILD_SCRIPT_PATH: ${BUILD_SCRIPT_PATH}"
    echo "BUILD_SCRIPT_DIR:  ${BUILD_SCRIPT_DIR}"
    echo "TOP_ROOT_DIR:      ${TOP_ROOT_DIR}"
    echo "CONFIGS_DIR:       ${CONFIGS_DIR}"
    echo "DEFAULTS_DIR:      ${DEFAULTS_DIR}"
    echo "HANDOVER_DIR:      ${HANDOVER_DIR}"

    # ------------------------------------------------------------------
    # Layer 1: Global defaults — source every file under configs/defaults/
    #          Order: base → build → tools → workspace → registry → sdk
    #                 → volumes → samba → runtime → serverside → proxy
    # ------------------------------------------------------------------
    echo "--- Layer 1: Loading defaults ---"
    for defaults_file in \
        "${DEFAULTS_DIR}/01_base.env" \
        "${DEFAULTS_DIR}/02_build.env" \
        "${DEFAULTS_DIR}/03_tools.env" \
        "${DEFAULTS_DIR}/04_workspace.env" \
        "${DEFAULTS_DIR}/05_registry.env" \
        "${DEFAULTS_DIR}/06_sdk.env" \
        "${DEFAULTS_DIR}/07_volumes.env" \
        "${DEFAULTS_DIR}/08_samba.env" \
        "${DEFAULTS_DIR}/09_runtime.env" \
        "${DEFAULTS_DIR}/10_serverside.env" \
        "${DEFAULTS_DIR}/11_proxy.env"
    do
        if [ -f "${defaults_file}" ]; then
            echo "  source ${defaults_file}"
            source "${defaults_file}"
        else
            echo "  Warning: defaults file not found, skipping: ${defaults_file}"
        fi
    done

    # ------------------------------------------------------------------
    # Layer 2: Project constants (version, maintainer, etc.)
    # ------------------------------------------------------------------
    echo "--- Layer 2: Loading platform-independent common.env ---"
    echo "  PLATFORM_INDEPENDENT_ENV_PATH: ${PLATFORM_INDEPENDENT_ENV_PATH}"
    if [ -e "${PLATFORM_INDEPENDENT_ENV_PATH}" ]; then
        source "${PLATFORM_INDEPENDENT_ENV_PATH}"
    else
        echo "Fatal: ${PLATFORM_INDEPENDENT_ENV_PATH} not found, exit"
        exit 1
    fi

    # ------------------------------------------------------------------
    # Layer 3: Platform-specific overrides (only what differs from defaults)
    # ------------------------------------------------------------------
    echo "--- Layer 3: Loading platform overrides ---"
    echo "  PLATFORM_ENV_PATH: ${PLATFORM_ENV_PATH}"
    if [ -e "${PLATFORM_ENV_PATH}" ]; then
        source "${PLATFORM_ENV_PATH}"
    else
        echo "Fatal: ${PLATFORM_ENV_PATH} not found, exit"
        exit 1
    fi

    # Port calculation: auto-derive ports from PORT_SLOT (or validate explicit ports).
    # Unset any derived port vars that may have been inherited from a parent process
    # (e.g. when harbor sources port_calc.sh and then invokes this script as a
    # subprocess).  Clearing them lets port_calc.sh detect MODE A/B cleanly.
    unset CLIENT_SSH_PORT GDB_PORT
    source "${TOP_ROOT_DIR}/scripts/port_calc.sh"

    BUILD_DATE="$(TZ=$TIMEZONE date +"%Y-%m-%dT%H:%M:%S%z")"

    # ------------------------------------------------------------------
    # Collect final (post-override) variable values as Docker build args.
    # We scan all three layers' files to get the superset of variable names,
    # then read each variable's current (resolved) value from the environment.
    # ------------------------------------------------------------------
    BUILD_ARGS=()
    declare -A _seen_vars  # deduplicate variable names

    all_env_files=(
        "${DEFAULTS_DIR}/01_base.env"
        "${DEFAULTS_DIR}/02_build.env"
        "${DEFAULTS_DIR}/03_tools.env"
        "${DEFAULTS_DIR}/04_workspace.env"
        "${DEFAULTS_DIR}/05_registry.env"
        "${DEFAULTS_DIR}/06_sdk.env"
        "${DEFAULTS_DIR}/07_volumes.env"
        "${DEFAULTS_DIR}/08_samba.env"
        "${DEFAULTS_DIR}/09_runtime.env"
        "${DEFAULTS_DIR}/10_serverside.env"
        "${DEFAULTS_DIR}/11_proxy.env"
        "${PLATFORM_INDEPENDENT_ENV_PATH}"
        "${PLATFORM_ENV_PATH}"
    )

    for file in "${all_env_files[@]}"; do
        if [ -f "$file" ]; then
            while IFS='=' read -r name _; do
                # Skip blank lines, comments, and already-seen vars
                [[ -z "$name" || "$name" =~ ^[[:space:]]*# ]] && continue
                name="${name%%[[:space:]]*}"  # strip trailing whitespace
                [[ -z "$name" ]] && continue
                [[ -n "${_seen_vars[$name]+set}" ]] && continue
                _seen_vars[$name]=1
                value=$(eval echo "\$$name" 2>/dev/null || true)
                if [ -n "$value" ]; then
                    BUILD_ARGS+=(--build-arg "$name=$value")
                fi
            done < "$file"
        else
            echo "警告：文件 $file 不存在，跳过"
        fi
    done

    BUILD_ARGS+=(--build-arg "BUILD_DATE=${BUILD_DATE}")

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