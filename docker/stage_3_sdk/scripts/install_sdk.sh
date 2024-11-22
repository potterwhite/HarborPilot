################################################################################
# File: docker/stage_3_sdk/scripts/install_sdk.sh
#
# Description: SDK installation script
#              Handles SDK extraction, installation and configuration
#
# Author: [Your Name]
# Created: 2024-11-21
# Last Modified: 2024-11-21
#
# Copyright (c) 2024 [Your Company/Name]
# License: MIT
################################################################################

#!/bin/bash
set -e

# Source SDK configuration
source /tmp/sdk_config.conf

# Create SDK directories
mkdir -p ${SDK_INSTALL_PATH}/{bin,lib,include,tools}

# Install SDK dependencies
apt-get update && apt-get install -y \
    ${SDK_DEPENDENCIES} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Extract and install SDK
if [ -f "/tmp/offline_packages/${SDK_PACKAGE}" ]; then
    echo "Installing SDK from offline package..."
    tar axf "/tmp/offline_packages/${SDK_PACKAGE}" -C "${SDK_INSTALL_PATH}" --strip-components=1
else
    echo "Error: SDK package not found in offline packages directory"
    exit 1
fi

# Set correct ownership for SDK directories
# Note: DEV_USERNAME and DEV_GROUP should be defined in sdk_config.conf
echo "Setting correct ownership for SDK directories..."
chown -R ${DEV_USERNAME}:${DEV_GROUP} ${SDK_INSTALL_PATH}

# Set up SDK environment
echo "export SDK_ROOT=${SDK_INSTALL_PATH}" >> /etc/profile.d/sdk_env.sh
echo "export PATH=\${SDK_ROOT}/bin:\$PATH" >> /etc/profile.d/sdk_env.sh
echo "export LD_LIBRARY_PATH=\${SDK_ROOT}/lib:\$LD_LIBRARY_PATH" >> /etc/profile.d/sdk_env.sh

# Configure SDK components
# if [ -f "${SDK_INSTALL_PATH}/setup.sh" ]; then
#     chmod +x "${SDK_INSTALL_PATH}/setup.sh"
#     "${SDK_INSTALL_PATH}/setup.sh"
# fi

# Verify installation
echo -e "\nls -lha ${SDK_INSTALL_PATH}/"
ls -ha ${SDK_INSTALL_PATH}/

echo -e "\nrm -rf /tmp/*"
rm -rf /tmp/*
# if [ ! -f "${SDK_INSTALL_PATH}/bin/gcc" ]; then
#     echo "Error: SDK installation verification failed"
#     exit 1
# fi

echo "SDK installation completed successfully"