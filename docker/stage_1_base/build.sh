#!/bin/bash

################################################################################
# File: docker/stage_1_base/build.sh
#
# Description: Build script for stage 1 (base environment)
#              This script builds the base Docker image
#
# Author: [Your Name]
# Created: 2024-11-21
# Last Modified: 2024-11-21
#
# Copyright (c) 2024 [Your Company/Name]
# License: MIT
################################################################################

set -e

BUILD_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${BUILD_SCRIPT_DIR}/../../project_handover/.env"

echo "Building base stage..."
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
    --build-arg DEV_UID="${DEV_UID}" \
    --build-arg DEV_GID="${DEV_GID}" \
    --build-arg TIMEZONE="${TIMEZONE}" \
    -t "${IMAGE_NAME}:stage1" \
    -f "${BUILD_SCRIPT_DIR}/Dockerfile" \
    "${BUILD_SCRIPT_DIR}" 2>&1 | tee build_log.txt
