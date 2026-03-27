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
# File: 05_container_lifecycle.sh
# Description: Container lifecycle operations (start/stop/restart/recreate/remove)
################################################################################

# =============================================================================
# 5th_group_1st_branch: Helper - check container state
# =============================================================================
container_lifecycle_5th_1st_is_running() {
    docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"
}

container_lifecycle_5th_2nd_exists() {
    docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"
}

container_lifecycle_5th_3rd_image_exists() {
    docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^${FINAL_IMAGE_NAME}$"
}

# =============================================================================
# 5th_group_2nd_branch: Pull latest image
# =============================================================================
container_lifecycle_5th_4th_pull_image() {
    if container_lifecycle_5th_3rd_image_exists; then
        if ! utils_prompt_yes_no "Local image already exists. Pull latest anyway?" "N"; then
            return 0
        fi
    fi
    
    if [ "${HAVE_HARBOR_SERVER}" == "FALSE" ]; then
        utils_print_error "No registry server configured. Cannot pull image."
        return 1
    fi
    
    utils_print_info "Pulling latest image from ${REGISTRY_URL}..."
    if docker pull "${FINAL_IMAGE_NAME}"; then
        utils_print_success "Image pulled successfully"
        return 0
    else
        utils_print_error "Failed to pull image"
        return 1
    fi
}

# =============================================================================
# 5th_group_3rd_branch: Container operations
# =============================================================================
container_lifecycle_5th_5th_stop() {
    if container_lifecycle_5th_1st_is_running; then
        utils_print_info "Stopping container..."
        docker stop ${CONTAINER_NAME}
    else
        utils_print_warning "Container is not running"
    fi
}

container_lifecycle_5th_6th_start() {
    if container_lifecycle_5th_2nd_exists; then
        utils_print_info "Starting existing container..."
        docker start ${CONTAINER_NAME}
    else
        utils_print_info "Creating new container..."
        compose_generator_4th_generate
        (cd "${BUILD_SCRIPT_DIR}" && docker compose -p ${CONTAINER_NAME} up -d)
    fi
    
    if [ $? -eq 0 ]; then
        utils_print_success "Container is ready!"
    else
        utils_print_error "Failed to start container"
        return 1
    fi
}

container_lifecycle_5th_7th_remove_container() {
    if container_lifecycle_5th_2nd_exists; then
        utils_print_info "Removing container..."
        if ! docker rm "${CONTAINER_NAME}" -f; then
            utils_print_error "Failed to remove container"
            return 1
        fi
    fi
}

container_lifecycle_5th_8th_remove_image() {
    if container_lifecycle_5th_3rd_image_exists; then
        utils_print_info "Removing image..."
        if ! docker rmi "${FINAL_IMAGE_NAME}" -f; then
            utils_print_error "Failed to remove image"
            return 1
        fi
    fi
}

# =============================================================================
# 5th_group_4th_branch: Interactive flow - start with options
# =============================================================================
container_lifecycle_5th_9th_start_interactive() {
    if container_lifecycle_5th_1st_is_running; then
        while true; do
            utils_print_msg "Container is already running!" "${UTILS_COLOR_YELLOW}"
            echo "Please choose an option:"
            echo "  1. Enter the container"
            echo "  2. Restart container"
            echo "  3. Remove and recreate"
            echo ""
            echo "Manual: docker exec -it -u ${DEV_USERNAME} ${CONTAINER_NAME} bash"
            echo ""
            read -p "Enter your choice (1-3): " choice
            
            case $choice in
                1)
                    docker exec -it -u ${DEV_USERNAME} ${CONTAINER_NAME} bash
                    return 0
                    ;;
                2)
                    container_lifecycle_5th_5th_stop
                    container_lifecycle_5th_6th_start
                    utils_prompt_yes_no "Enter container?" && docker exec -it -u ${DEV_USERNAME} ${CONTAINER_NAME} bash
                    return 0
                    ;;
                3)
                    container_lifecycle_5th_7th_remove_container
                    container_lifecycle_5th_8th_remove_image
                    container_lifecycle_5th_4th_pull_image
                    container_lifecycle_5th_6th_start
                    utils_prompt_yes_no "Enter container?" && docker exec -it -u ${DEV_USERNAME} ${CONTAINER_NAME} bash
                    return 0
                    ;;
                *)
                    utils_print_error "Invalid choice"
                    ;;
            esac
        done
    fi
    
    if [ "${HAVE_HARBOR_SERVER}" == "FALSE" ] && ! container_lifecycle_5th_3rd_image_exists; then
        utils_print_error "Local image not found and no registry configured"
        return 1
    fi
    
    container_lifecycle_5th_6th_start
    utils_prompt_yes_no "Enter container?" && docker exec -it -u ${DEV_USERNAME} ${CONTAINER_NAME} bash
}

# =============================================================================
# 5th_group: Stop wrapper
# =============================================================================
container_lifecycle_5th_stop() {
    container_lifecycle_5th_5th_stop
}

# =============================================================================
# 5th_group: Restart wrapper
# =============================================================================
container_lifecycle_5th_restart() {
    container_lifecycle_5th_5th_stop
    container_lifecycle_5th_6th_start
}

# =============================================================================
# 5th_group: Recreate wrapper
# =============================================================================
container_lifecycle_5th_recreate() {
    container_lifecycle_5th_7th_remove_container
    container_lifecycle_5th_8th_remove_image
    container_lifecycle_5th_4th_pull_image
    container_lifecycle_5th_6th_start
}

# =============================================================================
# 5th_group: Remove container only
# =============================================================================
container_lifecycle_5th_remove() {
    container_lifecycle_5th_7th_remove_container
}
