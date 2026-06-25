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
#   Layer 1: configs/1_defaults/*.env  — global defaults (all platforms inherit)
#   Layer 2: configs/2_platforms/<platform>.env  — platform-specific overrides
#   Layer 3: configs/3_hosts/<hostname>.env  — host-level overrides (optional)
################################################################################

func_1_1_setup_env(){
    set -e

    # Get script path and directory
    BUILD_SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
    BUILD_SCRIPT_DIR="$(dirname "${BUILD_SCRIPT_PATH}")"
    CLIENTSIDE_DIR=${BUILD_SCRIPT_DIR}
    DOCKER_DIR="$(dirname "${CLIENTSIDE_DIR}")"
    TOP_ROOT_DIR="$(dirname "${DOCKER_DIR}")"
    CONFIGS_DIR="${TOP_ROOT_DIR}/configs"
    DEFAULTS_DIR="${CONFIGS_DIR}/1_defaults"
    HANDOVER_DIR="${TOP_ROOT_DIR}/project_handover"
    PLATFORM_ENV_PATH="${HANDOVER_DIR}/.env"

    echo "BUILD_SCRIPT_PATH: ${BUILD_SCRIPT_PATH}"
    echo "BUILD_SCRIPT_DIR:  ${BUILD_SCRIPT_DIR}"
    echo "TOP_ROOT_DIR:      ${TOP_ROOT_DIR}"
    echo "CONFIGS_DIR:       ${CONFIGS_DIR}"
    echo "DEFAULTS_DIR:      ${DEFAULTS_DIR}"
    echo "HANDOVER_DIR:      ${HANDOVER_DIR}"

    # ------------------------------------------------------------------
    # Layer 1: Global defaults — source every file under configs/1_defaults/
    #          Order: base → build → tools → workspace → registry → sdk
    #                 → volumes → samba → runtime → serverside → proxy
    # ------------------------------------------------------------------
    echo "--- Layer 1: Loading defaults ---"
    for defaults_file in \
        "${DEFAULTS_DIR}/00_global.env" \
        "${DEFAULTS_DIR}/01_stage_1st_base.env" \
        "${DEFAULTS_DIR}/02_stage_2nd_build.env" \
        "${DEFAULTS_DIR}/03_stage_3rd_sdk.env" \
        "${DEFAULTS_DIR}/04_stage_4th_proxy.env" \
        "${DEFAULTS_DIR}/05_stage_5th_runtime.env"
    do
        if [ -f "${defaults_file}" ]; then
            echo "  source ${defaults_file}"
            source "${defaults_file}"
        else
            echo "  Warning: defaults file not found, skipping: ${defaults_file}"
        fi
    done

    # ------------------------------------------------------------------
    # Layer 2 + 3: Host-driven platform resolution
    # If host config declares BASE_PLATFORM, use that to determine the platform.
    # Otherwise fall back to the .env symlink (backward compatibility).
    # If HOST_CONFIG is already set by the parent process (e.g. ./harbor --host),
    # use it directly instead of re-deriving from hostname.
    # ------------------------------------------------------------------
    if [ -z "${HOST_CONFIG}" ]; then
        LOCAL_HOSTNAME=$(hostname)
        HOST_CONFIG="${CONFIGS_DIR}/3_hosts/${LOCAL_HOSTNAME}.env"
    fi

    if [ -f "${HOST_CONFIG}" ]; then
        # Read BASE_PLATFORM without sourcing the whole file
        base_platform=$(grep -E '^BASE_PLATFORM=' "${HOST_CONFIG}" | head -1 | sed 's/^BASE_PLATFORM=//;s/^"//;s/"$//' | tr -d "'")

        if [ -n "${base_platform}" ]; then
            # New path: platform determined by host config
            platform_env="${CONFIGS_DIR}/2_platforms/${base_platform}.env"
            if [ -f "${platform_env}" ]; then
                source "${platform_env}"
                echo "[config] Platform loaded from BASE_PLATFORM: ${base_platform}"
            else
                echo "Fatal: BASE_PLATFORM='${base_platform}' not found at ${platform_env}"
                exit 1
            fi
        else
            # Legacy path: platform from .env symlink
            echo "--- Layer 2: Loading platform overrides ---"
            echo "  PLATFORM_ENV_PATH: ${PLATFORM_ENV_PATH}"
            if [ -e "${PLATFORM_ENV_PATH}" ]; then
                source "${PLATFORM_ENV_PATH}"
            else
                echo "Fatal: ${PLATFORM_ENV_PATH} not found, exit"
                exit 1
            fi
        fi

        # Source host config AFTER platform (host overrides platform)
        source "${HOST_CONFIG}"
        echo "[config] Host override loaded: ${HOST_CONFIG}"
    else
        # No host config — use .env symlink (legacy behavior)
        echo "--- Layer 2: Loading platform overrides ---"
        echo "  PLATFORM_ENV_PATH: ${PLATFORM_ENV_PATH}"
        if [ -e "${PLATFORM_ENV_PATH}" ]; then
            source "${PLATFORM_ENV_PATH}"
        else
            echo "Fatal: ${PLATFORM_ENV_PATH} not found, exit"
            exit 1
        fi
        echo "[config] No host-specific config found for ${LOCAL_HOSTNAME}"
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
        "${DEFAULTS_DIR}/00_global.env"
        "${DEFAULTS_DIR}/01_stage_1st_base.env"
        "${DEFAULTS_DIR}/02_stage_2nd_build.env"
        "${DEFAULTS_DIR}/03_stage_3rd_sdk.env"
        "${DEFAULTS_DIR}/04_stage_4th_proxy.env"
        "${DEFAULTS_DIR}/05_stage_5th_runtime.env"
        "${PLATFORM_ENV_PATH}"
        "${HOST_CONFIG}"
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
                value="${!name}"
                if [ -n "$value" ]; then
                    BUILD_ARGS+=(--build-arg "$name=$value")
                fi
            done < "$file"
        else
            echo "Warning: file $file not found, skipping"
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

# Cleanup function (no-op: libs/ no longer copied into build context)
func_3_1_cleanup(){
    :
}

main(){
    func_1_1_setup_env "$@"
    func_1_2_preparation
    func_2_1_build_docker_image "$@"
    func_3_1_cleanup
}

main "$@"