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
# File: 04_compose_generator.sh
# Description: Generate docker-compose.yaml dynamically from environment
################################################################################

# =============================================================================
# 4th_group_1st_branch: Ensure VOLUMES_DIR is set
# =============================================================================
compose_generator_4th_1st_ensure_volumes_dir() {
    if [ -z "${VOLUMES_DIR}" ]; then
        local volumes_link="${BUILD_SCRIPT_DIR}/volumes"
        if [ -L "${volumes_link}" ] && [ -e "${volumes_link}" ]; then
            export VOLUMES_DIR="$(realpath "${volumes_link}")"
        else
            utils_print_error "VOLUMES_DIR is not set and volumes symlink is not available"
            return 1
        fi
    fi
}

# =============================================================================
# 4th_group_2nd_branch: Build NVIDIA GPU section
# =============================================================================
compose_generator_4th_2nd_build_gpu_section() {
    local tmp_use="${USE_NVIDIA_GPU:-false}"
    tmp_use="${tmp_use,,}"
    
    if [[ "${tmp_use}" == "true" ]]; then
        COMPOSE_GPU_SETTING=$(cat << 'GPU_EOF'
    shm_size: ${CONTAINER_SHM_SIZE}
    deploy:
        resources:
            reservations:
                devices:
                    - driver: nvidia
                      count: all
                      capabilities: [gpu]
GPU_EOF
)
        echo "NVIDIA GPU Support: ENABLED"
    else
        COMPOSE_GPU_SETTING=""
        echo "NVIDIA GPU Support: DISABLED"
    fi
}

# =============================================================================
# 4th_group_3rd_branch: Build serial device section
# =============================================================================
compose_generator_4th_3rd_build_device_section() {
    if [ -n "${CONTAINER_SERIAL_DEVICE}" ] && [ -e "${CONTAINER_SERIAL_DEVICE}" ]; then
        COMPOSE_DEVICES_SETTING="    devices:
      - ${CONTAINER_SERIAL_DEVICE}:${CONTAINER_SERIAL_DEVICE}"
    else
        COMPOSE_DEVICES_SETTING=""
    fi
}

# =============================================================================
# 4th_group_4th_branch: Generate compose file
# =============================================================================
compose_generator_4th_4th_generate_file() {
    cat << EOF > "${BUILD_SCRIPT_DIR}/docker-compose.yaml"
services:
  dev-env:
    image: ${FINAL_IMAGE_NAME}
    container_name: ${CONTAINER_NAME}
    hostname: ${CONTAINER_NAME}
    user: "${DEV_USERNAME}"
    restart: ${CONTAINER_RESTART_POLICY}
    privileged: ${CONTAINER_PRIVILEGED}
    tty: true
    stdin_open: true

${COMPOSE_DEVICES_SETTING}

    volumes:
      - /dev/bus/usb:/dev/bus/usb
      - "${VOLUMES_DIR}:${VOLUMES_ROOT}"

    ports:
      - "${CLIENT_SSH_PORT}:22"
      - "${GDB_PORT}:2345"

    environment:
      - TIMEZONE=${TIMEZONE}
      - DISPLAY=${DISPLAY}
      - WORKSPACE_ENABLE_REMOTE_DEBUG=${WORKSPACE_ENABLE_REMOTE_DEBUG}
      - WORKSPACE_LOG_LEVEL=${WORKSPACE_LOG_LEVEL}
      - NVIDIA_VISIBLE_DEVICES=${NVIDIA_VISIBLE_DEVICES}
      - NVIDIA_DRIVER_CAPABILITIES=${NVIDIA_DRIVER_CAPABILITIES}

${COMPOSE_GPU_SETTING}
    working_dir: ${WORKSPACE_ROOT}

    networks:
      - dev-net

networks:
  dev-net:
    driver: bridge

volumes:
  samba_public:
    driver: local
    driver_opts:
      type: cifs
      device: "//${SAMBA_SERVER_IP}/public"
      o: "username=${SAMBA_PUBLIC_ACCOUNT_NAME},password=${SAMBA_PUBLIC_ACCOUNT_PASSWORD},uid=${DEV_UID},gid=${DEV_GID},file_mode=${SAMBA_FILE_MODE},dir_mode=${SAMBA_DIR_MODE}"
EOF
    utils_print_success "Generated docker-compose.yaml"
}

# =============================================================================
# 4th_group: Master function - generate compose configuration
# =============================================================================
compose_generator_4th_generate() {
    compose_generator_4th_1st_ensure_volumes_dir || return 1
    compose_generator_4th_2nd_build_gpu_section
    compose_generator_4th_3rd_build_device_section
    compose_generator_4th_4th_generate_file
}
