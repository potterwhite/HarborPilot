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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../.env"

echo "Building base stage..."
docker build \
    --progress=plain \
    --no-cache \
    --build-arg USERNAME="${DEV_USERNAME}" \
    --build-arg USER_UID="${DEV_UID}" \
    --build-arg USER_GID="${DEV_GID}" \
    --build-arg TZ="${TIMEZONE}" \
    -t "${IMAGE_NAME}:stage1" \
    -f "${SCRIPT_DIR}/Dockerfile" \
    "${SCRIPT_DIR}" 2>&1 | tee build_log.txt
