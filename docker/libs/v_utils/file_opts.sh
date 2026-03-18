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

#! /bin/bash

# Function: Create directory with proper permissions
lib_fileopts_create_directory() {
    local dir_path="$1"
    local dir_owner="$2"
    local dir_perms="$3"

    echo "Creating directory: ${dir_path}"
    if [ -z "${dir_path}" ]; then
        echo "ERROR: Directory path is empty"
        exit 1
    fi

    echo "Parameters:"
    echo "  Path: ${dir_path}"
    echo "  Owner: ${dir_owner}"
    echo "  Permissions: ${dir_perms}"

    mkdir -p "${dir_path}"
    chown "${dir_owner}:${dir_owner}" "${dir_path}"
    chmod "${dir_perms}" "${dir_path}"
}
