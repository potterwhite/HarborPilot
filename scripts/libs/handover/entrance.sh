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
# File: entrance.sh
# Description: Container lifecycle manager (start/stop/restart/recreate/remove)
#              This is the single entry point for the handover client.
#              Sources shared functions from scripts/libs/.
################################################################################

set -e
if [ "${V}" == "1" ]; then
    set -x
fi

# Get script directory (resolve symlinks to get the real path)
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

# Source shared libraries
source "${SCRIPT_DIR}/scripts/libs/common/utils.sh"
source "${SCRIPT_DIR}/scripts/libs/common/ui.sh"
source "${SCRIPT_DIR}/scripts/libs/config.sh"
source "${SCRIPT_DIR}/scripts/libs/volumes.sh"
source "${SCRIPT_DIR}/scripts/libs/compose.sh"
source "${SCRIPT_DIR}/scripts/libs/container.sh"

main_show_help() {
    cat << EOF
Usage: $0 [COMMAND] [OPTIONS]

Commands:
    start     Start development environment
    stop      Stop development environment
    restart   Restart development environment
    recreate  Remove and recreate development environment
    remove    Remove development environment

Options (for non-interactive first-run host config creation):
    --platform <name>       Base platform (e.g. rk3588-rk3588s_ubuntu-22.04)
    --volume <path>         Host volume directory
    --harbor-ip <ip>        Harbor server IP
    --harbor-port <port>    Harbor server port
    --gitlab                Enable GitLab server (default: no)
    --gitlab-ip <ip>        GitLab server IP (default: same as harbor-ip)
    --gitlab-port <port>    GitLab server port
    --proxy                 Enable proxy (default: no)
    --http-proxy-ip <ip>    HTTP proxy IP (default: same as harbor-ip)
    --https-proxy-ip <ip>   HTTPS proxy IP (default: same as http-proxy-ip)
    --gpu                   Enable NVIDIA GPU (default: no)
    --shm <size>            SHM size (default: 256m, or 1g with GPU)
    --network <mode>        Network mode: host or bridge (default: host)
    --restart <policy>      Restart policy (default: unless-stopped)
    --cuda                  Install CUDA toolkit (default: no)
    --opencv                Install OpenCV (default: no)
    --npm-china-mirror      Use npm China mirror (default: no)
    -h, --help              Show this help message

Examples:
    $0 start                                          # Interactive (wizard on first run)
    $0 start --platform rk3588-rk3588s_ubuntu-22.04 \\
        --harbor-ip 192.168.3.67 --volume /mnt/ssd/docker-volumes/project
EOF
}

