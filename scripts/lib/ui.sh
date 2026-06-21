#!/bin/bash
################################################################################
# Module: ui.sh
# Description: UI interaction functions for HarborPilot
# Functions: prompt_with_timeout, prompt_simple, 0_show_main_menu,
#            1_specify_platform, _select_config_source, _create_host_config,
#            _load_host_config, _check_and_prompt_host_config, _print_next_steps
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
    echo "  ║  (Press Enter for recommended option)                           ║"
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
# 0. Top-level action menu: Build or Package
# Sets _HARBOR_MODE to "build" or "package"
################################################################################
0_show_main_menu() {
    echo ""
    echo "  ╔══════════════════════════════════════════════════════════════════╗"
    echo "  ║                      HarborPilot — Main Menu                    ║"
    echo "  ╠══════════════════════════════════════════════════════════════════╣"
    echo "  ║                                                                  ║"
    echo "  ║  [1]  Build & Push          — build image and push to registry  ║"
    echo "  ║  [2]  Package Handover      — create client delivery tarball    ║"
    echo "  ║                                                                  ║"
    echo "  ╚══════════════════════════════════════════════════════════════════╝"
    echo ""

    while true; do
        read -p "  Please select [1-2]: " _menu_choice
        case "${_menu_choice}" in
            1)
                _HARBOR_MODE="build"
                echo "  → Build & Push selected."
                echo ""
                break
                ;;
            2)
                _HARBOR_MODE="package"
                echo "  → Package Handover selected."
                echo ""
                break
                ;;
            *)
                echo "  ✗ Invalid choice. Please enter 1 or 2."
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
    echo "  ║                  BUILD COMPLETE — NEXT STEPS                    ║"
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
    echo "  ║  ⚠  DEPRECATED (no longer maintained):                          ║"
    echo "  ║     • Windows client      — windows support has been dropped    ║"
    echo "  ╚══════════════════════════════════════════════════════════════════╝"
    echo ""
}

################################################################################
# 1. Platform selection: list available platforms and create .env symlink
################################################################################
1_specify_platform() {
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
    # Build sort key: "<family> <slot_padded> <basename>"
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
        echo "No platforms exists, return now"
        return 1
    fi

    echo
    echo "Now we have below platforms:"
    echo ""

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
            [[ -n "${prev_family}" ]] && echo ""
            echo -e "  ── ${fam} ──"
            prev_family="${fam}"
        fi

        printf "    [%d] %-14s  os=%-5s  %s\n" "${i}" "${extract}" "${os_ver}" "${slot_label}"
    done

    echo ""
    local create_idx=$(( i + 1 ))
    echo -e "  [${create_idx}].${_CREATE_PLATFORM_LABEL:-+ Create new platform}"

    #-------------------------------------------------------
    read -p "Please type the index your choice: " user_type

    platform_number="$((${#platforms_array[@]}))"

    if ! [[ "${user_type}" =~ ^[0-9]+$ ]]; then
        echo "✗ Error: Invalid input. Please enter a number."
        return 1
    fi

    # Handle "Create new platform" selection
    if [ "${user_type}" -eq "${create_idx}" ]; then
        if "${TOP_ROOT_DIR}/scripts/create_platform.sh"; then
            echo "Platform created. Reloading platform list..."
            return 1  # return 1 triggers the while-true retry in main()
        else
            echo "Platform creation cancelled or failed."
            return 1
        fi
    fi

    if [ ${user_type} -lt 1 ] || [ ${user_type} -gt ${platform_number} ]; then
        echo "$user_type is not valid, please input from 1 to ${platform_number}"
        return 1
    fi

    target_platform="${platforms_array[((${user_type} - 1))]}"
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
# 1.5 Select configuration source: platform or host
# Scans for existing host configs and presents unified menu
################################################################################
_select_config_source() {
    LOCAL_HOSTNAME=$(hostname)
    HOST_CONFIG="${TOP_CONFIGS_DIR}/3_host/${LOCAL_HOSTNAME}.env"

    # Scan for all existing host configs
    declare -a host_configs=()
    for host_file in "${TOP_CONFIGS_DIR}/3_host/"*.env; do
        [[ ! -f "${host_file}" ]] && continue
        local basename
        basename="$(basename "${host_file}" .env)"
        host_configs+=("${basename}")
    done

    # Build menu options
    echo ""
    echo "  ╔══════════════════════════════════════════════════════════════════╗"
    echo "  ║                    Configuration Source                         ║"
    echo "  ╠══════════════════════════════════════════════════════════════════╣"
    echo "  ║                                                                  ║"
    echo "  ║  Choose how to configure this build:                             ║"
    echo "  ║                                                                  ║"
    echo "  ║  [1]  Select existing platform     — use a platform config as-is ║"
    echo "  ║  [2]  Create new platform          — define a new platform       ║"
    echo "  ║                                                                  ║"

    local host_start_idx=3
    local host_count=${#host_configs[@]}

    if [[ $host_count -gt 0 ]]; then
        echo "  ║  Existing host configs (machine-specific overrides):            ║"
        echo "  ║                                                                  ║"
        local idx=$host_start_idx
        for host_name in "${host_configs[@]}"; do
            local marker=""
            [[ "${host_name}" == "${LOCAL_HOSTNAME}" ]] && marker=" ← this machine"
            printf "  ║  [%d]  %-20s%-30s║\n" "${idx}" "${host_name}" "${marker}"
            ((idx++))
        done
        echo "  ║                                                                  ║"
        echo "  ║  [${idx}]  Create new host config — customize for a specific machine ║"
    else
        echo "  ║  [3]  Create new host config       — customize for this machine ║"
    fi

    echo "  ║                                                                  ║"
    echo "  ╚══════════════════════════════════════════════════════════════════╝"
    echo ""

    local max_option=$((host_start_idx + host_count))
    [[ $host_count -eq 0 ]] && max_option=3

    read -p "  Please select [1-${max_option}]: " _config_choice

    case "${_config_choice}" in
        1)
            # Select existing platform
            while true; do
                1_specify_platform
                if [ $? -eq 0 ]; then
                    break
                fi
            done
            _check_and_prompt_host_config
            ;;
        2)
            # Create new platform
            if "${TOP_ROOT_DIR}/scripts/create_platform.sh"; then
                echo "Platform created. Reloading..."
                _select_config_source
            else
                echo "Platform creation cancelled."
                _select_config_source
            fi
            ;;
        ${max_option})
            # Create new host config
            _create_host_config
            ;;
        *)
            # Check if it's an existing host selection
            if [[ $_config_choice -ge $host_start_idx && $_config_choice -lt $max_option ]]; then
                local host_idx=$(( _config_choice - host_start_idx ))
                local selected_host="${host_configs[$host_idx]}"
                _load_host_config "${selected_host}"
            else
                echo "  ✗ Invalid choice."
                _select_config_source
            fi
            ;;
    esac
}

