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
# Module: utils.sh
# Description: Utility functions for HarborPilot
# Functions: 0_check_registry_login, _log, _error, _check_dependencies
################################################################################

################################################################################
# 0. Pre-flight: verify docker registry login
# If HAVE_HARBOR_SERVER is TRUE, ensure the user is authenticated to the
# registry before we waste time building an image we cannot push.
# Returns:
#   0 if login is not required, or login is already valid
#   1 if user failed / declined to login
################################################################################
0_check_registry_login() {
    if [ "${HAVE_HARBOR_SERVER}" != "TRUE" ]; then
        echo "[Registry] HAVE_HARBOR_SERVER is not TRUE — skipping login check."
        return 0
    fi

    echo -e "\n[Registry] Checking Docker login status for ${REGISTRY_URL%%/*} ..."

    local registry_host="${HARBOR_SERVER_IP}:${HARBOR_SERVER_PORT}"

    # ------------------------------------------------------------------
    # Passive credential check — reads config.json only, no network call.
    # docker login writes an entry under .auths (plain creds) or registers
    # the host under .credHelpers (credential-helper mode); docker logout
    # removes it.  Either key present means the user has logged in.
    # ------------------------------------------------------------------
    local docker_config="${DOCKER_CONFIG:-${HOME}/.docker}/config.json"

    if [ -f "${docker_config}" ] && \
       grep -qF "\"${registry_host}\"" "${docker_config}" 2>/dev/null; then
        echo "[Registry] Already logged in to ${registry_host}."
        return 0
    fi

    # Credentials either missing or invalid — ask user to login now
    echo ""
    echo "  ╔══════════════════════════════════════════════════════════════════╗"
    echo "  ║  ACTION REQUIRED: Docker registry login                         ║"
    echo "  ║                                                                  ║"
    echo "  ║  You must log in to the Harbor registry before building,         ║"
    echo "  ║  otherwise the push step will fail.                              ║"
    echo "  ║                                                                  ║"
    echo "  ║  Registry: ${registry_host}"
    echo "  ║                                                                  ║"
    echo "  ║  Run:  docker login ${registry_host}                             ║"
    echo "  ╚══════════════════════════════════════════════════════════════════╝"
    echo ""
    read -p "  Press ENTER to run 'docker login ${registry_host}' now, or Ctrl+C to abort: "

    if docker login "${registry_host}"; then
        echo "[Registry] Login successful."
        return 0
    else
        echo "[Registry] Login failed. Aborting build."
        return 1
    fi
}

################################################################################
# Log function with timestamp
# Arguments:
#   $1 - Log level (INFO, WARN, ERROR, DEBUG)
#   $2 - Log message
################################################################################
_log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    echo "[${timestamp}] [${level}] ${message}"
}

################################################################################
# Error function with exit
# Arguments:
#   $1 - Error message
#   $2 - Exit code (optional, default: 1)
################################################################################
_error() {
    local message="$1"
    local exit_code="${2:-1}"

    _log "ERROR" "${message}"
    exit "${exit_code}"
}

################################################################################
# Check if required dependencies are installed
# Returns:
#   0 if all dependencies are available
#   1 if any dependency is missing
################################################################################
_check_dependencies() {
    local errors=0

    # Check for Docker
    if ! command -v docker &> /dev/null; then
        echo "Error: docker is not installed or not in PATH"
        ((errors++))
    fi

    # Check for jq (used in manifest inspection)
    if ! command -v jq &> /dev/null; then
        echo "Error: jq is not installed or not in PATH"
        ((errors++))
    fi

    # Check for tar (used in packaging)
    if ! command -v tar &> /dev/null; then
        echo "Error: tar is not installed or not in PATH"
        ((errors++))
    fi

    # Check for gzip (used in packaging)
    if ! command -v gzip &> /dev/null; then
        echo "Error: gzip is not installed or not in PATH"
        ((errors++))
    fi

    # Check for hostname (used for host config detection)
    if ! command -v hostname &> /dev/null; then
        echo "Error: hostname is not installed or not in PATH"
        ((errors++))
    fi

    # Check for readlink (used for path resolution)
    if ! command -v readlink &> /dev/null; then
        echo "Error: readlink is not installed or not in PATH"
        ((errors++))
    fi

    # Check for dirname (used for path resolution)
    if ! command -v dirname &> /dev/null; then
        echo "Error: dirname is not installed or not in PATH"
        ((errors++))
    fi

    # Check for basename (used for path resolution)
    if ! command -v basename &> /dev/null; then
        echo "Error: basename is not installed or not in PATH"
        ((errors++))
    fi

    # Check for grep (used for parsing)
    if ! command -v grep &> /dev/null; then
        echo "Error: grep is not installed or not in PATH"
        ((errors++))
    fi

    # Check for awk (used for parsing)
    if ! command -v awk &> /dev/null; then
        echo "Error: awk is not installed or not in PATH"
        ((errors++))
    fi

    # Check for sort (used for sorting)
    if ! command -v sort &> /dev/null; then
        echo "Error: sort is not installed or not in PATH"
        ((errors++))
    fi

    # Check for mktemp (used for temp directories)
    if ! command -v mktemp &> /dev/null; then
        echo "Error: mktemp is not installed or not in PATH"
        ((errors++))
    fi

    # Check for du (used for file size)
    if ! command -v du &> /dev/null; then
        echo "Error: du is not installed or not in PATH"
        ((errors++))
    fi

    # Check for cut (used for parsing)
    if ! command -v cut &> /dev/null; then
        echo "Error: cut is not installed or not in PATH"
        ((errors++))
    fi

    return ${errors}
}

