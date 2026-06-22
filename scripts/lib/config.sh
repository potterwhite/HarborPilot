#!/bin/bash
################################################################################
# Module: config.sh
# Description: Configuration management functions for HarborPilot
# Functions: _load_config_layers, _load_layer1_defaults, _load_layer2_platform,
#            _load_layer3_host, _validate_config
################################################################################

################################################################################
# Load all configuration layers (1_defaults, 2_platforms, 3_hosts)
# This function is called from main() after platform/host selection
################################################################################
_load_config_layers() {
    # Layer 1: Global defaults — must be sourced FIRST so later layers
    #          can override individual values
    DEFAULTS_DIR="${TOP_CONFIGS_DIR}/1_defaults"
    for defaults_file in \
        "${DEFAULTS_DIR}/00_project.env" \
        "${DEFAULTS_DIR}/01_base.env" \
        "${DEFAULTS_DIR}/02_build.env" \
        "${DEFAULTS_DIR}/03_tools.env" \
        "${DEFAULTS_DIR}/04_workspace.env" \
        "${DEFAULTS_DIR}/05_registry.env" \
        "${DEFAULTS_DIR}/06_sdk.env" \
        "${DEFAULTS_DIR}/07_volumes.env" \
        "${DEFAULTS_DIR}/08_samba.env" \
        "${DEFAULTS_DIR}/09_runtime.env" \
        "${DEFAULTS_DIR}/11_proxy.env"
    do
        if [ -f "${defaults_file}" ]; then
            source "${defaults_file}"
        else
            echo "Warning: defaults file not found, skipping: ${defaults_file}"
        fi
    done

    # Layer 2 + 3: Host-driven platform resolution
    # If host config declares BASE_PLATFORM, use that to determine the platform.
    # Otherwise fall back to the .env symlink (backward compatibility).
    LOCAL_HOSTNAME=$(hostname)
    HOST_CONFIG="${TOP_CONFIGS_DIR}/3_hosts/${LOCAL_HOSTNAME}.env"

    if [ -f "${HOST_CONFIG}" ]; then
        # Read BASE_PLATFORM without sourcing the whole file
        local base_platform
        base_platform=$(grep -E '^BASE_PLATFORM=' "${HOST_CONFIG}" | head -1 | sed 's/^BASE_PLATFORM=//;s/^"//;s/"$//' | tr -d "'")

        if [ -n "${base_platform}" ]; then
            # New path: platform determined by host config
            local platform_env="${TOP_CONFIGS_DIR}/2_platforms/${base_platform}.env"
            if [ -f "${platform_env}" ]; then
                source "${platform_env}"
                echo "[config] Platform loaded from BASE_PLATFORM: ${base_platform}"
            else
                echo "Error: BASE_PLATFORM='${base_platform}' not found at ${platform_env}"
                echo "       Available platforms:"
                ls -1 "${TOP_CONFIGS_DIR}/2_platforms/"*.env 2>/dev/null | sed 's|.*/||;s|\.env$||' | sed 's/^/         /'
                return 1
            fi
        else
            # Legacy path: platform from .env symlink
            echo "Loading environment variables from ${PLATFORM_ENV_DEST_PATH}"
            source "${PLATFORM_ENV_DEST_PATH}"
        fi

        # Source host config AFTER platform (host overrides platform)
        source "${HOST_CONFIG}"
        echo "[config] Host override loaded: ${HOST_CONFIG}"
    else
        # No host config — use .env symlink (legacy behavior)
        echo "Loading environment variables from ${PLATFORM_ENV_DEST_PATH}"
        source "${PLATFORM_ENV_DEST_PATH}"
        echo "[config] No host-specific config found for ${LOCAL_HOSTNAME}"
    fi

    # Port calculation: auto-derive ports from PORT_SLOT (or validate explicit ports)
    source "${TOP_ROOT_DIR}/scripts/port_calc.sh"
}

################################################################################
# Load Layer 1: Global defaults
# These are the base configuration values that apply to all platforms
################################################################################
_load_layer1_defaults() {
    DEFAULTS_DIR="${TOP_CONFIGS_DIR}/1_defaults"

    for defaults_file in \
        "${DEFAULTS_DIR}/00_project.env" \
        "${DEFAULTS_DIR}/01_base.env" \
        "${DEFAULTS_DIR}/02_build.env" \
        "${DEFAULTS_DIR}/03_tools.env" \
        "${DEFAULTS_DIR}/04_workspace.env" \
        "${DEFAULTS_DIR}/05_registry.env" \
        "${DEFAULTS_DIR}/06_sdk.env" \
        "${DEFAULTS_DIR}/07_volumes.env" \
        "${DEFAULTS_DIR}/08_samba.env" \
        "${DEFAULTS_DIR}/09_runtime.env" \
        "${DEFAULTS_DIR}/11_proxy.env"
    do
        if [ -f "${defaults_file}" ]; then
            source "${defaults_file}"
        else
            echo "Warning: defaults file not found, skipping: ${defaults_file}"
        fi
    done
}