################################################################################
# Create a new host configuration file
################################################################################
_create_host_config() {
    LOCAL_HOSTNAME=$(hostname)
    HOST_CONFIG="${TOP_CONFIGS_DIR}/3_host/${LOCAL_HOSTNAME}.env"
    local total_questions=5  # Total questions to ask

    echo ""
    echo "  ╔══════════════════════════════════════════════════════════════════╗"
    echo "  ║                    Create Host Configuration                    ║"
    echo "  ╠══════════════════════════════════════════════════════════════════╣"
    echo "  ║                                                                  ║"
    printf "  ║  Hostname: %-52s║\n" "${LOCAL_HOSTNAME}"
    printf "  ║  File:     %-52s║\n" "${HOST_CONFIG}"
    echo "  ║                                                                  ║"
    echo "  ║  This will create a host-specific config file.                  ║"
    echo "  ║  You'll be guided through ${total_questions} questions.                           ║"
    echo "  ║                                                                  ║"
    echo "  ╚══════════════════════════════════════════════════════════════════╝"
    echo ""

    if [ -f "${HOST_CONFIG}" ]; then
        echo "  ⚠️  Host config already exists: ${HOST_CONFIG}"
        if ! prompt_simple "Overwrite existing config?" "1" "${total_questions}" "n"; then
            echo "  → Cancelled."
            _select_config_source
            return
        fi
    fi

    # First, select a base platform
    echo ""
    echo "  ╔══════════════════════════════════════════════════════════════════╗"
    echo "  ║                                                                  ║"
    echo "  ║  Step 1: Select a base platform for this host                   ║"
    echo "  ║                                                                  ║"
    echo "  ╚══════════════════════════════════════════════════════════════════╝"
    echo ""
    while true; do
        1_specify_platform
        if [ $? -eq 0 ]; then
            break
        fi
    done

    # Now create the host config with guided prompts
    echo ""
    echo "  ╔══════════════════════════════════════════════════════════════════╗"
    echo "  ║                                                                  ║"
    echo "  ║  Step 2: Configure host-specific overrides                      ║"
    echo "  ║                                                                  ║"
    echo "  ╚══════════════════════════════════════════════════════════════════╝"

    # Question 1: GPU (recommend: no for most machines)
    local use_gpu="false"
    if prompt_simple "Does this machine have an NVIDIA GPU?" "2" "${total_questions}" "n"; then
        use_gpu="true"
    fi

    # Question 2: SHM size
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

    # Question 3: Network mode (recommend: yes for production)
    local network_mode="bridge"
    if prompt_simple "Use host network mode?" "4" "${total_questions}" "y"; then
        network_mode="host"
        echo "  → Network mode set to host"
    else
        echo "  → Network mode set to bridge (default)"
    fi

    # Question 4: Auto-start container (recommend: yes)
    local auto_restart="no"
    if prompt_simple "Auto-restart container on boot?" "5" "${total_questions}" "y"; then
        auto_restart="unless-stopped"
        echo "  → Container will auto-restart on boot"
    else
        echo "  → Container will not auto-restart"
    fi

    # Write the host config
    cat > "${HOST_CONFIG}" << EOF
# Host-Level Configuration Overrides for ${LOCAL_HOSTNAME}
# Auto-generated by HarborPilot wizard
# This file is gitignored and NOT part of the Docker image

# GPU Settings
USE_NVIDIA_GPU="${use_gpu}"

# Shared Memory
CONTAINER_SHM_SIZE="${shm_size}"

# Network Settings
NETWORK_MODE="${network_mode}"

# Container Restart Policy
CONTAINER_RESTART_POLICY="${auto_restart}"

# Uncomment and modify as needed:
# HARBOR_SERVER_IP="192.168.1.100"
# CLIENT_IP="192.168.1.101"
# HOST_VOLUME_DIR="/mnt/ssd/volumes"
# EXTRA_VOLUMES_LIST="/path/to/local:/path/in/container"
EOF

    echo ""
    echo "  ╔══════════════════════════════════════════════════════════════════╗"
    echo "  ║                                                                  ║"
    echo "  ║  ✅ Host config created successfully!                           ║"
    echo "  ║                                                                  ║"
    printf "  ║  File: %-56s║\n" "${HOST_CONFIG}"
    echo "  ║                                                                  ║"
    echo "  ║  This config will be auto-loaded when you run './harbor'        ║"
    printf "  ║  on this machine (%-44s)║\n" "${LOCAL_HOSTNAME})"
    echo "  ║                                                                  ║"
    echo "  ╚══════════════════════════════════════════════════════════════════╝"
    echo ""

    if prompt_simple "Continue with build using this host config?"; then
        _load_host_config "${LOCAL_HOSTNAME}"
    else
        _select_config_source
    fi
}

