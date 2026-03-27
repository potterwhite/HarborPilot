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
    export ENTRY_ENV_PATH="${project_handover_dir}/.env"
    export ENTRY_ENV_INDEPENDENT_PATH="${project_handover_dir}/.env-independent"
    export ENTRY_DEFAULTS_DIR="${top_root_dir}/configs/defaults"
}

# =============================================================================
# 1st_group_2nd_branch: Layer 1 - Global defaults
# =============================================================================
env_loader_1st_2nd_load_defaults() {
    local defaults_files=(
        "${ENTRY_DEFAULTS_DIR}/01_base.env"
        "${ENTRY_DEFAULTS_DIR}/02_build.env"
        "${ENTRY_DEFAULTS_DIR}/03_tools.env"
        "${ENTRY_DEFAULTS_DIR}/04_workspace.env"
        "${ENTRY_DEFAULTS_DIR}/05_registry.env"
        "${ENTRY_DEFAULTS_DIR}/06_sdk.env"
        "${ENTRY_DEFAULTS_DIR}/07_volumes.env"
        "${ENTRY_DEFAULTS_DIR}/08_samba.env"
        "${ENTRY_DEFAULTS_DIR}/09_runtime.env"
        "${ENTRY_DEFAULTS_DIR}/10_serverside.env"
        "${ENTRY_DEFAULTS_DIR}/11_proxy.env"
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
# 1st_group_3rd_branch: Layer 2 - Project constants
# =============================================================================
env_loader_1st_3rd_load_independent() {
    if [ -f "${ENTRY_ENV_INDEPENDENT_PATH}" ]; then
        source "${ENTRY_ENV_INDEPENDENT_PATH}"
    fi
}

# =============================================================================
# 1st_group_4th_branch: Layer 3 - Platform-specific overrides
# =============================================================================
env_loader_1st_4th_load_platform() {
    if [ -f "${ENTRY_ENV_PATH}" ]; then
        source "${ENTRY_ENV_PATH}"
        echo -e "Done source .env\n"
    else
        echo -e "\nNo ${ENTRY_ENV_PATH} exist, quit"
        exit 1
    fi
}

# =============================================================================
# 1st_group_5th_branch: Port calculation
# =============================================================================
env_loader_1st_5th_calc_ports() {
    source "${TOP_ROOT_DIR}/scripts/port_calc.sh"
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
    env_loader_1st_2nd_load_defaults
    env_loader_1st_3rd_load_independent
    env_loader_1st_4th_load_platform
    env_loader_1st_5th_calc_ports
    env_loader_1st_6th_derive_values
}