################################################################################
# Load Layer 2: Platform-specific overrides
# These are platform-specific values that override Layer 1 defaults
################################################################################
_load_layer2_platform() {
    if [ -f "${PLATFORM_ENV_DEST_PATH}" ]; then
        echo "Loading environment variables from ${PLATFORM_ENV_DEST_PATH}"
        source "${PLATFORM_ENV_DEST_PATH}"
    else
        echo "Error: Platform config not found at ${PLATFORM_ENV_DEST_PATH}"
        return 1
    fi
}

################################################################################
# Load Layer 3: Host-level overrides
# These are machine-specific values that override Layer 1 and Layer 2
# If host config declares BASE_PLATFORM, platform is auto-resolved.
################################################################################
_load_layer3_host() {
    LOCAL_HOSTNAME=$(hostname)
    HOST_CONFIG="${TOP_CONFIGS_DIR}/3_hosts/${LOCAL_HOSTNAME}.env"

    if [ -f "${HOST_CONFIG}" ]; then
        # Read BASE_PLATFORM without sourcing the whole file
        local base_platform
        base_platform=$(grep -E '^BASE_PLATFORM=' "${HOST_CONFIG}" | head -1 | sed 's/^BASE_PLATFORM=//;s/^"//;s/"$//' | tr -d "'")

        if [ -n "${base_platform}" ]; then
            local platform_env="${TOP_CONFIGS_DIR}/2_platforms/${base_platform}.env"
            if [ -f "${platform_env}" ]; then
                source "${platform_env}"
                echo "[config] Platform loaded from BASE_PLATFORM: ${base_platform}"
            else
                echo "Error: BASE_PLATFORM='${base_platform}' not found at ${platform_env}"
                return 1
            fi
        fi

        source "${HOST_CONFIG}"
        echo "[config] Host override loaded: ${HOST_CONFIG}"
    else
        echo "[config] No host-specific config found for ${LOCAL_HOSTNAME}"
    fi
}

################################################################################
# Validate configuration
# Check that required variables are set and have valid values
################################################################################
_validate_config() {
    local errors=0

    # Check required variables
    if [ -z "${IMAGE_NAME}" ]; then
        echo "Error: IMAGE_NAME is not set"
        ((errors++))
    fi

    if [ -z "${PROJECT_VERSION}" ]; then
        echo "Error: PROJECT_VERSION is not set"
        ((errors++))
    fi

    if [ -z "${PRODUCT_NAME}" ]; then
        echo "Error: PRODUCT_NAME is not set"
        ((errors++))
    fi

    # Check optional but important variables
    if [ -z "${REGISTRY_URL}" ]; then
        echo "Warning: REGISTRY_URL is not set (push will fail)"
    fi

    if [ -z "${HARBOR_SERVER_IP}" ]; then
        echo "Warning: HARBOR_SERVER_IP is not set"
    fi

    # Validate PORT_SLOT if set
    if [ -n "${PORT_SLOT}" ]; then
        if ! [[ "${PORT_SLOT}" =~ ^[0-9]+$ ]]; then
            echo "Error: PORT_SLOT must be a number, got: ${PORT_SLOT}"
            ((errors++))
        fi
    fi

    # Validate USE_NVIDIA_GPU if set
    if [ -n "${USE_NVIDIA_GPU}" ]; then
        if [[ "${USE_NVIDIA_GPU}" != "true" && "${USE_NVIDIA_GPU}" != "false" ]]; then
            echo "Error: USE_NVIDIA_GPU must be 'true' or 'false', got: ${USE_NVIDIA_GPU}"
            ((errors++))
        fi
    fi

    # Validate CONTAINER_SHM_SIZE if set
    if [ -n "${CONTAINER_SHM_SIZE}" ]; then
        if ! [[ "${CONTAINER_SHM_SIZE}" =~ ^[0-9]+[mMgG]$ ]]; then
            echo "Error: CONTAINER_SHM_SIZE must be like '256m' or '1g', got: ${CONTAINER_SHM_SIZE}"
            ((errors++))
        fi
    fi

    # Validate NETWORK_MODE if set
    if [ -n "${NETWORK_MODE}" ]; then
        if [[ "${NETWORK_MODE}" != "bridge" && "${NETWORK_MODE}" != "host" ]]; then
            echo "Error: NETWORK_MODE must be 'bridge' or 'host', got: ${NETWORK_MODE}"
            ((errors++))
        fi
    fi

    # Validate CONTAINER_RESTART_POLICY if set
    if [ -n "${CONTAINER_RESTART_POLICY}" ]; then
        if [[ "${CONTAINER_RESTART_POLICY}" != "no" && "${CONTAINER_RESTART_POLICY}" != "always" && "${CONTAINER_RESTART_POLICY}" != "unless-stopped" && "${CONTAINER_RESTART_POLICY}" != "on-failure" ]]; then
            echo "Error: CONTAINER_RESTART_POLICY must be 'no', 'always', 'unless-stopped', or 'on-failure', got: ${CONTAINER_RESTART_POLICY}"
            ((errors++))
        fi
    fi

    return ${errors}
}
