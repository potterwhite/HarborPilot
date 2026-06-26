#!/bin/bash

# Copyright (c) 2026 Potter White
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

################################################################################
# File: 01_env_loader.sh
# Description: Environment variable loading (3-layer config system)
#              Source this file before using any environment variables
################################################################################

# =============================================================================
# 1st_group_1st_branch: Path setup
# =============================================================================
env_loader_1st_1st_setup_paths() {
    # Get the entrance script directory (not this script's directory)
    local source="${BASH_SOURCE[0]}"
    while [ -h "${source}" ]; do
        local dir="$(cd -P "$(dirname "${source}")" && pwd)"
        source="$(readlink "${source}")"
        [[ "${source}" != /* ]] && source="${dir}/${source}"
    done
    
    # Get the parent of scripts/ (which is ubuntu/)
    local scripts_dir="$(cd -P "$(dirname "${source}")" && pwd)"
    local ubuntu_dir="$(dirname "${scripts_dir}")"
    
    # Resolve symlinks to get real paths
    local project_handover_dir
    project_handover_dir="$(cd -P "${ubuntu_dir}/../.." && pwd)"
    local top_root_dir
    top_root_dir="$(cd -P "${project_handover_dir}/.." && pwd)"
    
    export BUILD_SCRIPT_DIR="${ubuntu_dir}"
    export TOP_ROOT_DIR="${top_root_dir}"
    export TOP_CONFIGS_DIR="${top_root_dir}/configs"
    export ENTRY_DEFAULTS_DIR="${top_root_dir}/configs/1_defaults"
    export ENTRY_CONFIGS_DIR="${top_root_dir}/configs"
}

# =============================================================================
# 1st_group_2nd_branch: Layer 1 - Global defaults
# =============================================================================
env_loader_1st_2nd_load_defaults() {
    local defaults_files=(
        "${ENTRY_DEFAULTS_DIR}/00_global.env"
        "${ENTRY_DEFAULTS_DIR}/01_stage_1st_base.env"
        "${ENTRY_DEFAULTS_DIR}/02_stage_2nd_build.env"
        "${ENTRY_DEFAULTS_DIR}/03_stage_3rd_sdk.env"
        "${ENTRY_DEFAULTS_DIR}/04_stage_4th_proxy.env"
        "${ENTRY_DEFAULTS_DIR}/05_stage_5th_runtime.env"
    )
    
    for defaults_file in "${defaults_files[@]}"; do
        if [ -f "${defaults_file}" ]; then
            source "${defaults_file}"
        else
            echo "Warning: defaults file not found, skipping: ${defaults_file}"
        fi
    done
}

# =============================================================================
# 1st_group_3rd_branch: Auto-create host config if missing
# =============================================================================
env_loader_1st_3rd_ensure_host_config() {
    local host_name=$(hostname)
    local host_config="${ENTRY_CONFIGS_DIR}/3_hosts/${host_name}.env"
    local template="${ENTRY_CONFIGS_DIR}/3_hosts/TEMPLATE.env.example"

    if [ -f "${host_config}" ]; then
        return 0
    fi

    echo ""
    echo "  ╔══════════════════════════════════════════════════════════════╗"
    echo "  ║           First Run — Auto-creating host config              ║"
    echo "  ╠══════════════════════════════════════════════════════════════╣"
    echo "  ║                                                              ║"
    printf "  ║  Hostname: %-50s║\n" "${host_name}"
    printf "  ║  Config:   %-50s║\n" "$(basename "${host_config}")"
    echo "  ║                                                              ║"
    echo "  ║  Press Enter to accept defaults, or type custom values.      ║"
    echo "  ║                                                              ║"
    echo "  ╚══════════════════════════════════════════════════════════════╝"
    echo ""

    if [ ! -f "${template}" ]; then
        echo "Error: Template not found: ${template}"
        return 1
    fi
    cp "${template}" "${host_config}"

    # Auto-detect BASE_PLATFORM (the only .env in 2_platforms/)
    local platform_file
    platform_file=$(ls "${ENTRY_CONFIGS_DIR}/2_platforms/"*.env 2>/dev/null | head -1)
    if [ -n "${platform_file}" ]; then
        local platform_name
        platform_name=$(basename "${platform_file}" .env)
        sed -i "s|^# BASE_PLATFORM=.*|BASE_PLATFORM=\"${platform_name}\"|" "${host_config}"
        echo "  → Platform: ${platform_name}"
    fi

    # Ask 3 key questions with defaults
    local host_volume_dir
    read -p "  Host volume dir [/opt/harborpilot/volumes]: " host_volume_dir
    host_volume_dir="${host_volume_dir:-/opt/harborpilot/volumes}"
    sed -i "s|^# HOST_VOLUME_DIR=.*|HOST_VOLUME_DIR=\"${host_volume_dir}\"|" "${host_config}"

    local use_gpu
    read -p "  Use NVIDIA GPU? [false]: " use_gpu
    use_gpu="${use_gpu:-false}"
    sed -i "s|^# USE_NVIDIA_GPU=.*|USE_NVIDIA_GPU=\"${use_gpu}\"|" "${host_config}"

    local shm_size
    read -p "  Container SHM size [256m]: " shm_size
    shm_size="${shm_size:-256m}"
    sed -i "s|^# CONTAINER_SHM_SIZE=.*|CONTAINER_SHM_SIZE=\"${shm_size}\"|" "${host_config}"

    echo ""
    echo "  ✅ Host config created: $(basename "${host_config}")"
    echo ""
}

# =============================================================================
# 1st_group_4th_branch: Load all config layers
# Reuses _load_config_layers from scripts/lib/config.sh (shared with SDK).
# Requires TOP_CONFIGS_DIR and TOP_ROOT_DIR to be set by setup_paths.
# =============================================================================
env_loader_1st_4th_load_all_configs() {
    source "${TOP_ROOT_DIR}/scripts/lib/config.sh"
    _load_config_layers
}

# =============================================================================
# 1st_group_6th_branch: Derived values
# =============================================================================
env_loader_1st_6th_derive_values() {
    if [ "${HAVE_HARBOR_SERVER}" == "TRUE" ]; then
        export FINAL_IMAGE_NAME="${REGISTRY_URL}/${IMAGE_NAME}:latest"
    else
        export FINAL_IMAGE_NAME="${IMAGE_NAME}:latest"
    fi
}

# =============================================================================
# 1st_group: Master function - load all environment
# =============================================================================
env_loader_1st_load_all() {
    env_loader_1st_1st_setup_paths
    env_loader_1st_3rd_ensure_host_config
    env_loader_1st_4th_load_all_configs
    env_loader_1st_6th_derive_values
}
