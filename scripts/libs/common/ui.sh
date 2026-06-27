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
# Module: ui.sh
# Description: UI interaction functions for HarborPilot
# Functions: prompt_with_timeout, prompt_simple, 0_show_main_menu,
#            _show_config_menu, 1_specify_platform, _select_host_config,
#            _create_host_config, _load_host_config, _check_and_prompt_host_config,
#            _print_next_steps
################################################################################

################################################################################
# Unified prompt function with timeout and Ctrl+C/Esc handling
# Arguments:
#   $1 - Prompt message
#   $2 - Timeout in seconds
# Returns:
#   0 if user confirms, 1 if user denies or timeout occurs
################################################################################
prompt_with_timeout() {
    local message="$1"
    local timeout="$2"

    echo -e "\n--------------------"
    echo -e "${message}"
    echo -e "--------------------"

    echo "Default: Yes (Press 'n' to skip, any other key to continue, Ctrl+C or Esc to abort all)"

    # Ctrl+C should abort the entire script, not just skip this step.
    # We temporarily override SIGINT only during the read loop, then restore it.
    local _user_aborted=0
    trap '_user_aborted=1' SIGINT

    for ((i = timeout; i > 0; i--)); do
        echo -ne "\rStarting in $i seconds... "
        read -t 1 -n 1 input
        local _read_rc=$?

        if [ "${_user_aborted}" -eq 1 ]; then
            # Restore default SIGINT and propagate the abort upward
            trap - SIGINT
            echo -e "\nAborted by user — exiting."
            kill -INT $$
            return 1   # unreachable, but keeps shellcheck happy
        fi

        if [ ${_read_rc} -eq 0 ]; then
            trap - SIGINT
            echo -e "\n"
            if [[ "${input,,}" == "n" || "${input}" == $'\e' ]]; then
                return 1
            else
                return 0
            fi
        fi
    done

    trap - SIGINT
    echo -e "\nProceeding with default action..."
    return 0
}

################################################################################
# Simple prompt function without timeout (for guided wizards)
# Arguments:
#   $1 - Prompt message
#   $2 - Current question number (optional)
#   $3 - Total questions count (optional)
#   $4 - Recommended value: "y" or "n" (optional, default: "y")
# Returns:
#   0 if user confirms (y/Y/Enter), 1 if user denies (n/N)
################################################################################
prompt_simple() {
    local message="$1"
    local current="${2:-}"
    local total="${3:-}"
    local recommend="${4:-y}"  # Default recommendation is "y"
    local prefix=""

    if [[ -n "${current}" && -n "${total}" ]]; then
        prefix="(${current}/${total}) "
    fi

    # Determine which option is recommended
    local recommend_y=""
    local recommend_n=""
    if [[ "${recommend,,}" == "y" ]]; then
        recommend_y=" (recommended)"
        recommend_n=""
    else
        recommend_y=""
        recommend_n=" (recommended)"
    fi

    echo ""
    echo "  ╔══════════════════════════════════════════════════════════════════╗"
    echo "  ║                                                                  ║"
    printf "  ║  ${prefix}%-60s║\n" "${message}"
    echo "  ║                                                                  ║"
    printf "  ║  [y] Yes%-8s [n] No%-48s║\n" "${recommend_y}" "${recommend_n}"
    echo "  ║  (Press Enter for recommended option)                            ║"
    echo "  ║                                                                  ║"
    echo "  ╚══════════════════════════════════════════════════════════════════╝"

    while true; do
        read -p "  Your choice: " input
        case "${input,,}" in
            y|yes)
                return 0
                ;;
            n|no)
                return 1
                ;;
            "")
                # Enter pressed - use recommended value
                if [[ "${recommend,,}" == "y" ]]; then
                    return 0
                else
                    return 1
                fi
                ;;
            *)
                echo "  ✗ Please enter 'y' or 'n' (or press Enter for recommended)."
                ;;
        esac
    done
}

