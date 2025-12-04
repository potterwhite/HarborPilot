#!/bin/bash
################################################################################
# File: docker/stage_2_tools/offline_packages/gcc/install_gcc.sh
#
# Description: Installation script for GCC offline package
#              Handles extraction, installation and PATH configuration
#              Supports conditional installation based on configuration
#
# Dependencies:
#   - tool_versions.conf for package configuration
#   - GCC offline package in specified location
#   - build-essential package
#
# Environment Variables (from tool_versions.conf):
#   - GCC_OFFLINE_PACKAGE: Filename of the GCC package
#   - GCC_INSTALL_PATH: Installation directory path
#
# Usage:
#   This script is intended to be run during Docker image build process
#   Requires root privileges for installation
#
# Author: PotterWhite
# Created: 2024-11-21
# Last Modified: 2024-11-21
#
# Copyright (c) 2024 [Your Company/Name]
# License: MIT
################################################################################

set -e

# Source configurations
source /tmp/tool_versions.conf

# Check if GCC installation is enabled
if [ -z "${GCC_OFFLINE_PACKAGE}" ]; then
    echo "GCC offline installation is disabled"
    exit 0
fi

# Check if package exists
PACKAGE_PATH="/tmp/offline_packages/gcc/${GCC_OFFLINE_PACKAGE}"
if [ ! -f "${PACKAGE_PATH}" ]; then
    echo "Warning: GCC package not found at ${PACKAGE_PATH}"
    exit 0
fi

# Install dependencies
apt-get update && apt-get install -y \
    build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Extract and install GCC
cd /tmp
tar axvf "${PACKAGE_PATH}"

# Get directory name by removing .tar.* from package name
GCC_DIR=$(echo "${GCC_OFFLINE_PACKAGE}" | sed 's/\.tar\.[^.]*$//')

# Move to install path
mv "/tmp/${GCC_DIR}" "${GCC_INSTALL_PATH}/"

# Add to PATH using /etc/environment (most reliable way)
CURRENT_PATH=$(grep '^PATH=' /etc/environment | cut -d'"' -f2)
# echo "PATH=${GCC_INSTALL_PATH}/${GCC_DIR}/bin:\$PATH" >> /etc/environment
echo "PATH=\"${CURRENT_PATH}:${GCC_INSTALL_PATH}/${GCC_DIR}/bin\"" > /etc/environment

# 立即更新当前会话的PATH
export PATH="${GCC_INSTALL_PATH}/${GCC_DIR}/bin:$PATH"

# Clean up
rm -f "${PACKAGE_PATH}"

# Verify installation
if command -v aarch64-none-linux-gnu-gcc >/dev/null 2>&1; then
    echo "GCC cross compiler successfully installed"
    aarch64-none-linux-gnu-gcc --version
else
    echo "Error: GCC installation failed"
    exit 1
fi

