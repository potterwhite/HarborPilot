################################################################################
# File: docker/stage_3_sdk/scripts/compile_sdk.sh
#
# Description: SDK compilation script
#              Handles SDK compilation after installation
#
# Author: [Your Name]
# Created: 2024-11-22
# Last Modified: 2024-11-22
#
# Copyright (c) 2024 [Your Company/Name]
# License: MIT
################################################################################

#!/bin/bash
set -e

###############################################################################
# 1st: Source configurations
# - Load SDK configurations from external config file
###############################################################################
source /tmp/sdk_config.conf

###############################################################################
# 2nd: Setup utility functions
# - Logging function for better output visibility
###############################################################################
log() {
    echo -e "\n==========================================\n$1\n==========================================\n"
}

###############################################################################
# 3rd: Verify SDK installation and prepare environment
# - Check if SDK directory exists
# - Create necessary build directories
###############################################################################
if [ ! -d "${SDK_INSTALL_PATH}" ]; then
    log "Error: SDK installation directory not found at ${SDK_INSTALL_PATH}"
    exit 1
fi

mkdir -p ${SDK_INSTALL_PATH}/output/log
cd ${SDK_INSTALL_PATH}

###############################################################################
# 4th: Build SDK
# - Execute build command based on external configuration
###############################################################################
log "Starting SDK compilation at ${SDK_INSTALL_PATH}..."

if [ -f "Makefile" ]; then
    make rockchip_defconfig
    make all 2>&1 | tee output/log/build_$(date +%Y%m%d_%H%M%S).log
else
    log "Error: Makefile not found in ${SDK_INSTALL_PATH}"
    exit 1
fi

###############################################################################
# 5th: Verify build results
# - Check build output based on SDK requirements
###############################################################################
if [ ! -d "${SDK_INSTALL_PATH}/output" ]; then
    log "Error: Build output directory not found"
    exit 1
fi

log "SDK compilation completed successfully"