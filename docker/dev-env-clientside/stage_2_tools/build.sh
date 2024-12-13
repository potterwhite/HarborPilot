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
source "${BUILD_SCRIPT_DIR}/../../project_handover/.env"

echo "Building development tools stage..."
echo "##### IMAGE_NAME: ${IMAGE_NAME}"
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
    --build-arg IMAGE_NAME="${IMAGE_NAME}" \
    -t "${IMAGE_NAME}:stage2" \
    -f "${BUILD_SCRIPT_DIR}/Dockerfile" \
    "${BUILD_SCRIPT_DIR}" 2>&1 | tee "${BUILD_SCRIPT_DIR}/build_log.txt"