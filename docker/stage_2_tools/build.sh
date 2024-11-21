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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../project_handover/.env"

echo "Building development tools stage..."
docker build \
    --progress=plain \
    --no-cache \
    --build-arg DEBIAN_FRONTEND="${DEBIAN_FRONTEND}" \
    --build-arg INSTALL_CUDA="${INSTALL_CUDA}" \
    --build-arg INSTALL_OPENCV="${INSTALL_OPENCV}" \
    -t "${IMAGE_NAME}:stage2" \
    -f "${SCRIPT_DIR}/Dockerfile" \
    "${SCRIPT_DIR}" 2>&1 | tee build_log.txt