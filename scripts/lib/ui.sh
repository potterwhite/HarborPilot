#!/bin/bash
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
                    _load_host_config "${LOCAL_HOSTNAME}"
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
    local clientside_script="${BUILD_SCRIPT_DIR}/project_handover/clientside/ubuntu/ubuntu_only_entrance.sh"

    echo ""
    echo "  ╔══════════════════════════════════════════════════════════════════╗"
    echo "  ║                  BUILD COMPLETE — NEXT STEPS                     ║"
    echo "  ╠══════════════════════════════════════════════════════════════════╣"
    echo "  ║                                                                  ║"
    echo "  ║  Image  : ${IMAGE_NAME}:${PROJECT_VERSION}"
    echo "  ║  Platform: ${PRODUCT_NAME}"
    echo "  ║                                                                  ║"
    echo "  ║  To start your development container (Ubuntu host):              ║"
    echo "  ║                                                                  ║"
    echo "  ║    ${clientside_script}"
    echo "  ║                                                                  ║"
    echo "  ║  Supported commands:                                             ║"
    echo "  ║    start     — create and start the container                    ║"
    echo "  ║    stop      — stop the running container                        ║"
    echo "  ║    restart   — restart the container                             ║"
    echo "  ║    recreate  — remove and recreate the container                 ║"
    echo "  ║    remove    — stop and remove the container                     ║"
    echo "  ║                                                                  ║"
    echo "  ║  Example:                                                        ║"
    echo "  ║    ./project_handover/clientside/ubuntu/ubuntu_only_entrance.sh start"
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
    echo "Now we have below platforms:" >/dev/tty
    echo "" >/dev/tty

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
            [[ -n "${prev_family}" ]] && echo "" >/dev/tty
            echo -e "  ── ${fam} ──" >/dev/tty
            prev_family="${fam}"
        fi

        printf "    [%d] %-14s  os=%-5s  %s\n" "${i}" "${extract}" "${os_ver}" "${slot_label}" >/dev/tty
    done

    echo "" >/dev/tty
    local create_idx=$(( i + 1 ))
    echo -e "  [${create_idx}].${_CREATE_PLATFORM_LABEL:-+ Create new platform}" >/dev/tty

    #-------------------------------------------------------
    read -p "Please type the index your choice: " user_type </dev/tty

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
# 1_specify_platform — full interactive platform setup (legacy entry point)
#
# Calls _pick_platform() for selection, then creates the .env symlink.
# Used by harbor's main menu for standalone platform selection.
################################################################################
1_specify_platform() {
    if ! _pick_platform; then
        return 1
    fi

    local target_platform="${TARGET_PLATFORM}"
    echo ${target_platform}
    cd ${TOP_ROOT_DIR}

    # create configs/2_platforms/.env symlink
    if [ -e ${PLATFORM_ENV_DEST_PATH} ]; then
        rm -f ${PLATFORM_ENV_DEST_PATH}
    fi
    ln -sf "${PLATFORM_ENV_SRC_DIR}/${target_platform}.env" "${PLATFORM_ENV_DEST_PATH}"

    ls -lha ${PLATFORM_ENV_DEST_PATH}

    echo
    echo "--- Setup env files (${target_platform}) Successfully ---"
    echo
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
            _load_host_config "${LOCAL_HOSTNAME}"
        else
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
        [[ "${host_name}" == "${LOCAL_HOSTNAME}" ]] && marker=" ← this machine"
        printf "  ║  [%d]  %-20s platform: %-24s%s║\n" "${idx}" "${host_name}" "${base_platform}" "${marker}"
        ((idx++))
    done

    echo "  ║                                                                  ║"
    echo "  ║  [${idx}]  Create new host    — configure for a new machine      ║"
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
            _load_host_config "${LOCAL_HOSTNAME}"
        else
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
    LOCAL_HOSTNAME=$(hostname)
    HOST_CONFIG="${TOP_CONFIGS_DIR}/3_hosts/${LOCAL_HOSTNAME}.env"
    local total_questions=5  # Questions after platform selection

    echo ""
    echo "  ╔══════════════════════════════════════════════════════════════════╗"
    echo "  ║                    Create Host Configuration                     ║"
    echo "  ╠══════════════════════════════════════════════════════════════════╣"
    echo "  ║                                                                  ║"
    printf "  ║  Hostname: %-52s║\n" "${LOCAL_HOSTNAME}"
    printf "  ║  File:     %-52s║\n" "${HOST_CONFIG}"
    echo "  ║                                                                  ║"
    echo "  ║  This will create a host-specific config file.                   ║"
    echo "  ║You'll be guided through 1 platform + ${total_questions} settings.║"
    echo "  ║                                                                  ║"
    echo "  ╚══════════════════════════════════════════════════════════════════╝"
    echo ""

    if [ -f "${HOST_CONFIG}" ]; then
        echo "  ⚠️  Host config already exists: ${HOST_CONFIG}"
        if ! prompt_simple "Overwrite existing config?" "" "" "n"; then
            echo "  → Cancelled."
            _select_host_config
            return
        fi
    fi

    # First, select a base platform
    echo ""
    echo "  ╔══════════════════════════════════════════════════════════════════╗"
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

    # Now create the host config with guided prompts
    echo ""
    echo "  ╔══════════════════════════════════════════════════════════════════╗"
    echo "  ║                                                                  ║"
    echo "  ║  Step 2: Configure host-specific overrides                       ║"
    echo "  ║                                                                  ║"
    echo "  ╚══════════════════════════════════════════════════════════════════╝"

    # Question 1: HOST_VOLUME_DIR (required — no universal default)
    local host_volume_dir=""
    echo ""
    echo "  (1/${total_questions}) Docker volumes directory on this host"
    echo "      This is where container volumes are stored."
    echo "      Recommended: /mnt/ssd/docker-volumes/\${PRODUCT_NAME}"
    echo ""
    read -p "  Enter HOST_VOLUME_DIR path: " host_volume_dir
    if [ -z "${host_volume_dir}" ]; then
        host_volume_dir="/mnt/ssd/docker-volumes/\${PRODUCT_NAME}"
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

    # Write the host config
    cat > "${HOST_CONFIG}" << EOF
################################################################################
# Host-Level Configuration for ${LOCAL_HOSTNAME}
# Auto-generated by HarborPilot wizard on $(date +%Y-%m-%d)
# This file is gitignored and NOT part of the Docker image
################################################################################

# =============================================================================
# Platform Reference  [REQUIRED]
# =============================================================================
BASE_PLATFORM="${selected_platform}"

# =============================================================================
# Volume Paths
# =============================================================================
HOST_VOLUME_DIR="${host_volume_dir}"
# EXTRA_VOLUME_0="/home/username/notes:/volumes_notes"

# =============================================================================
# Hardware
# =============================================================================
USE_NVIDIA_GPU="${use_gpu}"
CONTAINER_SHM_SIZE="${shm_size}"

# =============================================================================
# Network
# =============================================================================
NETWORK_MODE="${network_mode}"
CONTAINER_RESTART_POLICY="${auto_restart}"

# =============================================================================
# Proxy (uncomment if needed)
# =============================================================================
# HAS_PROXY="true"
# HTTP_PROXY_IP="192.168.3.67"
# HTTPS_PROXY_IP="192.168.3.67"
# NPM_USE_CHINA_MIRROR="true"

# =============================================================================
# Server Connectivity (uncomment to override defaults)
# =============================================================================
# HAVE_GITLAB_SERVER="TRUE"
# GITLAB_SERVER_IP="192.168.3.67"
# GITLAB_SERVER_PORT="80"
# HARBOR_SERVER_IP="192.168.3.67"
# HARBOR_SERVER_PORT="9000"
EOF

    echo ""
    echo "  -----"
    echo ""
    echo "  ✅ Host config created: ${LOCAL_HOSTNAME}.env"
    echo "  → File: ${HOST_CONFIG}"
    echo "  → Auto-loaded when you run './harbor' on ${LOCAL_HOSTNAME}"
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
