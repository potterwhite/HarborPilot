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
# Module: container.sh
# Description: Container lifecycle operations (start/stop/restart/recreate/remove)
################################################################################

# =============================================================================
# 5th_group_1st_branch: Helper - check container state
# =============================================================================
_container_is_running() {
    docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"
}

_container_exists() {
    docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"
}

_container_image_exists() {
    docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^${FINAL_IMAGE_NAME}$"
}

# =============================================================================
# 5th_group_2nd_branch: Pull latest image
# =============================================================================
_container_pull_image() {
    if _container_image_exists; then
        if ! prompt_simple "Local image already exists. Pull latest anyway?" "" "" "n"; then
            return 0
        fi
    fi
    
    if [ "${HAVE_HARBOR_SERVER}" == "FALSE" ]; then
        _error "No registry server configured. Cannot pull image."
        return 1
    fi
    
    _log "INFO" "Pulling latest image from ${REGISTRY_URL}..."
    if docker pull "${FINAL_IMAGE_NAME}"; then
        _log "SUCCESS" "Image pulled successfully"
        return 0
    else
        _error "Failed to pull image"
        return 1
    fi
}

# =============================================================================
# 5th_group_3rd_branch: Container operations
# =============================================================================
_container_stop() {
    if _container_is_running; then
        _log "INFO" "Stopping container..."
        docker stop ${CONTAINER_NAME}
    else
        _log "WARN" "Container is not running"
    fi
}

_container_start() {
    if _container_exists; then
        _log "INFO" "Starting existing container..."
        docker start ${CONTAINER_NAME}
    else
        _log "INFO" "Creating new container..."
        compose_generate
        (cd "${BUILD_SCRIPT_DIR}" && docker compose -p ${CONTAINER_NAME} up -d)
    fi
    
    if [ $? -eq 0 ]; then
        _log "SUCCESS" "Container is ready!"
    else
        _error "Failed to start container"
        return 1
    fi
}

_container_remove_container() {
    if _container_exists; then
        _log "INFO" "Removing container..."
        if ! docker rm "${CONTAINER_NAME}" -f; then
            _error "Failed to remove container"
            return 1
        fi
    fi
}

_container_remove_image() {
    if _container_image_exists; then
        _log "INFO" "Removing image..."
        if ! docker rmi "${FINAL_IMAGE_NAME}" -f; then
            _error "Failed to remove image"
            return 1
        fi
    fi
}

# =============================================================================
# 5th_group_4th_branch: Interactive flow - start with options
# =============================================================================
container_start_interactive() {
    if _container_is_running; then
        while true; do
            _log "INFO" "Container is already running!"
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
                    _container_stop
                    _container_start
                    prompt_simple "Enter container?" "" "" "y" && docker exec -it -u ${DEV_USERNAME} ${CONTAINER_NAME} bash
                    return 0
                    ;;
                3)
                    _container_remove_container
                    _container_remove_image
                    _container_pull_image
                    _container_start
                    prompt_simple "Enter container?" "" "" "y" && docker exec -it -u ${DEV_USERNAME} ${CONTAINER_NAME} bash
                    return 0
                    ;;
                *)
                    _error "Invalid choice"
                    ;;
            esac
        done
    fi
    
    if [ "${HAVE_HARBOR_SERVER}" == "FALSE" ] && ! _container_image_exists; then
        _error "Local image not found and no registry configured"
        return 1
    fi
    
    _container_start
    prompt_simple "Enter container?" "" "" "y" && docker exec -it -u ${DEV_USERNAME} ${CONTAINER_NAME} bash
}

# =============================================================================
# 5th_group: Stop wrapper
# =============================================================================
container_stop() {
    _container_stop
}

# =============================================================================
# 5th_group: Restart wrapper
# =============================================================================
container_restart() {
    _container_stop
    _container_start
}

# =============================================================================
# 5th_group: Recreate wrapper
# =============================================================================
container_recreate() {
    _container_remove_container
    _container_remove_image
    _container_pull_image
    _container_start
}

# =============================================================================
# 5th_group: Remove container only
# =============================================================================
container_remove() {
    _container_remove_container
}
