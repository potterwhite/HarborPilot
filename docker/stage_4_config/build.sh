################################################################################
# File: docker/stage_4_config/build.sh
#
# Description: Build script for stage 4 (environment configuration)
#              Builds the environment configuration Docker image
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

BUILD_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${BUILD_SCRIPT_DIR}/../../.env"

# Check required variables
for var in DEV_USERNAME DEV_UID DEV_GID SDK_INSTALL_PATH IMAGE_NAME; do
    if [ -z "${!var}" ]; then
        echo "Error: $var is not set in .env file"
        exit 1
    fi
done

# Generate configuration from template
sed -e "s|{{USERNAME}}|${DEV_USERNAME}|g" \
    -e "s|{{USER_UID}}|${DEV_UID}|g" \
    -e "s|{{USER_GID}}|${DEV_GID}|g" \
    -e "s|{{SDK_INSTALL_PATH}}|${SDK_INSTALL_PATH}|g" \
    "${BUILD_SCRIPT_DIR}/configs/env_config.conf.template" > "${BUILD_SCRIPT_DIR}/configs/env_config.conf"

# Build Docker image
echo "Building environment configuration stage..."
docker build \
    --progress=plain \
    --build-arg USERNAME="${DEV_USERNAME}" \
    --build-arg USER_UID="${DEV_UID}" \
    --build-arg USER_GID="${DEV_GID}" \
    --build-arg SDK_INSTALL_PATH="${SDK_INSTALL_PATH}" \
    -t "${IMAGE_NAME}:stage4" \
    -f "${BUILD_SCRIPT_DIR}/Dockerfile" \
    "${BUILD_SCRIPT_DIR}" 2>&1 | tee build_log.txt