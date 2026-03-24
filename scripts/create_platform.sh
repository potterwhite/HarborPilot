#!/usr/bin/env bash
################################################################################
# File: scripts/create_platform.sh
#
# Description: Interactive wizard for creating a new platform configuration.
#              Scans existing platforms for used PORT_SLOTs, auto-assigns the
#              next available slot, prompts for platform-specific values, and
#              generates a complete .env file.
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

    # 1. Platform name
    _prompt "Platform name (e.g. rk3566, imx8mp, am62x)"
    local platform_name="${REPLY}"

    # Validate: no spaces, no special chars
    if [[ ! "${platform_name}" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo -e "  ${_RED}Error: Platform name can only contain letters, digits, hyphens, and underscores.${_NC}"
        return 1
    fi

    # Check for existing platform
    if [[ -f "${PLATFORMS_DIR}/${platform_name}.env" ]]; then
        echo -e "  ${_RED}Error: Platform '${platform_name}' already exists at:${_NC}"
        echo -e "  ${_RED}  ${PLATFORMS_DIR}/${platform_name}.env${_NC}"
        return 1
    fi

    # 2. OS version
    _prompt "OS version (e.g. 22.04, 24.04, 20.04)" "22.04"
    local os_version="${REPLY}"

    # 3. Host volume directory
    _prompt "Host volume directory" "/mnt/2tb_wd_purpleSurveillance_hdd/system-redirection/Development/docker/volumes/${platform_name}"
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
    echo -e "  Platform:        ${_BOLD}${platform_name}${_NC}"
    echo -e "  OS version:      ${os_version}"
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
# Description: Platform-specific overrides for ${platform_name} (${os_version}).
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
PRODUCT_NAME="${platform_name}"
OS_VERSION="${os_version}"

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
REGISTRY_URL="\${HARBOR_SERVER_IP}:\${HARBOR_SERVER_PORT}/team_\${CONTAINER_NAME}"

# =============================================================================
# SDK  [derived — depends on CONTAINER_NAME and GITLAB_SERVER_IP]
# =============================================================================
SDK_INSTALL_PATH="\${WORKSPACE_ROOT}/sdk"
SDK_GIT_REPO="git@\${GITLAB_SERVER_IP:-${harbor_ip}}:team_\${CONTAINER_NAME}/\${CONTAINER_NAME}_sdk.git"
SDK_GIT_KEY_FILE="SDK_\${CONTAINER_NAME}_ED25519"
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

# ─── Entry point ─────────────────────────────────────────────────────────────
create_platform "$@"