################################################################################
# Check if Docker daemon is running
# Returns:
#   0 if Docker daemon is running
#   1 if Docker daemon is not running
################################################################################
_check_docker_daemon() {
    if ! docker info &> /dev/null; then
        echo "Error: Docker daemon is not running"
        return 1
    fi
    return 0
}

################################################################################
# Check if we have enough disk space
# Arguments:
#   $1 - Required space in GB (optional, default: 10)
# Returns:
#   0 if enough space is available
#   1 if not enough space
################################################################################
_check_disk_space() {
    local required_gb="${1:-10}"
    local available_gb

    # Get available space in GB
    available_gb=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')

    if [ "${available_gb}" -lt "${required_gb}" ]; then
        echo "Warning: Low disk space. Available: ${available_gb}GB, Recommended: ${required_gb}GB"
        return 1
    fi

    return 0
}

################################################################################
# Check if a port is available
# Arguments:
#   $1 - Port number
# Returns:
#   0 if port is available
#   1 if port is in use
################################################################################
_check_port_available() {
    local port="$1"

    if netstat -tuln 2>/dev/null | grep -q ":${port} "; then
        echo "Warning: Port ${port} is already in use"
        return 1
    fi

    return 0
}

################################################################################
# Generate a random string
# Arguments:
#   $1 - Length (optional, default: 16)
# Returns:
#   Random string
################################################################################
_generate_random_string() {
    local length="${1:-16}"

    tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c "${length}"
}

################################################################################
# Format file size
# Arguments:
#   $1 - Size in bytes
# Returns:
#   Formatted size (e.g., "1.5GB", "500MB")
################################################################################
_format_file_size() {
    local size_bytes="$1"

    if [ "${size_bytes}" -ge 1073741824 ]; then
        echo "$(echo "scale=1; ${size_bytes}/1073741824" | bc)GB"
    elif [ "${size_bytes}" -ge 1048576 ]; then
        echo "$(echo "scale=1; ${size_bytes}/1048576" | bc)MB"
    elif [ "${size_bytes}" -ge 1024 ]; then
        echo "$(echo "scale=1; ${size_bytes}/1024" | bc)KB"
    else
        echo "${size_bytes}B"
    fi
}

################################################################################
# Check if a file exists and is readable
# Arguments:
#   $1 - File path
# Returns:
#   0 if file exists and is readable
#   1 if file does not exist or is not readable
################################################################################
_check_file_readable() {
    local file_path="$1"

    if [ ! -f "${file_path}" ]; then
        echo "Error: File not found: ${file_path}"
        return 1
    fi

    if [ ! -r "${file_path}" ]; then
        echo "Error: File not readable: ${file_path}"
        return 1
    fi

    return 0
}

################################################################################
# Check if a directory exists and is writable
# Arguments:
#   $1 - Directory path
# Returns:
#   0 if directory exists and is writable
#   1 if directory does not exist or is not writable
################################################################################
_check_directory_writable() {
    local dir_path="$1"

    if [ ! -d "${dir_path}" ]; then
        echo "Error: Directory not found: ${dir_path}"
        return 1
    fi

    if [ ! -w "${dir_path}" ]; then
        echo "Error: Directory not writable: ${dir_path}"
        return 1
    fi

    return 0
}

################################################################################
# Create a backup of a file
# Arguments:
#   $1 - File path
#   $2 - Backup suffix (optional, default: ".bak")
# Returns:
#   0 if backup was created successfully
#   1 if backup failed
################################################################################
_create_backup() {
    local file_path="$1"
    local backup_suffix="${2:-.bak}"
    local backup_path="${file_path}${backup_suffix}"

    if [ ! -f "${file_path}" ]; then
        echo "Error: File not found: ${file_path}"
        return 1
    fi

    if cp "${file_path}" "${backup_path}"; then
        echo "Backup created: ${backup_path}"
        return 0
    else
        echo "Error: Failed to create backup of ${file_path}"
        return 1
    fi
}

################################################################################
# Restore a file from backup
# Arguments:
#   $1 - Backup file path
#   $2 - Original file path (optional, derived from backup path)
# Returns:
#   0 if restore was successful
#   1 if restore failed
################################################################################
_restore_from_backup() {
    local backup_path="$1"
    local original_path="${2:-${backup_path%.bak}}"

    if [ ! -f "${backup_path}" ]; then
        echo "Error: Backup file not found: ${backup_path}"
        return 1
    fi

    if cp "${backup_path}" "${original_path}"; then
        echo "File restored from backup: ${original_path}"
        return 0
    else
        echo "Error: Failed to restore from backup: ${backup_path}"
        return 1
    fi
}