################################################################################
# 0. Top-level action menu: Build, Package, or Configurations
# Sets _HARBOR_MODE to "build", "package", or "config"
################################################################################
0_show_main_menu() {
    echo ""
    echo "  ╔══════════════════════════════════════════════════════════════════╗"
    echo "  ║                      HarborPilot — Main Menu                     ║"
    echo "  ╠══════════════════════════════════════════════════════════════════╣"
    echo "  ║                                                                  ║"
    echo "  ║  [1]  Configurations        — create platform or host config     ║"
    echo "  ║  [2]  Build & Push          — build image and push to registry   ║"
    echo "  ║  [3]  Package Handover      — create client delivery tarball     ║"
    echo "  ║                                                                  ║"
    echo "  ╚══════════════════════════════════════════════════════════════════╝"
    echo ""

    while true; do
        read -p "  Please select [1-3]: " _menu_choice
        case "${_menu_choice}" in
            1)
                _HARBOR_MODE="config"
                echo "  → Configurations selected."
                echo ""
                break
                ;;
            2)
                _HARBOR_MODE="build"
                echo "  → Build & Push selected."
                echo ""
                break
                ;;
            3)
                _HARBOR_MODE="package"
                echo "  → Package Handover selected."
                echo ""
                break
                ;;
            *)
                echo "  ✗ Invalid choice. Please enter 1, 2, or 3."
                ;;
        esac
    done
}

################################################################################
# Configurations submenu: create platform, create host, or go back
################################################################################
_show_config_menu() {
    while true; do
        echo ""
        echo "  ╔══════════════════════════════════════════════════════════════════╗"
        echo "  ║                     Configurations                               ║"
        echo "  ╠══════════════════════════════════════════════════════════════════╣"
        echo "  ║                                                                  ║"
        echo "  ║  [1]  Create new platform                                        ║"
        echo "  ║  [2]  Create new host (based on existing platform config)        ║"
        echo "  ║                                                                  ║"
        echo "  ║  [0]  Back to main menu                                          ║"
        echo "  ║                                                                  ║"
        echo "  ╚══════════════════════════════════════════════════════════════════╝"
        echo ""

        read -p "  Please select [0-2]: " _config_choice
        case "${_config_choice}" in
            1)
                "${TOP_ROOT_DIR}/scripts/create_platform.sh" || true
                ;;
            2)
                _create_host_config
                read -p "  Build this host now? (y/N): " _build_choice
                if [[ "${_build_choice}" =~ ^[yY]$ ]]; then
                    _load_host_config "$(basename "${HOST_CONFIG}" .env)"
                    _HARBOR_MODE="build"
                    break
                fi
                ;;
            0)
                echo "  → Back to main menu."
                echo ""
                break
                ;;
            *)
                echo "  ✗ Invalid choice. Please enter 0, 1, or 2."
                ;;
        esac
    done
}

################################################################################
# Print next steps after a successful build
################################################################################
_print_next_steps() {
    echo ""
    echo "  ╔══════════════════════════════════════════════════════════════════╗"
    echo "  ║                  BUILD COMPLETE — NEXT STEPS                     ║"
    echo "  ╠══════════════════════════════════════════════════════════════════╣"
    echo "  ║                                                                  ║"
    echo "  ║  Image  : ${IMAGE_NAME}:${PROJECT_VERSION}"
    echo "  ║  Platform: ${PRODUCT_NAME}"
    echo "  ║                                                                  ║"
    echo "  ║  To deploy on a client Ubuntu host:                              ║"
    echo "  ║    1. Run: ./harbor → Package Handover                          ║"
    echo "  ║    2. Transfer the tarball to the client                         ║"
    echo "  ║    3. Extract and run: ./ubuntu_only_entrance.sh start           ║"
    echo "  ║                                                                  ║"
    echo "  ║  Supported commands:                                             ║"
    echo "  ║    start     — create and start the container                    ║"
    echo "  ║    stop      — stop the running container                        ║"
    echo "  ║    restart   — restart the container                             ║"
    echo "  ║    recreate  — remove and recreate the container                 ║"
    echo "  ║    remove    — stop and remove the container                     ║"
    echo "  ║                                                                  ║"
    echo "  ║  Example:                                                        ║"
    echo "  ║    ./ubuntu_only_entrance.sh start"
    echo "  ║                                                                  ║"
    echo "  ╠══════════════════════════════════════════════════════════════════╣"
    echo "  ║  ⚠  DEPRECATED (no longer maintained):                           ║"
    echo "  ║     • Windows client      — windows support has been dropped     ║"
    echo "  ╚══════════════════════════════════════════════════════════════════╝"
    echo ""
}

