#!/usr/bin/env bash

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
# File: scripts/create_platform.sh
#
# Description: Wizard for creating a new platform configuration.
#
#   Interactive mode (default):
#     ./scripts/create_platform.sh
#
#   Non-interactive mode (AI-friendly / CI-friendly):
#     ./scripts/create_platform.sh --non-interactive \
#         --chip-family <chip_family> \  # e.g. rk3568, rk3588, rv1126
#         --chip-extract-name <name> \   # e.g. rk3568, rk3588s, rv1126bp
#         --os <ubuntu|debian> \
#         --os-version <22.04|24.04|...> \
#         --harbor-ip <ip> \
#         [--harbor-port <port>]         # default: 9000
#         [--host-volume-dir <path>]     # default: auto
#         [--gitlab-ip <ip>]             # enables GitLab (optional)
#         [--gitlab-port <port>]         # default: 80
#         [--sdk-branch <branch>]        # default: main
#         [--nvidia]                     # enable NVIDIA GPU
#         [--port-slot <n>]              # default: auto-assigned
#         [--proxy-http <url>]           # enables proxy (optional)
#         [--proxy-https <url>]          # default: same as --proxy-http
#         [--install-cuda]               # enable CUDA
#         [--install-opencv]             # enable OpenCV
#         [--npm-china-mirror]           # use npmmirror.com
#
#   Example (for AI agent or CI):
#     ./scripts/create_platform.sh --non-interactive \
#         --chip-family rk3568 \
#         --chip-extract-name rk3568 \
#         --os debian \
#         --os-version 12 \
#         --harbor-ip 192.168.3.68 \
#         --port-slot 3
#
#              Scans existing platforms for used PORT_SLOTs, auto-assigns the
#              next available slot, and generates a complete .env file.
#
#              Called from the `harbor` script — not intended for direct use.
#
# Author: PotterWhite
# Created: 2026-03-24
#
# Copyright (c) 2024 [PotterWhite]
# License: MIT
################################################################################

set -euo pipefail

# ─── Resolve paths ───────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOP_ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PLATFORMS_DIR="${TOP_ROOT_DIR}/configs/platforms"

# ─── Colors ──────────────────────────────────────────────────────────────────
_BOLD='\033[1m'
_GREEN='\033[0;32m'
_YELLOW='\033[1;33m'
_CYAN='\033[0;36m'
_RED='\033[0;31m'
_NC='\033[0m'

# ─── Port base values (must match scripts/port_calc.sh) ──────────────────────
_PORT_BASE_CLIENT_SSH=2109
_PORT_BASE_GDB=2345
_PORT_STEP=10

# ─── Helper functions ────────────────────────────────────────────────────────

# Print a styled header
_header() {
    echo ""
    echo -e "${_BOLD}${_CYAN}╔══════════════════════════════════════════════════════════════╗${_NC}"
    echo -e "${_BOLD}${_CYAN}║           CREATE NEW PLATFORM CONFIGURATION                 ║${_NC}"
    echo -e "${_BOLD}${_CYAN}╚══════════════════════════════════════════════════════════════╝${_NC}"
    echo ""
}

# Prompt with a default value; empty input = default
# Usage: _prompt "Label" "default_value"  → sets REPLY
_prompt() {
    local label="$1"
    local default="${2:-}"
    if [[ -n "${default}" ]]; then
        echo -ne "  ${_BOLD}${label}${_NC} [${_GREEN}${default}${_NC}]: "
        read -r REPLY
        REPLY="${REPLY:-${default}}"
    else
        echo -ne "  ${_BOLD}${label}${_NC}: "
        read -r REPLY
        if [[ -z "${REPLY}" ]]; then
            echo -e "  ${_RED}Error: This field is required.${_NC}"
            _prompt "$@"  # retry
        fi
    fi
}

# Prompt for yes/no; returns 0 for yes, 1 for no
# Usage: _prompt_yn "Question" "y/n"  (default)
_prompt_yn() {
    local label="$1"
    local default="${2:-n}"
    local hint
    if [[ "${default}" == "y" ]]; then
        hint="Y/n"
    else
        hint="y/N"
    fi
    echo -ne "  ${_BOLD}${label}${_NC} [${hint}]: "
    read -r REPLY
    REPLY="${REPLY:-${default}}"
    [[ "${REPLY,,}" == "y" || "${REPLY,,}" == "yes" ]]
}