################################################################################
# Create host config non-interactively from CLI arguments
################################################################################
_create_host_config_non_interactive() {
    local TEMPLATE="${TOP_CONFIGS_DIR}/3_hosts/TEMPLATE.env.example"
    local host_name
    host_name=$(hostname)
    HOST_CONFIG="${TOP_CONFIGS_DIR}/3_hosts/${host_name}_${NI_PLATFORM}.env"

    if [[ ! -f "${TEMPLATE}" ]]; then
        echo "  ✗ Error: Template not found: ${TEMPLATE}"
        return 1
    fi
    cp "${TEMPLATE}" "${HOST_CONFIG}"

    # Load Layer 1 defaults + platform config
    _load_layer1_defaults
    local platform_env="${TOP_CONFIGS_DIR}/2_platforms/${NI_PLATFORM}.env"
    if [ -f "${platform_env}" ]; then
        source "${platform_env}"
    fi

    # Apply CLI args (use provided value or fall back to loaded default)
    local harbor_ip="${NI_HARBOR_IP:-${HARBOR_SERVER_IP}}"
    local harbor_port="${NI_HARBOR_PORT:-${HARBOR_SERVER_PORT}}"
    local volume_dir="${NI_VOLUME:-${BUILD_SCRIPT_DIR}/volume}"

    sed -i "s|^# BASE_PLATFORM=.*|BASE_PLATFORM=\"${NI_PLATFORM}\"|" "${HOST_CONFIG}"
    sed -i "s|^# HOST_VOLUME_DIR=.*|HOST_VOLUME_DIR=\"${volume_dir}\"|" "${HOST_CONFIG}"
    sed -i "s|^# HARBOR_SERVER_IP=.*|HARBOR_SERVER_IP=\"${harbor_ip}\"|" "${HOST_CONFIG}"
    sed -i "s|^# HARBOR_SERVER_PORT=.*|HARBOR_SERVER_PORT=\"${harbor_port}\"|" "${HOST_CONFIG}"
    sed -i "s|^# USE_NVIDIA_GPU=.*|USE_NVIDIA_GPU=\"${NI_GPU:-false}\"|" "${HOST_CONFIG}"
    sed -i "s|^# CONTAINER_SHM_SIZE=.*|CONTAINER_SHM_SIZE=\"${NI_SHM:-256m}\"|" "${HOST_CONFIG}"
    sed -i "s|^# NETWORK_MODE=.*|NETWORK_MODE=\"${NI_NETWORK:-host}\"|" "${HOST_CONFIG}"
    sed -i "s|^# CONTAINER_RESTART_POLICY=.*|CONTAINER_RESTART_POLICY=\"${NI_RESTART:-unless-stopped}\"|" "${HOST_CONFIG}"
    sed -i "s|^# HAVE_GITLAB_SERVER=.*|HAVE_GITLAB_SERVER=\"${NI_GITLAB:-FALSE}\"|" "${HOST_CONFIG}"
    if [[ "${NI_GITLAB:-FALSE}" == "TRUE" ]]; then
        sed -i "s|^# GITLAB_SERVER_IP=.*|GITLAB_SERVER_IP=\"${NI_GITLAB_IP:-${harbor_ip}}\"|" "${HOST_CONFIG}"
        sed -i "s|^# GITLAB_SERVER_PORT=.*|GITLAB_SERVER_PORT=\"${NI_GITLAB_PORT:-80}\"|" "${HOST_CONFIG}"
    fi
    sed -i "s|^# HAS_PROXY=.*|HAS_PROXY=\"${NI_PROXY:-false}\"|" "${HOST_CONFIG}"
    if [[ "${NI_PROXY:-false}" == "true" ]]; then
        sed -i "s|^# HTTP_PROXY_IP=.*|HTTP_PROXY_IP=\"${NI_HTTP_PROXY_IP:-${harbor_ip}}\"|" "${HOST_CONFIG}"
        sed -i "s|^# HTTPS_PROXY_IP=.*|HTTPS_PROXY_IP=\"${NI_HTTPS_PROXY_IP:-${NI_HTTP_PROXY_IP:-${harbor_ip}}}\"|" "${HOST_CONFIG}"
    fi
    sed -i "s|^# INSTALL_CUDA=.*|INSTALL_CUDA=\"${NI_CUDA:-false}\"|" "${HOST_CONFIG}"
    sed -i "s|^# INSTALL_OPENCV=.*|INSTALL_OPENCV=\"${NI_OPENCV:-false}\"|" "${HOST_CONFIG}"
    sed -i "s|^# NPM_USE_CHINA_MIRROR=.*|NPM_USE_CHINA_MIRROR=\"${NI_NPM_MIRROR:-false}\"|" "${HOST_CONFIG}"

    # Auto-derive REGISTRY_URL
    # The REGISTRY_URL line in the template has two forms:
    #
    #   Original (before commit 5c4f980):
    #     # Auto-derived: REGISTRY_URL = ${HARBOR_SERVER_IP}:...
    #                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    #                matched by: ^#.*REGISTRY_URL= *
    #
    #   Current (split into two lines after commit 5c4f980):
    #     # Auto-derived
    #     # REGISTRY_URL= ${HARBOR_SERVER_IP}:...
    #                    ^^^^^^^^^^^^^^^^^^^^^^^^^
    #                    matched by: ^#.*REGISTRY_URL= *
    #
    # Regex breakdown — s|^# REGISTRY_URL= *.*|REGISTRY_URL="..."|:
    #
    #   ^          Anchor to the start of the line
    #   #          Literal hash — the variable is commented out in the template
    #   REGISTRY_URL   Literal variable name
    #   =          Literal equals sign
    #   *          Zero or more spaces AFTER the equals sign
    #             (the template line is "# REGISTRY_URL= ${HARBOR}" — note the space)
    #   .*         Any characters after the spaces (the old placeholder value)
    #
    # Replacement: REGISTRY_URL="${derived_registry_url}"
    #   The new value replaces the entire commented line, uncommented.
    #
    # Regex breakdown — /^# REGISTRY_URL= */a REGISTRY_URL="...":
    #
    #   /^# REGISTRY_URL= */   BRE pattern to find the commented line:
    #     ^                   Start of line
    #     #                   Literal hash
    #     REGISTRY_URL        Literal variable name
    #     =                   Literal equals sign
    #      *                  Zero or more spaces after "=" (template has one)
    #
    #   a\ REGISTRY_URL="..."   Append a new line AFTER the matched line:
    #     a\                   sed "append" command — adds text on a new line below
    #     REGISTRY_URL=...     The uncommented, evaluated value
    #
    # Result (two lines in the config file):
    #   # REGISTRY_URL= ${HARBOR_SERVER_IP}:${HARBOR_SERVER_PORT}/team_${CHIP_FAMILY}  ← kept as formula doc
    #   REGISTRY_URL="192.168.3.67:9000/team_rk3588"                                   ← new evaluated value
    #
    # Without " *" after "=", the pattern fails to match the template's "REGISTRY_URL= "
    # (equals + space), leaving REGISTRY_URL blank. That causes FINAL_IMAGE_NAME to become
    # "/<image>:latest" — an invalid reference with a leading slash.
    if [ -n "${harbor_ip}" ] && [ -n "${harbor_port}" ] && [ -n "${CHIP_FAMILY:-}" ]; then
        local derived_registry_url="${harbor_ip}:${harbor_port}/team_${CHIP_FAMILY}"
        sed -i "/^# REGISTRY_URL= */a REGISTRY_URL=\"${derived_registry_url}\"" "${HOST_CONFIG}"
    fi

    echo "  ✅ Host config created (non-interactive): $(basename "${HOST_CONFIG}")"
}

