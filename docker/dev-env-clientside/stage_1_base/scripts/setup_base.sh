#!/bin/bash

################################################################################
# File: docker/stage_1_base/scripts/setup_base.sh
#
# Description: Base system setup script for the development environment
#              Installs essential packages and configures basic system settings
#
# Author: PotterWhite
# Created: 2024-11-21
# Last Modified: 2025-07-14
#
# Copyright (c) 2024 [Your Company/Name]
# License: MIT
################################################################################

set -e

###############################################################################
# Function: func_replace_apt_source
# Description: Replaces apt sources with China mainland mirrors
#              Supports Ubuntu (legacy sources.list and new DEB822 format)
#              and Debian
# Arguments: None
# Returns: None
# Notes:
#   - Ubuntu >= 24.04 uses DEB822 format: /etc/apt/sources.list.d/ubuntu.sources
#   - Ubuntu <= 22.04 uses legacy format: /etc/apt/sources.list
#   - Debian uses legacy format: /etc/apt/sources.list
#   - Mirror used: mirrors.aliyun.com (fallback: mirrors.ustc.edu.cn)
###############################################################################
func_replace_apt_source() {
    echo "Detecting OS distribution and version..."

    local distro=""
    local version_id=""
    local version_codename=""

    # Read /etc/os-release to get distro info
    if [ -f /etc/os-release ]; then
        distro=$(. /etc/os-release && echo "${ID}")
        version_id=$(. /etc/os-release && echo "${VERSION_ID}")
        version_codename=$(. /etc/os-release && echo "${VERSION_CODENAME}")
    else
        echo "WARNING: /etc/os-release not found, skipping apt source replacement"
        return 0
    fi

    echo "Detected: distro=${distro}, version_id=${version_id}, codename=${version_codename}"

    case "${distro}" in
        ubuntu)
            # Ubuntu 24.04+ uses DEB822 format (.sources file)
            # Ubuntu 22.04 and earlier uses legacy sources.list
            local major_version
            major_version=$(echo "${version_id}" | cut -d'.' -f1)

            if [ "${major_version}" -ge 24 ]; then
                echo "Ubuntu >= 24.04 detected, using DEB822 format replacement..."
                local sources_file="/etc/apt/sources.list.d/ubuntu.sources"
                if [ -f "${sources_file}" ]; then
                    cp "${sources_file}" "${sources_file}.bak"
                    sed -i 's|http://archive.ubuntu.com/ubuntu|http://mirrors.aliyun.com/ubuntu|g' "${sources_file}"
                    sed -i 's|http://security.ubuntu.com/ubuntu|http://mirrors.aliyun.com/ubuntu|g' "${sources_file}"
                    echo "Replaced DEB822 apt source -> mirrors.aliyun.com"
                else
                    echo "WARNING: ${sources_file} not found, skipping DEB822 replacement"
                fi
            else
                echo "Ubuntu < 24.04 detected, using legacy sources.list replacement..."
                local sources_file="/etc/apt/sources.list"
                if [ -f "${sources_file}" ]; then
                    cp "${sources_file}" "${sources_file}.bak"
                    sed -i 's|http://archive.ubuntu.com/ubuntu|http://mirrors.aliyun.com/ubuntu|g' "${sources_file}"
                    sed -i 's|http://security.ubuntu.com/ubuntu|http://mirrors.aliyun.com/ubuntu|g' "${sources_file}"
                    echo "Replaced legacy apt source -> mirrors.aliyun.com"
                else
                    echo "WARNING: ${sources_file} not found, skipping legacy replacement"
                fi
            fi
            ;;

        debian)
            echo "Debian detected, replacing sources.list..."
            local sources_file="/etc/apt/sources.list"
            if [ -f "${sources_file}" ]; then
                cp "${sources_file}" "${sources_file}.bak"
                sed -i 's|http://deb.debian.org/debian|http://mirrors.aliyun.com/debian|g' "${sources_file}"
                sed -i 's|http://security.debian.org/debian-security|http://mirrors.aliyun.com/debian-security|g' "${sources_file}"
                echo "Replaced Debian apt source -> mirrors.aliyun.com"
            else
                echo "WARNING: ${sources_file} not found, skipping Debian replacement"
            fi
            ;;

        *)
            echo "WARNING: Unknown distribution '${distro}', skipping apt source replacement"
            ;;
    esac
}

func_install_universe_repo() {
    echo "Enabling universe repository"
    apt-get update
    apt-get install -y software-properties-common
    add-apt-repository universe
}

###############################################################################
# Function: func_install_system_core
# Description: Installs core system management packages
# Arguments: None
# Returns: None
# Notes: Basic system utilities required for operation
###############################################################################
func_install_system_core() {
    echo "Installing core system packages..."
    apt-get install -y \
        sudo \
        apt-utils \
        apt-transport-https \
        ca-certificates \
        software-properties-common \
        libncursesw6
}