# Scan all platform .env files for PORT_SLOT values; return sorted list
_get_used_slots() {
    local slots=()
    for env_file in "${PLATFORMS_DIR}"/*.env; do
        [[ ! -f "${env_file}" ]] && continue
        local slot
        slot=$(grep -oP '^\s*PORT_SLOT\s*=\s*"?\K[0-9]+' "${env_file}" 2>/dev/null || true)
        if [[ -n "${slot}" ]]; then
            slots+=("${slot}")
        fi
    done
    printf '%s\n' "${slots[@]}" | sort -n | uniq
}

# Find the next available slot
_next_available_slot() {
    local used_slots
    used_slots=$(_get_used_slots)
    local candidate=0
    while echo "${used_slots}" | grep -qx "${candidate}"; do
        ((candidate++))
    done
    echo "${candidate}"
}

# ─── Main wizard ─────────────────────────────────────────────────────────────
create_platform() {
    _header

    # 0. Show existing platforms (sorted by PORT_SLOT / SSH port ascending)
    echo -e "  ${_YELLOW}Existing platforms and their PORT_SLOTs:${_NC}"

    # Build a sortable list: "<slot_numeric> <name> <ssh> <gdb> <slot_label>"
    local _sort_lines=()
    for env_file in "${PLATFORMS_DIR}"/*.env; do
        [[ ! -f "${env_file}" ]] && continue
        local name slot sort_key ssh_port gdb_port slot_label
        name=$(basename "${env_file}" .env)
        slot=$(grep -oP '^\s*PORT_SLOT\s*=\s*"?\K[0-9]+' "${env_file}" 2>/dev/null || true)
        if [[ -n "${slot}" ]]; then
            ssh_port=$(( _PORT_BASE_CLIENT_SSH + slot * _PORT_STEP ))
            gdb_port=$(( _PORT_BASE_GDB + slot * _PORT_STEP ))
            sort_key="${slot}"
            slot_label="slot=${slot}"
        else
            ssh_port=$(grep -oP '^\s*CLIENT_SSH_PORT\s*=\s*"?\K[0-9]+' "${env_file}" 2>/dev/null || echo "?")
            gdb_port=$(grep -oP '^\s*GDB_PORT\s*=\s*"?\K[0-9]+' "${env_file}" 2>/dev/null || echo "?")
            sort_key="999"
            slot_label="(manual)"
        fi
        _sort_lines+=("${sort_key} ${name} ${ssh_port} ${gdb_port} ${slot_label}")
    done

    # Sort by first field (slot number) and print
    while IFS= read -r line; do
        read -r _sk _name _ssh _gdb _label <<< "${line}"
        printf "    %-24s %-8s  SSH=%-5s  GDB=%-5s\n" "${_name}" "${_label}" "${_ssh}" "${_gdb}"
    done < <(printf '%s\n' "${_sort_lines[@]}" | sort -n)

    local next_slot
    next_slot=$(_next_available_slot)
    echo ""
    echo -e "  ${_GREEN}Next available PORT_SLOT: ${next_slot}${_NC}"
    echo ""
    echo -e "  ${_YELLOW}--- Platform Details ---${_NC}"
    echo ""

    # 1. CHIP_FAMILY — silicon family used for Harbor team / SDK repo grouping
    _prompt "CHIP_FAMILY (e.g. rk3588, rk3568, rv1126)"
    local chip_family="${REPLY,,}"

    if [[ ! "${chip_family}" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo -e "  ${_RED}Error: CHIP_FAMILY can only contain letters, digits, hyphens, and underscores.${_NC}"
        return 1
    fi

    # 2. CHIP_EXTRACT_NAME — the exact variant name (may differ from family, e.g. rk3588s)
    _prompt "CHIP_EXTRACT_NAME (exact variant, e.g. rk3588s, rv1126bp)" "${chip_family}"
    local chip_extract_name="${REPLY,,}"

    if [[ ! "${chip_extract_name}" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo -e "  ${_RED}Error: CHIP_EXTRACT_NAME can only contain letters, digits, hyphens, and underscores.${_NC}"
        return 1
    fi

    # 3. OS distribution
    _prompt "OS distribution (e.g. ubuntu, debian, alpine)" "ubuntu"
    local os_distro="${REPLY,,}"  # lowercase

    # 4. OS version (default only makes sense for Ubuntu)
    local os_version
    if [[ "${os_distro}" == "ubuntu" ]]; then
        _prompt "OS version (e.g. 22.04, 24.04, 20.04)" "22.04"
    else
        _prompt "OS version"
    fi
    os_version="${REPLY}"

    # Auto-derive platform name: <chip_family>-<chip_extract_name>_<os_distro>-<os_version>
    local derived_name="${chip_family}-${chip_extract_name}_${os_distro}-${os_version}"
    _prompt "Platform config file name (auto-derived)" "${derived_name}"
    local platform_name="${REPLY}"

    # Validate: no spaces, no special chars
    if [[ ! "${platform_name}" =~ ^[a-zA-Z0-9_.-]+$ ]]; then
        echo -e "  ${_RED}Error: Platform name can only contain letters, digits, hyphens, dots, and underscores.${_NC}"
        return 1
    fi

    # Check for existing platform
    if [[ -f "${PLATFORMS_DIR}/${platform_name}.env" ]]; then
        echo -e "  ${_RED}Error: Platform '${platform_name}' already exists at:${_NC}"
        echo -e "  ${_RED}  ${PLATFORMS_DIR}/${platform_name}.env${_NC}"
        return 1
    fi

    # Host volume directory
    _prompt "Host volume directory" "/mnt/2tb_wd_purpleSurveillance_hdd/system-redirection/Development/docker/volumes/${chip_family}"
    local host_volume_dir="${REPLY}"

    # 4. GitLab server (optional)
    local have_gitlab="FALSE"
    local gitlab_ip="" gitlab_port=""
    if _prompt_yn "GitLab server available?" "n"; then
        have_gitlab="TRUE"
        _prompt "GitLab server IP" "192.168.3.67"
        gitlab_ip="${REPLY}"
        _prompt "GitLab server port" "80"
        gitlab_port="${REPLY}"
    fi

    # 5. Harbor registry server
    local harbor_ip harbor_port
    if [[ "${have_gitlab}" == "TRUE" ]]; then
        _prompt "Harbor registry IP" "${gitlab_ip}"
    else
        _prompt "Harbor registry IP" "192.168.3.68"
    fi
    harbor_ip="${REPLY}"
    _prompt "Harbor registry port" "9000"
    harbor_port="${REPLY}"

    # 6. SDK branch
    _prompt "SDK git branch" "main"
    local sdk_branch="${REPLY}"

    # 7. NVIDIA GPU
    local use_nvidia="false"
    if _prompt_yn "Enable NVIDIA GPU support?" "n"; then
        use_nvidia="true"
    fi

    # 8. PORT_SLOT
    _prompt "PORT_SLOT (auto-assigned)" "${next_slot}"
    local port_slot="${REPLY}"

    # Validate PORT_SLOT is numeric
    if ! [[ "${port_slot}" =~ ^[0-9]+$ ]]; then
        echo -e "  ${_RED}Error: PORT_SLOT must be a non-negative integer.${_NC}"
        return 1
    fi

    # Check for slot collision
    if _get_used_slots | grep -qx "${port_slot}"; then
        echo -e "  ${_RED}Warning: PORT_SLOT ${port_slot} is already used by another platform!${_NC}"
        if ! _prompt_yn "Continue anyway?" "n"; then
            return 1
        fi
    fi

    # 9. Proxy
    local has_proxy="false"
    local http_proxy_url=""
    local https_proxy_url=""
    if _prompt_yn "Has proxy?" "n"; then
        has_proxy="true"
        _prompt "HTTP proxy URL" "http://${harbor_ip}:7890"
        http_proxy_url="${REPLY}"
        _prompt "HTTPS proxy URL" "${http_proxy_url}"
        https_proxy_url="${REPLY}"
    fi

    # ─── Calculate and display ports ─────────────────────────────────────
    local offset=$(( port_slot * _PORT_STEP ))
    local calc_ssh=$(( _PORT_BASE_CLIENT_SSH + offset ))
    local calc_gdb=$(( _PORT_BASE_GDB + offset ))

    echo ""
    echo -e "  ${_YELLOW}--- Summary ---${_NC}"
    echo ""
    echo -e "  File name:       ${_BOLD}${platform_name}.env${_NC}"
    echo -e "  CHIP_FAMILY:     ${chip_family}"
    echo -e "  CHIP_EXTRACT_NAME: ${chip_extract_name}"
    echo -e "  OS:              ${os_distro} ${os_version}"
    echo -e "  PORT_SLOT:       ${port_slot} (offset = ${offset})"
    echo -e "  Volume:          ${host_volume_dir}"
    if [[ "${have_gitlab}" == "TRUE" ]]; then
        echo -e "  GitLab:          ${gitlab_ip}:${gitlab_port}"
    else
        echo -e "  GitLab:          (none)"
    fi
    echo -e "  Harbor registry: ${harbor_ip}:${harbor_port}"
    echo -e "  NVIDIA GPU:      ${use_nvidia}"
    if [[ "${has_proxy}" == "true" ]]; then
        echo -e "  HTTP  proxy:     ${http_proxy_url}"
        echo -e "  HTTPS proxy:     ${https_proxy_url}"
    fi
    echo ""
    echo -e "  ${_CYAN}Calculated Ports:${_NC}"
    echo -e "    CLIENT_SSH_PORT = ${calc_ssh}"
    echo -e "    GDB_PORT        = ${calc_gdb}"
    echo ""

    if ! _prompt_yn "Generate ${platform_name}.env?" "y"; then
        echo -e "  ${_YELLOW}Cancelled.${_NC}"
        return 1
    fi

    # ─── Generate the .env file ──────────────────────────────────────────
    local output_file="${PLATFORMS_DIR}/${platform_name}.env"

    # Build GitLab block conditionally
    local gitlab_block
    if [[ "${have_gitlab}" == "TRUE" ]]; then
        gitlab_block="HAVE_GITLAB_SERVER=\"TRUE\"
GITLAB_SERVER_IP=\"${gitlab_ip}\"
GITLAB_SERVER_PORT=\"${gitlab_port}\""
    else
        gitlab_block="HAVE_GITLAB_SERVER=\"FALSE\""
    fi

    # Build proxy block conditionally
    local proxy_block
    if [[ "${has_proxy}" == "true" ]]; then
        proxy_block="HAS_PROXY=\"true\"
HTTP_PROXY_IP=\"${http_proxy_url}\"
HTTPS_PROXY_IP=\"${https_proxy_url}\""
    else
        proxy_block="HAS_PROXY=\"false\""
    fi

    cat > "${output_file}" << ENVEOF
################################################################################
# File: configs/platforms/${platform_name}.env
#
# Description: Platform-specific overrides for ${platform_name} (${os_distro} ${os_version}).
#              Only values that DIFFER from configs/defaults/*.env are listed.
#              All other settings are inherited from the defaults layer.
#
# Author: PotterWhite
# Created: $(date +%Y-%m-%d)
# Last Modified: $(date +%Y-%m-%d)
#
# Copyright (c) 2024 [PotterWhite]
# License: MIT
#
# Port: PORT_SLOT=${port_slot}
#   → CLIENT_SSH_PORT=${calc_ssh}, GDB_PORT=${calc_gdb} (auto-calculated)
#
################################################################################

# =============================================================================
# Platform Identity  [REQUIRED — no defaults]
# =============================================================================
CHIP_FAMILY="${chip_family}"
# ${chip_extract_name} is a variant of ${chip_family} series SOC
CHIP_EXTRACT_NAME="${chip_extract_name}"
OS_DISTRIBUTION="${os_distro}"
OS_VERSION="${os_version}"
PRODUCT_NAME="\${CHIP_FAMILY}-\${CHIP_EXTRACT_NAME}_\${OS_DISTRIBUTION}-\${OS_VERSION}"

# Derived from PRODUCT_NAME (keep in sync)
IMAGE_NAME="\${PRODUCT_NAME}-dev-env"
LATEST_IMAGE_TAG=\${PROJECT_VERSION}
CONTAINER_NAME=\${PRODUCT_NAME}

# =============================================================================
# GitLab Server  [optional — set HAVE_GITLAB_SERVER=FALSE to skip]
# =============================================================================
${gitlab_block}

# =============================================================================
# Harbor Registry  [required for push/pull]
# =============================================================================
HARBOR_SERVER_IP="${harbor_ip}"
HARBOR_SERVER_PORT="${harbor_port}"
REGISTRY_URL="\${HARBOR_SERVER_IP}:\${HARBOR_SERVER_PORT}/team_\${CHIP_FAMILY}"

# =============================================================================
# SDK  [CHIP_FAMILY groups same-silicon variants together]
# =============================================================================
SDK_INSTALL_PATH="\${WORKSPACE_ROOT}/sdk"
SDK_GIT_REPO="git@\${GITLAB_SERVER_IP:-${harbor_ip}}:team_\${CHIP_FAMILY}/\${PRODUCT_NAME}_sdk.git"
SDK_GIT_KEY_FILE="SDK_\${CHIP_FAMILY}_ED25519"
SDK_GIT_DEFAULT_BRANCH="${sdk_branch}"

# =============================================================================
# Docker Volumes  [REQUIRED — no universal default]
# =============================================================================
HOST_VOLUME_DIR="${host_volume_dir}"

# =============================================================================
# Container Runtime  [ports auto-calculated from PORT_SLOT]
# =============================================================================
PORT_SLOT="${port_slot}"
USE_NVIDIA_GPU="${use_nvidia}"

# =============================================================================
# Proxy Overrides
# =============================================================================
${proxy_block}
ENVEOF

    echo ""
    echo -e "  ${_GREEN}Generated: ${output_file}${_NC}"
    echo ""
    echo -e "  ${_CYAN}The new platform will appear in the harbor menu automatically.${_NC}"
    echo ""

    return 0
}

# ─── Non-interactive mode ────────────────────────────────────────────────────

create_platform_noninteractive() {
    # ── Parse arguments ──────────────────────────────────────────────────────
    local chip_family="" chip_extract_name="" os_distro="ubuntu" os_version=""
    local harbor_ip="" harbor_port="9000"
    local host_volume_dir=""
    local have_gitlab="FALSE" gitlab_ip="" gitlab_port="80"
    local sdk_branch="main"
    local use_nvidia="false"
    local port_slot=""
    local has_proxy="false" http_proxy_url="" https_proxy_url=""
    local install_cuda="false" install_opencv="false"
    local npm_china_mirror="false"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --chip-family)     chip_family="${2,,}";   shift 2 ;;
            --chip-extract-name) chip_extract_name="${2,,}"; shift 2 ;;
            --name)            chip_family="$2"; chip_extract_name="$2"; shift 2 ;;  # legacy compat
            --os)              os_distro="${2,,}";    shift 2 ;;
            --os-version)      os_version="$2";       shift 2 ;;
            --harbor-ip)       harbor_ip="$2";        shift 2 ;;
            --harbor-port)     harbor_port="$2";      shift 2 ;;
            --host-volume-dir) host_volume_dir="$2";  shift 2 ;;
            --gitlab-ip)       have_gitlab="TRUE"; gitlab_ip="$2"; shift 2 ;;
            --gitlab-port)     gitlab_port="$2";      shift 2 ;;
            --sdk-branch)      sdk_branch="$2";       shift 2 ;;
            --nvidia)          use_nvidia="true";     shift ;;
            --port-slot)       port_slot="$2";        shift 2 ;;
            --proxy-http)      has_proxy="true"; http_proxy_url="$2"; shift 2 ;;
            --proxy-https)     https_proxy_url="$2";  shift 2 ;;
            --install-cuda)    install_cuda="true";   shift ;;
            --install-opencv)  install_opencv="true"; shift ;;
            --npm-china-mirror) npm_china_mirror="true"; shift ;;
            *) echo "Unknown argument: $1" >&2; exit 1 ;;
        esac
    done

    # ── Validate required fields ─────────────────────────────────────────────
    local errors=0
    [[ -z "${chip_family}" ]]    && { echo "ERROR: --chip-family is required" >&2; ((errors++)); }
    [[ -z "${os_version}" ]]     && { echo "ERROR: --os-version is required" >&2; ((errors++)); }
    [[ -z "${harbor_ip}" ]]      && { echo "ERROR: --harbor-ip is required" >&2; ((errors++)); }
    [[ $errors -gt 0 ]] && exit 1

    # chip_extract_name defaults to chip_family if not specified
    if [[ -z "${chip_extract_name}" ]]; then
        chip_extract_name="${chip_family}"
    fi

    # Auto-derive platform file name
    local platform_name="${chip_family}-${chip_extract_name}_${os_distro}-${os_version}"

    if [[ ! "${chip_family}" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "ERROR: CHIP_FAMILY '${chip_family}' contains invalid characters" >&2
        exit 1
    fi

    if [[ -f "${PLATFORMS_DIR}/${platform_name}.env" ]]; then
        echo "ERROR: Platform '${platform_name}' already exists at ${PLATFORMS_DIR}/${platform_name}.env" >&2
        exit 1
    fi

    # ── Auto-assign PORT_SLOT if not specified ────────────────────────────────
    if [[ -z "${port_slot}" ]]; then
        port_slot=$(_next_available_slot)
        echo "INFO: Auto-assigned PORT_SLOT=${port_slot}"
    fi

    if ! [[ "${port_slot}" =~ ^[0-9]+$ ]]; then
        echo "ERROR: PORT_SLOT must be a non-negative integer" >&2
        exit 1
    fi

    # ── Default host volume dir ───────────────────────────────────────────────
    if [[ -z "${host_volume_dir}" ]]; then
        host_volume_dir="/mnt/2tb_wd_purpleSurveillance_hdd/system-redirection/Development/docker/volumes/${chip_family}"
    fi

    # ── Default HTTPS proxy = HTTP proxy if not set ───────────────────────────
    if [[ "${has_proxy}" == "true" && -z "${https_proxy_url}" ]]; then
        https_proxy_url="${http_proxy_url}"
    fi

    # ── Calculate ports ───────────────────────────────────────────────────────
    local offset=$(( port_slot * _PORT_STEP ))
    local calc_ssh=$(( _PORT_BASE_CLIENT_SSH + offset ))
    local calc_gdb=$(( _PORT_BASE_GDB + offset ))

    # ── Build conditional blocks ──────────────────────────────────────────────
    local gitlab_block
    if [[ "${have_gitlab}" == "TRUE" ]]; then
        gitlab_block="HAVE_GITLAB_SERVER=\"TRUE\"
GITLAB_SERVER_IP=\"${gitlab_ip}\"
GITLAB_SERVER_PORT=\"${gitlab_port}\""
    else
        gitlab_block="HAVE_GITLAB_SERVER=\"FALSE\""
    fi

    local proxy_block
    if [[ "${has_proxy}" == "true" ]]; then
        proxy_block="HAS_PROXY=\"true\"
HTTP_PROXY_IP=\"${http_proxy_url}\"
HTTPS_PROXY_IP=\"${https_proxy_url}\""
    else
        proxy_block="HAS_PROXY=\"false\""
    fi

    local tools_overrides=""
    [[ "${install_cuda}" == "true" ]]         && tools_overrides+=$'\nINSTALL_CUDA="true"'
    [[ "${install_opencv}" == "true" ]]       && tools_overrides+=$'\nINSTALL_OPENCV="true"'
    [[ "${npm_china_mirror}" == "true" ]]     && tools_overrides+=$'\nNPM_USE_CHINA_MIRROR="true"'

    # ── Print summary ─────────────────────────────────────────────────────────
    echo ""
    echo "  [non-interactive] Creating platform: ${platform_name}"
    echo "  CHIP_FAMILY:     ${chip_family}"
    echo "  CHIP_EXTRACT_NAME: ${chip_extract_name}"
    echo "  OS:              ${os_distro} ${os_version}"
    echo "  PORT_SLOT:       ${port_slot} → SSH=${calc_ssh}, GDB=${calc_gdb}"
    echo "  Harbor:          ${harbor_ip}:${harbor_port}"
    echo "  Volume:          ${host_volume_dir}"
    [[ "${have_gitlab}" == "TRUE" ]] && echo "  GitLab:          ${gitlab_ip}:${gitlab_port}"
    echo ""

    # ── Generate .env file ────────────────────────────────────────────────────
    local output_file="${PLATFORMS_DIR}/${platform_name}.env"

    cat > "${output_file}" << ENVEOF
################################################################################
# File: configs/platforms/${platform_name}.env
#
# Description: Platform-specific overrides for ${platform_name} (${os_distro} ${os_version}).
#              Only values that DIFFER from configs/defaults/*.env are listed.
#              All other settings are inherited from the defaults layer.
#
# Generated: $(date +%Y-%m-%d) by create_platform.sh --non-interactive
#
# Copyright (c) 2024 [PotterWhite]
# License: MIT
#
# Port: PORT_SLOT=${port_slot}
#   → CLIENT_SSH_PORT=${calc_ssh}, GDB_PORT=${calc_gdb} (auto-calculated)
#
################################################################################

# =============================================================================
# Platform Identity  [REQUIRED — no defaults]
# =============================================================================
CHIP_FAMILY="${chip_family}"
# ${chip_extract_name} is a variant of ${chip_family} series SOC
CHIP_EXTRACT_NAME="${chip_extract_name}"
OS_DISTRIBUTION="${os_distro}"
OS_VERSION="${os_version}"
PRODUCT_NAME="\${CHIP_FAMILY}-\${CHIP_EXTRACT_NAME}_\${OS_DISTRIBUTION}-\${OS_VERSION}"

# Derived from PRODUCT_NAME (keep in sync)
IMAGE_NAME="\${PRODUCT_NAME}-dev-env"
LATEST_IMAGE_TAG=\${PROJECT_VERSION}
CONTAINER_NAME=\${PRODUCT_NAME}

# =============================================================================
# GitLab Server  [optional — set HAVE_GITLAB_SERVER=FALSE to skip]
# =============================================================================
${gitlab_block}

# =============================================================================
# Harbor Registry  [required for push/pull]
# =============================================================================
HARBOR_SERVER_IP="${harbor_ip}"
HARBOR_SERVER_PORT="${harbor_port}"
REGISTRY_URL="\${HARBOR_SERVER_IP}:\${HARBOR_SERVER_PORT}/team_\${CHIP_FAMILY}"

# =============================================================================
# SDK  [CHIP_FAMILY groups same-silicon variants together]
# =============================================================================
SDK_INSTALL_PATH="\${WORKSPACE_ROOT}/sdk"
SDK_GIT_REPO="git@\${GITLAB_SERVER_IP:-${harbor_ip}}:team_\${CHIP_FAMILY}/\${PRODUCT_NAME}_sdk.git"
SDK_GIT_KEY_FILE="SDK_\${CHIP_FAMILY}_ED25519"
SDK_GIT_DEFAULT_BRANCH="${sdk_branch}"

# =============================================================================
# Docker Volumes  [REQUIRED — no universal default]
# =============================================================================
HOST_VOLUME_DIR="${host_volume_dir}"

# =============================================================================
# Container Runtime  [ports auto-calculated from PORT_SLOT]
# =============================================================================
PORT_SLOT="${port_slot}"
USE_NVIDIA_GPU="${use_nvidia}"

# =============================================================================
# Tools Overrides (non-default values only)
# =============================================================================${tools_overrides}

# =============================================================================
# Proxy Overrides
# =============================================================================
${proxy_block}
ENVEOF

    echo "  Generated: ${output_file}"
    echo ""
}

# ─── Entry point ─────────────────────────────────────────────────────────────
# Route to interactive or non-interactive mode based on first argument.
if [[ "${1:-}" == "--non-interactive" ]]; then
    shift
    create_platform_noninteractive "$@"
else
    create_platform "$@"
fi
