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
SDK_INSTALL_PATH="${SDK_INSTALL_PATH:-/opt/sdk}"

# Process all templates (处理所有模板文件)
echo "Processing template files..."
for template in "${BUILD_SCRIPT_DIR}"/configs/*.template "${BUILD_SCRIPT_DIR}"/configs/*.sh_template; do
    # Get output filename (获取输出文件名)
    case "$template" in
        *.sh_template)
            filename=$(basename "$template" .sh_template).sh
            ;;
        *.template)
            filename=$(basename "$template" .template)
            ;;
    esac

    echo "Processing $filename..."
    sed -e "s|[@\$]{SDK_INSTALL_PATH}|${SDK_INSTALL_PATH}|g" \
        -e "s|[@\$]{SDK_GIT_REPO}|${SDK_GIT_REPO}|g" \
        -e "s|\${SDK_GIT_KEY_FILE}|${SDK_GIT_KEY_FILE}|g" \
        -e "s|\${SDK_GIT_HOST}|${SDK_GIT_HOST}|g" \
        "$template" > "${BUILD_SCRIPT_DIR}/configs/$filename"

    # Make shell scripts executable (使shell脚本可执行)
    [[ "$filename" == *.sh ]] && chmod +x "${BUILD_SCRIPT_DIR}/configs/$filename"
done

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
    --build-arg SDK_INSTALL_PATH="${SDK_INSTALL_PATH}" \
    --build-arg SDK_GIT_REPO="${SDK_GIT_REPO}" \
    --build-arg SDK_SSH_KEY_NAME="${SDK_SSH_KEY_NAME}" \
    --build-arg IMAGE_NAME="${IMAGE_NAME}" \
    -t "${IMAGE_NAME}:stage3" \
    -f "${BUILD_SCRIPT_DIR}/Dockerfile" \
    "${BUILD_SCRIPT_DIR}" 2>&1 | tee "${BUILD_SCRIPT_DIR}/build_log.txt"

# Clean up processed files (清理生成的文件)
# rm -f "${BUILD_SCRIPT_DIR}"/configs/*.{sh,conf}