###############################################################################
# Function: func_install_network_tools
# Description: Installs networking related packages
# Arguments: None
# Returns: None
# Notes: Tools for network connectivity and SSH
###############################################################################
func_install_network_tools() {
    echo "Installing network tools..."
    apt-get install -y \
        net-tools \
        openssh-server \
        curl \
        wget

    # Create SSH directory
    mkdir -p /var/run/sshd
}

###############################################################################
# Function: func_install_system_utils
# Description: Installs general system utilities
# Arguments: None
# Returns: None
# Notes: Common tools used in system operations
###############################################################################
func_install_system_utils() {
    echo "Installing system utilities..."
    apt-get install -y \
        vim \
        pigz \
        locate \
        whiptail \
        bc \
        time \
        cpio \
        unzip \
        rsync \
        gettext-base

    echo "OS_VERSION = ${OS_VERSION}"
    if [ "${OS_VERSION}" != "20.04" ]; then
        apt-get install -y \
            bsdextrautils

        echo "install bsdextrautils"
    fi
}

###############################################################################
# Function: func_install_security_tools
# Description: Installs security related packages
# Arguments: None
# Returns: None
# Notes: Tools for system security and encryption
###############################################################################
func_install_security_tools() {
    echo "Installing security tools..."
    apt-get install -y \
        gnupg \
        gnupg2
}

###############################################################################
# Function: func_install_essential_packages
# Description: Orchestrates the installation of all package groups
# Arguments: None
# Returns: None
# Notes: This is the first step in system setup
###############################################################################
func_install_essential_packages() {
    echo "Installing essential system packages..."

    # Update package lists and upgrade existing packages
    apt-get update && apt-get upgrade -y

    # Install locales first to avoid locale-gen command not found
    apt-get install -y locales tzdata

    # Install package groups
    func_install_system_core
    func_install_network_tools
    func_install_system_utils
    func_install_security_tools
}

###############################################################################
# Function: func_setup_locale
# Description: Configures system locale settings
# Arguments: None
# Returns: None
# Notes: Sets up UTF-8 locale for better international character support
###############################################################################
func_setup_locale() {
    echo "Configuring system locale..."

    # Generate and set default locale
    locale-gen en_US.UTF-8
    update-locale LANG=en_US.UTF-8
}

###############################################################################
# Function: func_create_user
# Description: Creates non-root user with sudo privileges
# Arguments: None
# Returns: None
# Notes: Uses environment variables for user details
###############################################################################
func_create_user() {
    echo "Creating non-root user..."

    # Create user group
    groupadd --gid $DEV_GID $DEV_USERNAME

    # Create user with home directory
    useradd --uid $DEV_UID --gid $DEV_GID -m $DEV_USERNAME

    # Set passwords for user and root
    echo "$DEV_USERNAME:$DEV_USER_PASSWORD" | chpasswd
    echo "root:$DEV_USER_ROOT_PASSWORD" | chpasswd

    # Configure sudo access
    echo $DEV_USERNAME ALL=\(root\) NOPASSWD:ALL >/etc/sudoers.d/$DEV_USERNAME
    chmod 0440 /etc/sudoers.d/$DEV_USERNAME
}

###############################################################################
# Function: func_setup_timezone
# Description: Sets system timezone
# Arguments: None
# Returns: None
# Notes: Uses TIMEZONE environment variable
###############################################################################
func_setup_timezone() {
    echo "Setting up system timezone..."

    ln -fs /usr/share/zoneinfo/$TIMEZONE /etc/localtime
    dpkg-reconfigure -f noninteractive tzdata
}

###############################################################################
# Function: func_restore_system_docs
# Description: Restores full system documentation and man pages
# Arguments: None
# Returns: None
# Notes: This will increase image size but provide better development experience
###############################################################################
func_restore_system_docs() {
    echo "Restoring system documentation..."

    # Restore full system documentation
    yes | unminimize

    # Install man system
    apt-get install -y man-db

    echo "System documentation restored successfully"
}

###############################################################################
# Function: func_cleanup
# Description: Cleans up package manager cache
# Arguments: None
# Returns: None
# Notes: Reduces image size by removing unnecessary cache files
###############################################################################
func_cleanup() {
    echo "Cleaning up..."

    apt-get clean && rm -rf /var/lib/apt/lists/*
}

###############################################################################
# Main function
# Description: Orchestrates the execution of all setup functions
# Arguments: $@ - All script arguments
# Returns: 0 on success, non-zero on failure
###############################################################################
main() {
    local args="$@"
    echo "Starting system setup with arguments: ${args}"

    func_replace_apt_source
    func_install_universe_repo
    func_install_essential_packages
    func_setup_locale
    func_create_user
    func_setup_timezone
    func_restore_system_docs
    func_cleanup

    echo "System setup completed successfully"
    return 0
}

# Execute main function with all script arguments
main "$@"
