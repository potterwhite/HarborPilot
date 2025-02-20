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
