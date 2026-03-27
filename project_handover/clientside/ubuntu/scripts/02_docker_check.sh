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
# File: 02_docker_check.sh
# Description: Docker group and login checks
################################################################################

# =============================================================================
# 2nd_group_1st_branch: Check Docker group membership
# =============================================================================
docker_check_2nd_1st_check_group() {
    if ! groups "$USER" | grep -q "docker"; then
        utils_print_warning "Current user is not in the docker group"
        utils_prompt_yes_no "Do you want to add current user to docker group?" || return 0
        
        if sudo usermod -aG docker "$USER"; then
            utils_print_success "Successfully added user to docker group"
            utils_prompt_yes_no "Do you want to apply changes now?" && exec newgrp docker
            utils_print_info "Please log out and log back in for changes to take effect"
        fi
    fi
}

# =============================================================================
# 2nd_group_2nd_branch: Check Docker registry login
# =============================================================================
docker_check_2nd_2nd_check_login() {
    if [ "${HAVE_HARBOR_SERVER}" == "FALSE" ]; then
        return 0
    fi
    
    local registry="${REGISTRY_URL}"
    local max_attempts=3
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        attempt=$((attempt + 1))
        
        login_output=$(docker login "${registry}" 2>&1)
        login_status=$?
        
        if [ $login_status -eq 0 ] && echo "$login_output" | grep -q "Authenticating with existing credentials"; then
            utils_print_success "Already logged in to registry ${registry}"
            return 0
        fi
        
        if [ $login_status -eq 0 ]; then
            utils_print_success "Successfully logged in to registry ${registry}"
            return 0
        fi
        
        if [ $attempt -lt $max_attempts ]; then
            if echo "$login_output" | grep -q "unauthorized"; then
                utils_print_error "Authentication failed"
            elif echo "$login_output" | grep -q "no such host"; then
                utils_print_error "Registry host not found"
            elif echo "$login_output" | grep -q "connection refused"; then
                utils_print_error "Registry not available"
            else
                utils_print_error "Login failed: ${login_output}"
            fi
            utils_print_warning "Attempt ${attempt}/${max_attempts} failed. Please try again."
        fi
    done
    
    utils_print_error "Failed to login after ${max_attempts} attempts"
    return 1
}

# =============================================================================
# 2nd_group: Master function - perform all Docker checks
# =============================================================================
docker_check_2nd_do_checks() {
    docker_check_2nd_1st_check_group || return 1
    docker_check_2nd_2nd_check_login || return 1
    return 0
}
