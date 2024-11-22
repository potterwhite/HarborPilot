################################################################################
# File: docker/stage_3_sdk/build.sh
#
# Description: Build script for stage 3 (SDK installation)
#              Generates config from template and builds Docker image
#
################################################################################

#!/bin/bash
set -e

BUILD_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${BUILD_SCRIPT_DIR}/../../" && pwd)"

# Load .env file
source "${ROOT_DIR}/project_handover/.env"

# Set default values
SDK_PACKAGE="${SDK_PACKAGE:-embedded-sdk-1.0.tar.gz}"
SDK_INSTALL_PATH="${SDK_INSTALL_PATH:-/opt/sdk}"
SDK_VERSION="${SDK_VERSION:-1.0}"

# Generate sdk_config.conf from template
echo "Generating sdk_config.conf from template..."
sed -e "s|@SDK_PACKAGE@|${SDK_PACKAGE}|g" \
    -e "s|@SDK_INSTALL_PATH@|${SDK_INSTALL_PATH}|g" \
    -e "s|@SDK_VERSION@|${SDK_VERSION}|g" \
    "${BUILD_SCRIPT_DIR}/configs/sdk_config.conf.template" > "${BUILD_SCRIPT_DIR}/configs/sdk_config.conf"

# Verify SDK package exists
if [ ! -f "${BUILD_SCRIPT_DIR}/offline_packages/${SDK_PACKAGE}" ]; then
    echo "Error: SDK package not found: ${SDK_PACKAGE}"
    echo "Please place the SDK package in docker/stage_3_sdk/offline_packages/"
    exit 1
fi

echo "Building SDK installation stage..."
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
    --build-arg SDK_VERSION="${SDK_VERSION}" \
    --build-arg SDK_INSTALL_PATH="${SDK_INSTALL_PATH}" \
    --build-arg SDK_PACKAGE="${SDK_PACKAGE}" \
    -t "${IMAGE_NAME}:stage3" \
    -f "${BUILD_SCRIPT_DIR}/Dockerfile" \
    "${BUILD_SCRIPT_DIR}" 2>&1 | tee "${BUILD_SCRIPT_DIR}/build_log.txt"

# Optionally, clean up the generated config
# rm "${BUILD_SCRIPT_DIR}/configs/sdk_config.conf"