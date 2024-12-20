################################################################################
# File: docker/stage_2_tools/build.sh
#
# Description: Build script for stage 2 (development tools)
#              Builds the development tools Docker image
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
source "${BUILD_SCRIPT_DIR}/../../../project_handover/.env"

echo "Building development tools stage..."
echo "##### IMAGE_NAME: ${IMAGE_NAME}"
echo "##### INSTALL_DISTCC: ${INSTALL_DISTCC}"
docker build \
    --progress=plain \
    --no-cache \
    --network=host \
    --build-arg http_proxy="${http_proxy}"  \
    --build-arg https_proxy="${https_proxy}" \
    --build-arg no_proxy="${no_proxy}" \
    --build-arg HTTP_PROXY="${http_proxy}" \
    --build-arg HTTPS_PROXY="${https_proxy}" \
    --build-arg NO_PROXY="${no_proxy}" \
    --build-arg DEBIAN_FRONTEND="${DEBIAN_FRONTEND}" \
    --build-arg DEV_USERNAME="${DEV_USERNAME}" \
    --build-arg INSTALL_CUDA="${INSTALL_CUDA}" \
    --build-arg INSTALL_OPENCV="${INSTALL_OPENCV}" \
    --build-arg INSTALL_DISTCC="${INSTALL_DISTCC}" \
    --build-arg IMAGE_NAME="${IMAGE_NAME}" \
    --build-arg PROJECT_MAINTAINER="${PROJECT_MAINTAINER}" \
    --build-arg PROJECT_EMAIL="${PROJECT_EMAIL}" \
    --build-arg PROJECT_COPYRIGHT="${PROJECT_COPYRIGHT}" \
    --build-arg PROJECT_LICENSE="${PROJECT_LICENSE}" \
    --build-arg PROJECT_VERSION="${PROJECT_VERSION}" \
    --build-arg DISTCC_PORT="${DISTCC_PORT}" \
    --build-arg UBUNTU_SERVER_IP="${UBUNTU_SERVER_IP}" \
    --build-arg SDK_INSTALL_PATH="${SDK_INSTALL_PATH}" \
    --build-arg VOLUMES_ROOT="${VOLUMES_ROOT}" \
    --build-arg DEV_USERNAME="${DEV_USERNAME}" \
    --build-arg DEV_GROUP="${DEV_GROUP}" \
    -t "${IMAGE_NAME}:stage2" \
    -f "${BUILD_SCRIPT_DIR}/Dockerfile" \
    "${BUILD_SCRIPT_DIR}" 2>&1 | tee "${BUILD_SCRIPT_DIR}/build_log.txt"

# check if docker build failed and halt the script if it did
exit_status=${PIPESTATUS[0]}
if [ $exit_status -ne 0 ]; then
    echo "In ${BUILD_SCRIPT_PATH}, Docker build failed with exit status: $exit_status"
    exit $exit_status
fi