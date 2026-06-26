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
# Description: Volume directory initialization
#              Default: use local volume/ directly (zero-config).
#              Custom:  create symlink from volume/ to user-specified path.
################################################################################

# =============================================================================
# 3rd_group_1st_branch: Check if volume directory is ready
# =============================================================================
volumes_init_3rd_1st_check() {
    local volume_link="${BUILD_SCRIPT_DIR}/volume"

    # Already a valid symlink or directory
    if [ -e "${volume_link}" ]; then
        export VOLUMES_DIR="$(realpath "${volume_link}")"
        return 0
    fi
    return 1
}

# =============================================================================
# 3rd_group_2nd_branch: Initialize volume directory
# =============================================================================
volumes_init_3rd_2nd_init() {
    local volume_link="${BUILD_SCRIPT_DIR}/volume"
    local target="${HOST_VOLUME_DIR}"

    if [ -z "${target}" ]; then
        utils_print_error "HOST_VOLUME_DIR is not set."
        return 1
    fi

    # Resolve target to absolute path for comparison
    local abs_target
    abs_target="$(cd -P "${BUILD_SCRIPT_DIR}/.." 2>/dev/null && pwd)/volume"
    local target_resolved
    target_resolved="$(cd -P "${target}" 2>/dev/null && pwd)" || target_resolved="${target}"

    # If target is the local volume/ directory — just create it, no symlink
    if [ "${target_resolved}" = "${abs_target}" ]; then
        if [ ! -d "${volume_link}" ]; then
            mkdir -p "${volume_link}"
            utils_print_success "Created volume directory: ${volume_link}"
        fi
        export VOLUMES_DIR="${volume_link}"
        return 0
    fi

    # Custom path — create symlink
    if [ ! -d "${target}" ]; then
        utils_print_warning "Volume directory does not exist: ${target}"
        if utils_prompt_yes_no "Create it automatically?"; then
            mkdir -p "${target}" || { utils_print_error "Failed to create: ${target}"; return 1; }
            utils_print_success "Created: ${target}"
        else
            utils_print_error "Cannot proceed without volume directory"
            return 1
        fi
    fi

    # Remove existing file/symlink at volume_link
    rm -f "${volume_link}"

    if ln -sf "${target}" "${volume_link}"; then
        export VOLUMES_DIR="$(realpath "${volume_link}")"
        utils_print_success "Linked: ${volume_link} -> ${target}"
        return 0
    else
        utils_print_error "Failed to create symlink"
        return 1
    fi
}

# =============================================================================
# 3rd_group: Master function - initialize volume if needed
# =============================================================================
volumes_init_3rd_init_if_needed() {
    if volumes_init_3rd_1st_check; then
        return 0
    fi
    volumes_init_3rd_2nd_init
}
