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
# File: 03_volumes_init.sh
# Description: Volumes directory symlink auto-initialization
#              Creates/repairs volumes symlink automatically when missing or broken
################################################################################

# =============================================================================
# 3rd_group_1st_branch: Check if volumes symlink is valid
# =============================================================================
volumes_init_3rd_1st_check_symlink() {
    # Use BUILD_SCRIPT_DIR from env_loader if available
    local volumes_link="${BUILD_SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/volumes"
    
    if [ -L "${volumes_link}" ] && [ -e "${volumes_link}" ]; then
        export VOLUMES_DIR="$(realpath "${volumes_link}")"
        return 0
    fi
    return 1
}

# =============================================================================
# 3rd_group_2nd_branch: Create volumes symlink with auto-detection
# =============================================================================
volumes_init_3rd_2nd_create_symlink() {
    local volumes_link="${BUILD_SCRIPT_DIR}/volumes"
    local volumes_target="${HOST_VOLUME_DIR}"
    
    if [ -z "${volumes_target}" ]; then
        utils_print_error "HOST_VOLUME_DIR is not set. Cannot create volumes symlink."
        return 1
    fi
    
    if [ -L "${volumes_link}" ]; then
        rm -f "${volumes_link}"
    fi
    
    if [ ! -d "${volumes_target}" ]; then
        utils_print_warning "Volumes directory does not exist: ${volumes_target}"
        if utils_prompt_yes_no "Create it automatically?"; then
            if mkdir -p "${volumes_target}"; then
                utils_print_success "Created volumes directory: ${volumes_target}"
            else
                utils_print_error "Failed to create volumes directory: ${volumes_target}"
                return 1
            fi
        else
            utils_print_error "Cannot proceed without volumes directory"
            return 1
        fi
    fi
    
    if ln -sf "${volumes_target}" "${volumes_link}"; then
        export VOLUMES_DIR="$(realpath "${volumes_link}")"
        utils_print_success "Created volumes symlink: ${volumes_link} -> ${volumes_target}"
        return 0
    else
        utils_print_error "Failed to create volumes symlink"
        return 1
    fi
}

# =============================================================================
# 3rd_group_3rd_branch: Repair broken symlink
# =============================================================================
volumes_init_3rd_3rd_repair_symlink() {
    local volumes_link="${BUILD_SCRIPT_DIR}/volumes"
    
    utils_print_warning "Volumes symlink is broken: ${volumes_link}"
    
    if utils_prompt_yes_no "Repair symlink using HOST_VOLUME_DIR (${HOST_VOLUME_DIR})?"; then
        rm -f "${volumes_link}"
        if ln -sf "${HOST_VOLUME_DIR}" "${volumes_link}"; then
            export VOLUMES_DIR="$(realpath "${volumes_link}")"
            utils_print_success "Repaired volumes symlink"
            return 0
        else
            utils_print_error "Failed to repair volumes symlink"
            return 1
        fi
    else
        utils_print_error "Cannot proceed with broken symlink"
        return 1
    fi
}

# =============================================================================
# 3rd_group: Master function - initialize volumes if needed
# =============================================================================
volumes_init_3rd_init_if_needed() {
    if volumes_init_3rd_1st_check_symlink; then
        return 0
    fi
    
    if [ -L "${BUILD_SCRIPT_DIR}/volumes" ]; then
        volumes_init_3rd_3rd_repair_symlink
    else
        volumes_init_3rd_2nd_create_symlink
    fi
}