################################################################################
# 1. Platform selection: list available platforms and create .env symlink
################################################################################
################################################################################
# _pick_platform — interactive platform selection (no side effects)
#
# Displays the platform list, reads user choice, validates input.
# On success: sets global TARGET_PLATFORM and returns 0.
# On failure: returns 1.
#
# Safe to call from $() — all display goes to /dev/tty,
# only the return code and TARGET_PLATFORM variable matter.
################################################################################
_pick_platform() {
    TARGET_DIR="${PLATFORM_ENV_SRC_DIR}"
    declare -a platforms_array=()

    # ── collect platforms; read CHIP_FAMILY, CHIP_EXTRACT_NAME, OS_VERSION, PORT_SLOT ──
    declare -A _slot_map       # basename → slot (numeric, 999 if none)
    declare -A _family_map     # basename → CHIP_FAMILY
    declare -A _extract_map    # basename → CHIP_EXTRACT_NAME
    declare -A _os_map         # basename → OS_VERSION

    for file_path in "${TARGET_DIR}"/*.env; do
        [[ ! -f "${file_path}" ]] && continue
        local filename basename slot family extract os_ver
        filename="$(basename "${file_path}")"
        basename="${filename%.env}"
        slot=$(grep -oP '^\s*PORT_SLOT\s*=\s*"?\K[0-9]+' "${file_path}" 2>/dev/null || echo "")
        family=$(grep -oP '^\s*CHIP_FAMILY\s*=\s*"?\K[^"]+' "${file_path}" 2>/dev/null || echo "")
        extract=$(grep -oP '^\s*CHIP_EXTRACT_NAME\s*=\s*"?\K[^"]+' "${file_path}" 2>/dev/null || echo "")
        os_ver=$(grep -oP '^\s*OS_VERSION\s*=\s*"?\K[^"]+' "${file_path}" 2>/dev/null || echo "")
        _slot_map["${basename}"]="${slot:-999}"
        _family_map["${basename}"]="${family:-unknown}"
        _extract_map["${basename}"]="${extract:-${basename}}"
        _os_map["${basename}"]="${os_ver:-?}"
    done

    # Sort by CHIP_FAMILY first, then by PORT_SLOT within the same family
    while IFS= read -r line; do
        platforms_array+=("${line}")
    done < <(
        for name in "${!_slot_map[@]}"; do
            local fam="${_family_map[$name]}"
            local slot="${_slot_map[$name]}"
            printf '%s %03d %s\n' "${fam}" "${slot}" "${name}"
        done | sort | awk '{print $3}'
    )

    #-------------------------------------------------------
    if [ "${#platforms_array[@]}" == "0" ]; then
        echo "No platforms exists, return now" >/dev/tty
        return 1
    fi

    echo "" >/dev/tty
    echo "  ╔══════════════════════════════════════════════════════════════════╗" >/dev/tty
    echo "  ║                      Select Platform                             ║" >/dev/tty
    echo "  ╠══════════════════════════════════════════════════════════════════╣" >/dev/tty
    echo "  ║                                                                  ║" >/dev/tty

    local i=0
    local prev_family=""
    for platform in "${platforms_array[@]}"; do
        ((++i))
        local fam="${_family_map[$platform]}"
        local extract="${_extract_map[$platform]}"
        local os_ver="${_os_map[$platform]}"
        local slot="${_slot_map[$platform]}"
        local slot_label="slot=${slot}"
        [[ "${slot}" == "999" ]] && slot_label="(manual)"

        # Print family header when family changes
        if [[ "${fam}" != "${prev_family}" ]]; then
            [[ -n "${prev_family}" ]] && echo "  ║                                                                  ║" >/dev/tty
            printf "  ║  ── %-60s ║\n" "${fam}" >/dev/tty
            prev_family="${fam}"
        fi

        # Dynamic padding: compute remaining space to fill 66-char inner width
        local _content="  [${i}]  ${extract}  os=${os_ver}  ${slot_label}"
        local _pad=$(( 66 - ${#_content} ))
        [[ ${_pad} -lt 0 ]] && _pad=0
        printf "  ║%s%*s║\n" "${_content}" "${_pad}" "" >/dev/tty
    done

    echo "  ║                                                                  ║" >/dev/tty
    local create_idx=$(( i + 1 ))
    local _create="  [${create_idx}]  Create new platform"
    local _pad_create=$(( 66 - ${#_create} ))
    [[ ${_pad_create} -lt 0 ]] && _pad_create=0
    printf "  ║%s%*s║\n" "${_create}" "${_pad_create}" "" >/dev/tty
    echo "  ║                                                                  ║" >/dev/tty
    echo "  ╚══════════════════════════════════════════════════════════════════╝" >/dev/tty
    echo "" >/dev/tty

    #-------------------------------------------------------
    read -p "  Please select [1-${create_idx}]: " user_type </dev/tty

    platform_number="$((${#platforms_array[@]}))"

    if ! [[ "${user_type}" =~ ^[0-9]+$ ]]; then
        echo "✗ Error: Invalid input. Please enter a number." >/dev/tty
        return 1
    fi

    # Handle "Create new platform" selection
    if [ "${user_type}" -eq "${create_idx}" ]; then
        if "${TOP_ROOT_DIR}/scripts/create_platform.sh"; then
            echo "Platform created. Reloading platform list..." >/dev/tty
            return 1  # return 1 triggers the while-true retry
        else
            echo "Platform creation cancelled or failed." >/dev/tty
            return 1
        fi
    fi

    if [ ${user_type} -lt 1 ] || [ ${user_type} -gt ${platform_number} ]; then
        echo "$user_type is not valid, please input from 1 to ${platform_number}" >/dev/tty
        return 1
    fi

    TARGET_PLATFORM="${platforms_array[((${user_type} - 1))]}"
    return 0
}

################################################################################
# 1.5 Select host configuration
# Host is the primary user object. Platform is resolved automatically
# via BASE_PLATFORM in the host config.
################################################################################
_select_host_config() {
    LOCAL_HOSTNAME=$(hostname)
    HOST_CONFIG="${TOP_CONFIGS_DIR}/3_hosts/${LOCAL_HOSTNAME}.env"

    # Scan for all existing host configs
    declare -a host_configs=()
    for host_file in "${TOP_CONFIGS_DIR}/3_hosts/"*.env; do
        [[ ! -f "${host_file}" ]] && continue
        local basename
        basename="$(basename "${host_file}" .env)"
        host_configs+=("${basename}")
    done

    local host_count=${#host_configs[@]}

    # If no host configs exist, force create one
    if [[ $host_count -eq 0 ]]; then
        echo ""
        echo "  ╔══════════════════════════════════════════════════════════════════╗"
        echo "  ║              No Host Configurations Found                        ║"
        echo "  ╠══════════════════════════════════════════════════════════════════╣"
        echo "  ║                                                                  ║"
        echo "  ║  A host config is required to build.                             ║"
        echo "  ║  It defines which platform to use and host-specific settings.    ║"
        echo "  ║                                                                  ║"
        printf "  ║  [1]  Create host config for this machine (%-20s)║\n" "${LOCAL_HOSTNAME})"
        echo "  ║                                                                  ║"
        echo "  ╚══════════════════════════════════════════════════════════════════╝"
        echo ""
        read -p "  Please select [1]: " _config_choice
        _create_host_config
        read -p "  Build this host now? (y/N): " _build_choice
        if [[ "${_build_choice}" =~ ^[yY]$ ]]; then
            _load_host_config "$(basename "${HOST_CONFIG}" .env)"
        else
            echo "  → Build cancelled. You can build anytime by running './harbor'."
            _HARBOR_SKIP_BUILD=1
        fi
        return
    fi

    # Build menu with host configs
    echo ""
    echo "  ╔══════════════════════════════════════════════════════════════════╗"
    echo "  ║                    Select Host Configuration                     ║"
    echo "  ╠══════════════════════════════════════════════════════════════════╣"
    echo "  ║                                                                  ║"

    local idx=1
    for host_name in "${host_configs[@]}"; do
        # Read BASE_PLATFORM from host config for display
        local host_file="${TOP_CONFIGS_DIR}/3_hosts/${host_name}.env"
        local base_platform
        base_platform=$(grep -E '^BASE_PLATFORM=' "${host_file}" 2>/dev/null | head -1 | sed 's/^BASE_PLATFORM=//;s/^"//;s/"$//' | tr -d "'")
        [[ -z "${base_platform}" ]] && base_platform="(legacy — no BASE_PLATFORM)"

        local marker=""
        [[ "${host_name}" == "${LOCAL_HOSTNAME}" || "${host_name}" == ${LOCAL_HOSTNAME}_* ]] && marker="  ← this machine"

        # Line 1: host name + marker (dynamic padding to 66-char inner width)
        local _line1="  [${idx}]  ${host_name}${marker}"
        local _pad1=$(( 66 - ${#_line1} ))
        [[ ${_pad1} -lt 0 ]] && _pad1=0
        printf "  ║%s%*s║\n" "${_line1}" "${_pad1}" ""

        # Line 2: platform info (indented to align with host name)
        local _line2="       platform: ${base_platform}"
        local _pad2=$(( 66 - ${#_line2} ))
        [[ ${_pad2} -lt 0 ]] && _pad2=0
        printf "  ║%s%*s║\n" "${_line2}" "${_pad2}" ""
        ((idx++))
    done

    echo "  ║                                                                  ║"
    local _create="  [${idx}]  Create new host  — configure for a new machine"
    local _pad_create=$(( 66 - ${#_create} ))
    [[ ${_pad_create} -lt 0 ]] && _pad_create=0
    printf "  ║%s%*s║\n" "${_create}" "${_pad_create}" ""
    echo "  ║                                                                  ║"
    echo "  ╚══════════════════════════════════════════════════════════════════╝"
    echo ""

    local max_option=${idx}

    read -p "  Please select [1-${max_option}]: " _config_choice

    if [[ "${_config_choice}" -eq "${max_option}" ]]; then
        # Create new host config
        _create_host_config
        read -p "  Build this host now? (y/N): " _build_choice
        if [[ "${_build_choice}" =~ ^[yY]$ ]]; then
            _load_host_config "$(basename "${HOST_CONFIG}" .env)"
        else
            echo "  → Build cancelled. You can build anytime by running './harbor'."
            _select_host_config
        fi
    elif [[ "${_config_choice}" -ge 1 && "${_config_choice}" -lt "${max_option}" ]]; then
        # Load existing host config
        local host_idx=$(( _config_choice - 1 ))
        local selected_host="${host_configs[$host_idx]}"
        _load_host_config "${selected_host}"
    else
        echo "  ✗ Invalid choice."
        _select_host_config
    fi
}

################################################################################
# Create a new host configuration file
################################################################################
_create_host_config() {
    # DEBUG: trace what was passed in
    echo "[DEBUG] _create_host_config called with \$1='${1:-<empty>}'"
    echo "[DEBUG] \$1 hex: $(echo -n "${1:-}" | xxd -p)"
    echo "[DEBUG] BUILD_SCRIPT_DIR='${BUILD_SCRIPT_DIR:-<unset>}'"
    echo "[DEBUG] TOP_CONFIGS_DIR='${TOP_CONFIGS_DIR:-<unset>}'"

    LOCAL_HOSTNAME=$(hostname)
    local TEMPLATE="${TOP_CONFIGS_DIR}/3_hosts/TEMPLATE.env.example"
    local total_questions=5  # Questions after platform selection

    # Step 1: Select a base platform FIRST (determines filename)
    echo ""
    echo "  ╔══════════════════════════════════════════════════════════════════╗"
    echo "  ║                    Create Host Configuration                     ║"
    echo "  ╠══════════════════════════════════════════════════════════════════╣"
    echo "  ║                                                                  ║"
    printf "  ║  Hostname: %-52s║\n" "${LOCAL_HOSTNAME}"
    echo "  ║                                                                  ║"
    echo "  ║  Step 1: Select a base platform for this host                    ║"
    echo "  ║                                                                  ║"
    echo "  ╚══════════════════════════════════════════════════════════════════╝"
    echo ""
    local selected_platform=""
    while true; do
        if _pick_platform; then
            selected_platform="${TARGET_PLATFORM}"
            break
        fi
    done
    echo "  → Selected platform: ${selected_platform}"

    # Source platform config so HARBOR_SERVER_IP, CHIP_FAMILY etc. are available
    local platform_env="${TOP_CONFIGS_DIR}/2_platforms/${selected_platform}.env"
    if [ -f "${platform_env}" ]; then
        source "${platform_env}"
    fi

    # Derive filename from hostname + platform
    HOST_CONFIG="${TOP_CONFIGS_DIR}/3_hosts/${LOCAL_HOSTNAME}_${selected_platform}.env"

    echo ""
    printf "  ║  File:     %-52s║\n" "${HOST_CONFIG}"
    echo ""

    if [ -f "${HOST_CONFIG}" ]; then
        echo "  ⚠️  Host config already exists: ${HOST_CONFIG}"
        if ! prompt_simple "Overwrite existing config?" "" "" "n"; then
            echo "  → Cancelled."
            _select_host_config
            return
        fi
    fi

    # Step 0: Copy template as starting point
    if [[ ! -f "${TEMPLATE}" ]]; then
        echo "  ✗ Error: Template not found: ${TEMPLATE}"
        return 1
    fi
    cp "${TEMPLATE}" "${HOST_CONFIG}"
    echo "  → Copied template to ${HOST_CONFIG}"

    # Now configure host-specific overrides with guided prompts
    echo ""
    echo "  ╔══════════════════════════════════════════════════════════════════╗"
    echo "  ║                                                                  ║"
    echo "  ║  Step 2: Configure host-specific overrides                       ║"
    echo "  ║                                                                  ║"
    echo "  ╚══════════════════════════════════════════════════════════════════╝"

    # Question 1: HOST_VOLUME_DIR (required — no universal default)
    local _fallback_vol="/mnt/ssd/docker-volumes/\${PRODUCT_NAME}"
    local default_volume_dir="${1:-${_fallback_vol}}"
    local host_volume_dir=""
    echo ""
    echo "  (1/${total_questions}) Docker volumes directory on this host"
    echo "      This is where container volumes are stored."
    echo "      Default: ${default_volume_dir}"
    echo ""
    read -p "  Enter HOST_VOLUME_DIR path [${default_volume_dir}]: " host_volume_dir
    if [ -z "${host_volume_dir}" ]; then
        host_volume_dir="${default_volume_dir}"
        echo "  → Using default: ${host_volume_dir}"
    else
        echo "  → Volume dir set to: ${host_volume_dir}"
    fi

    # Question 2: GPU (recommend: no for most machines)
    local use_gpu="false"
    if prompt_simple "Does this machine have an NVIDIA GPU?" "2" "${total_questions}" "n"; then
        use_gpu="true"
    fi

    # Question 3: SHM size
    local shm_size="256m"
    if [[ "${use_gpu}" == "true" ]]; then
        shm_size="1g"
        if prompt_simple "Set SHM size to 1g for GPU?" "3" "${total_questions}" "y"; then
            echo "  → SHM size set to ${shm_size}"
        else
            shm_size="2g"
            echo "  → SHM size set to ${shm_size}"
        fi
    else
        if prompt_simple "Set SHM size to 512m? (default is 256m)" "3" "${total_questions}" "n"; then
            shm_size="512m"
            echo "  → SHM size set to ${shm_size}"
        else
            echo "  → SHM size set to ${shm_size} (default)"
        fi
    fi

    # Question 4: Network mode (recommend: yes for production)
    local network_mode="bridge"
    if prompt_simple "Use host network mode?" "4" "${total_questions}" "y"; then
        network_mode="host"
        echo "  → Network mode set to host"
    else
        echo "  → Network mode set to bridge (default)"
    fi

    # Question 5: Auto-start container (recommend: yes)
    local auto_restart="no"
    if prompt_simple "Auto-restart container on boot?" "5" "${total_questions}" "y"; then
        auto_restart="unless-stopped"
        echo "  → Container will auto-restart on boot"
    else
        echo "  → Container will not auto-restart"
    fi

    # Apply user choices to the copied template
    # Use '|' as sed delimiter to avoid conflicts with '/' in file paths
    sed -i "s|^# BASE_PLATFORM=.*|BASE_PLATFORM=\"${selected_platform}\"|" "${HOST_CONFIG}"
    sed -i "s|^# HOST_VOLUME_DIR=.*|HOST_VOLUME_DIR=\"${host_volume_dir}\"|" "${HOST_CONFIG}"
    sed -i "s|^# USE_NVIDIA_GPU=.*|USE_NVIDIA_GPU=\"${use_gpu}\"|" "${HOST_CONFIG}"
    sed -i "s|^# CONTAINER_SHM_SIZE=.*|CONTAINER_SHM_SIZE=\"${shm_size}\"|" "${HOST_CONFIG}"
    sed -i "s|^# NETWORK_MODE=.*|NETWORK_MODE=\"${network_mode}\"|" "${HOST_CONFIG}"
    sed -i "s|^# CONTAINER_RESTART_POLICY=.*|CONTAINER_RESTART_POLICY=\"${auto_restart}\"|" "${HOST_CONFIG}"

    # Auto-derive REGISTRY_URL from platform values (HARBOR_SERVER_IP + PORT + CHIP_FAMILY)
    if [ -n "${HARBOR_SERVER_IP:-}" ] && [ -n "${HARBOR_SERVER_PORT:-}" ] && [ -n "${CHIP_FAMILY:-}" ]; then
        local derived_registry_url="${HARBOR_SERVER_IP}:${HARBOR_SERVER_PORT}/team_${CHIP_FAMILY}"
        sed -i "s|^# REGISTRY_URL=.*|REGISTRY_URL=\"${derived_registry_url}\"|" "${HOST_CONFIG}"
        echo "  → REGISTRY_URL auto-derived: ${derived_registry_url}"
    fi

    echo ""
    echo "  -----"
    echo ""
    echo "  ✅ Host config created: $(basename "${HOST_CONFIG}")"
    echo "  → File: ${HOST_CONFIG}"
    echo "  → Use: ./harbor --host $(basename "${HOST_CONFIG}" .env)"
    echo ""

    return 0
}

################################################################################
# Load an existing host configuration
# Platform is resolved via BASE_PLATFORM in the host config (no user action needed)
################################################################################
_load_host_config() {
    local host_name="$1"
    HOST_CONFIG="${TOP_CONFIGS_DIR}/3_hosts/${host_name}.env"

    if [ ! -f "${HOST_CONFIG}" ]; then
        echo "  ✗ Error: Host config not found: ${HOST_CONFIG}"
        _select_host_config
        return
    fi

    # Read BASE_PLATFORM for display
    local base_platform
    base_platform=$(grep -E '^BASE_PLATFORM=' "${HOST_CONFIG}" | head -1 | sed 's/^BASE_PLATFORM=//;s/^"//;s/"$//' | tr -d "'")

    echo ""
    echo "  -----"
    echo ""
    echo "  ✅ Host config loaded: ${host_name}"
    if [ -n "${base_platform}" ]; then
        echo "  → Platform: ${base_platform} (from BASE_PLATFORM)"
    else
        echo "  → Platform: (legacy — from .env symlink)"
    fi
    echo ""
}

################################################################################
# 1.5 Check and prompt for host configuration
# If no host config exists, explain the options to the user
################################################################################
_check_and_prompt_host_config() {
    LOCAL_HOSTNAME=$(hostname)
    HOST_CONFIG="${TOP_CONFIGS_DIR}/3_hosts/${LOCAL_HOSTNAME}.env"

    echo ""
    echo "  ╔══════════════════════════════════════════════════════════════════╗"
    echo "  ║                    Host Configuration Check                      ║"
    echo "  ╠══════════════════════════════════════════════════════════════════╣"
    echo "  ║                                                                  ║"
    printf "  ║  Hostname: %-53s║\n" "${LOCAL_HOSTNAME}"
    printf "  ║  Config:   %-53s║\n" "${HOST_CONFIG}"
    echo "  ║                                                                  ║"

    if [ -f "${HOST_CONFIG}" ]; then
        echo "  ║  ✅ Host config found!                                            ║"
        echo "  ║                                                                  ║"
        echo "  ║  The following host-specific overrides will be applied:          ║"
        echo "  ║                                                                  ║"
        # Show first 5 non-comment, non-empty lines
        local count=0
        while IFS= read -r line; do
            [[ -z "${line}" || "${line}" =~ ^[[:space:]]*# ]] && continue
            printf "  ║    %-60s║\n" "${line}"
            ((count++))
            [[ $count -ge 5 ]] && break
        done < "${HOST_CONFIG}"
        if [[ $count -ge 5 ]]; then
            echo "  ║    ... (more overrides in file)                                  ║"
        fi
        echo "  ║                                                                  ║"
        echo "  ║  These overrides customize the platform config for this machine. ║"
        echo "  ║  They will NOT affect the Docker image, only runtime behavior.   ║"
    else
        echo "  ║  ⚠️  No host-specific config found for this machine.             ║"
        echo "  ║                                                                  ║"
        echo "  ║  You have two options:                                           ║"
        echo "  ║                                                                  ║"
        echo "  ║  Option 1: Use platform defaults (recommended if they fit)       ║"
        echo "  ║    → The selected platform config will be used as-is.            ║"
        echo "  ║    → No action needed, just continue.                            ║"
        echo "  ║                                                                  ║"
        echo "  ║  Option 2: Create host-specific overrides                        ║"
        echo "  ║    → Only if you need to customize for this machine:             ║"
        echo "  ║      • GPU settings (USE_NVIDIA_GPU)                             ║"
        echo "  ║      • Network/IP addresses (HARBOR_SERVER_IP, CLIENT_IP)        ║"
        echo "  ║      • Volume paths (HOST_VOLUME_DIR)                            ║"
        echo "  ║      • Other machine-specific settings                           ║"
        echo "  ║                                                                  ║"
        echo "  ║  To create:                                                      ║"
        printf "  ║    echo 'YOUR_VARS' > configs/3_hosts/%-25s║\n" "${LOCAL_HOSTNAME}.env"
        echo "  ║                                                                  ║"
        echo "  ║  📌 Note: Host configs are gitignored and NOT part of the image.  ║"
        echo "  ║     They only exist on this machine for runtime customization.   ║"
    fi

    echo "  ║                                                                  ║"
    echo "  ╚══════════════════════════════════════════════════════════════════╝"
    echo ""

    if [ ! -f "${HOST_CONFIG}" ]; then
        if prompt_with_timeout "Continue with platform defaults? (Select 'n' to abort and create host config)" 15; then
            echo "  → Using platform defaults."
        else
            echo "  → Aborted. Create host config and try again."
            echo "     See configs/3_hosts/README.md for details."
            exit 0
        fi
    fi
}