################################################################################
# Ensure host config exists (auto-create on first run)
################################################################################
_ensure_host_config() {
    local host_name
    host_name=$(hostname)

    # Check for existing host config (either naming convention)
    for host_file in "${ENTRY_CONFIGS_DIR}/3_hosts/${host_name}"*.env; do
        if [ -f "${host_file}" ]; then
            export HOST_CONFIG="${host_file}"
            return 0
        fi
    done

    # First run — create host config
    if [[ "${NI_MODE}" == "true" ]]; then
        _create_host_config_non_interactive
    else
        _create_host_config "${BUILD_SCRIPT_DIR}/volume"
    fi
}

################################################################################
# main_entry_1st_branch: Setup paths and ensure host config
################################################################################
main_entry_1st_setup() {
    # Setup paths (handover-specific: resolve relative to this script)
    export BUILD_SCRIPT_DIR="${SCRIPT_DIR}"
    export TOP_ROOT_DIR="${SCRIPT_DIR}"
    export TOP_CONFIGS_DIR="${SCRIPT_DIR}/configs"
    export ENTRY_DEFAULTS_DIR="${TOP_CONFIGS_DIR}/1_defaults"
    export ENTRY_CONFIGS_DIR="${TOP_CONFIGS_DIR}"
    export PLATFORM_ENV_SRC_DIR="${TOP_CONFIGS_DIR}/2_platforms"
    # Legacy fallback (only used when host config has no BASE_PLATFORM)
    export PLATFORM_ENV_DEST_PATH="${TOP_CONFIGS_DIR}/2_platforms/.env"

    # Ensure host config exists (first-run interactive)
    _ensure_host_config
}

################################################################################
# main_entry_2nd_branch: Load config layers and derive values
################################################################################
main_entry_2nd_load_config() {
    _load_config_layers

    # Derive FINAL_IMAGE_NAME (not in config.sh — handover-specific)
    if [ "${HAVE_HARBOR_SERVER}" == "TRUE" ]; then
        export FINAL_IMAGE_NAME="${REGISTRY_URL}/${IMAGE_NAME}:latest"
    else
        export FINAL_IMAGE_NAME="${IMAGE_NAME}:latest"
    fi

    # DEBUG: trace image name derivation
    echo "[DEBUG] HAVE_HARBOR_SERVER='${HAVE_HARBOR_SERVER}'"
    echo "[DEBUG] REGISTRY_URL='${REGISTRY_URL}'"
    echo "[DEBUG] IMAGE_NAME='${IMAGE_NAME}'"
    echo "[DEBUG] FINAL_IMAGE_NAME='${FINAL_IMAGE_NAME}'"
    echo "[DEBUG] FINAL_IMAGE_NAME hex: $(echo -n "${FINAL_IMAGE_NAME}" | xxd -p)"
}