################################################################################
# Load an existing host configuration
################################################################################
_load_host_config() {
    local host_name="$1"
    HOST_CONFIG="${TOP_CONFIGS_DIR}/3_host/${host_name}.env"

    if [ ! -f "${HOST_CONFIG}" ]; then
        echo "  ✗ Error: Host config not found: ${HOST_CONFIG}"
        _select_config_source
        return
    fi

    echo ""
    echo "  ✅ Loading host config: ${host_name}"
    echo ""

    # We still need a platform as base, so load the .env symlink
    # The host config will override specific values
    # Check if .env symlink exists
    if [ ! -e "${PLATFORM_ENV_DEST_PATH}" ]; then
        echo "  ⚠️  No platform selected yet. Please select a base platform:"
        echo ""
        while true; do
            1_specify_platform
            if [ $? -eq 0 ]; then
                break
            fi
        done
    fi

    echo "  → Host config will be applied as Layer 3 overrides."
    echo ""
}

################################################################################
# 1.5 Check and prompt for host configuration
# If no host config exists, explain the options to the user
################################################################################
_check_and_prompt_host_config() {
    LOCAL_HOSTNAME=$(hostname)
    HOST_CONFIG="${TOP_CONFIGS_DIR}/3_host/${LOCAL_HOSTNAME}.env"

    echo ""
    echo "  ╔══════════════════════════════════════════════════════════════════╗"
    echo "  ║                    Host Configuration Check                     ║"
    echo "  ╠══════════════════════════════════════════════════════════════════╣"
    echo "  ║                                                                  ║"
    printf "  ║  Hostname: %-53s║\n" "${LOCAL_HOSTNAME}"
    printf "  ║  Config:   %-53s║\n" "${HOST_CONFIG}"
    echo "  ║                                                                  ║"

    if [ -f "${HOST_CONFIG}" ]; then
        echo "  ║  ✅ Host config found!                                          ║"
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
            echo "  ║    ... (more overrides in file)                                 ║"
        fi
        echo "  ║                                                                  ║"
        echo "  ║  These overrides customize the platform config for this machine. ║"
        echo "  ║  They will NOT affect the Docker image, only runtime behavior.   ║"
    else
        echo "  ║  ⚠️  No host-specific config found for this machine.            ║"
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
        echo "  ║  📌 Note: Host configs are gitignored and NOT part of the image. ║"
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