################################################################################
# main_entry_3rd_branch: Start command
################################################################################
main_entry_3rd_cmd_start() {
    main_entry_1st_setup
    main_entry_2nd_load_config
    0_check_registry_login
    volumes_init_if_needed
    container_start_interactive
}

################################################################################
# main_entry_4th_branch: Stop command
################################################################################
main_entry_4th_cmd_stop() {
    main_entry_1st_setup
    main_entry_2nd_load_config
    container_stop
}

################################################################################
# main_entry_5th_branch: Restart command
################################################################################
main_entry_5th_cmd_restart() {
    main_entry_1st_setup
    main_entry_2nd_load_config
    container_restart
}

################################################################################
# main_entry_6th_branch: Recreate command
################################################################################
main_entry_6th_cmd_recreate() {
    main_entry_1st_setup
    main_entry_2nd_load_config
    0_check_registry_login
    volumes_init_if_needed
    container_recreate
}

################################################################################
# main_entry_7th_branch: Remove command
################################################################################
main_entry_7th_cmd_remove() {
    main_entry_1st_setup
    main_entry_2nd_load_config
    container_remove
}

################################################################################
# main_entry: Master router
################################################################################
main_entry() {
    # Parse command (first positional arg)
    local cmd=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            start|stop|restart|recreate|remove)
                cmd="$1"; shift ;;
            -h|--help|"")
                main_show_help; return 0 ;;
            --*)
                break ;;  # Options start here
            *)
                _error "Unknown command: $1"
                main_show_help; exit 1 ;;
        esac
    done

    if [[ -z "${cmd}" ]]; then
        main_show_help
        return 0
    fi

    # Parse CLI options
    NI_MODE="false"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --platform)       NI_MODE="true"; NI_PLATFORM="$2"; shift 2 ;;
            --volume)         NI_MODE="true"; NI_VOLUME="$2"; shift 2 ;;
            --harbor-ip)      NI_MODE="true"; NI_HARBOR_IP="$2"; shift 2 ;;
            --harbor-port)    NI_MODE="true"; NI_HARBOR_PORT="$2"; shift 2 ;;
            --gitlab)         NI_MODE="true"; NI_GITLAB="TRUE"; shift ;;
            --gitlab-ip)      NI_MODE="true"; NI_GITLAB_IP="$2"; shift 2 ;;
            --gitlab-port)    NI_MODE="true"; NI_GITLAB_PORT="$2"; shift 2 ;;
            --proxy)          NI_MODE="true"; NI_PROXY="true"; shift ;;
            --http-proxy-ip)  NI_MODE="true"; NI_HTTP_PROXY_IP="$2"; shift 2 ;;
            --https-proxy-ip) NI_MODE="true"; NI_HTTPS_PROXY_IP="$2"; shift 2 ;;
            --gpu)            NI_MODE="true"; NI_GPU="true"; NI_SHM="${NI_SHM:-1g}"; shift ;;
            --no-gpu)         NI_MODE="true"; NI_GPU="false"; shift ;;
            --shm)            NI_MODE="true"; NI_SHM="$2"; shift 2 ;;
            --network)        NI_MODE="true"; NI_NETWORK="$2"; shift 2 ;;
            --restart)        NI_MODE="true"; NI_RESTART="$2"; shift 2 ;;
            --cuda)           NI_MODE="true"; NI_CUDA="true"; shift ;;
            --no-cuda)        NI_MODE="true"; NI_CUDA="false"; shift ;;
            --opencv)         NI_MODE="true"; NI_OPENCV="true"; shift ;;
            --no-opencv)      NI_MODE="true"; NI_OPENCV="false"; shift ;;
            --npm-china-mirror) NI_MODE="true"; NI_NPM_MIRROR="true"; shift ;;
            --no-npm-china-mirror) NI_MODE="true"; NI_NPM_MIRROR="false"; shift ;;
            -h|--help)        main_show_help; return 0 ;;
            *)
                _error "Unknown option: $1"
                main_show_help; exit 1 ;;
        esac
    done

    # Route to command
    case "${cmd}" in
        "start")    main_entry_3rd_cmd_start ;;
        "stop")     main_entry_4th_cmd_stop ;;
        "restart")  main_entry_5th_cmd_restart ;;
        "recreate") main_entry_6th_cmd_recreate ;;
        "remove")   main_entry_7th_cmd_remove ;;
    esac
}

main_entry "$@"
