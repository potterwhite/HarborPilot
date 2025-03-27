#!/bin/bash
################################################################################
# File: docker/stage_3_sdk/build.sh
#
# Description: Build script for stage 3 (SDK installation)
#              Generates config from template and builds Docker image
#
################################################################################

func_setup_env(){
    set -e

    BUILD_SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
    BUILD_SCRIPT_DIR="$(dirname "${BUILD_SCRIPT_PATH}")"
    CLIENTSIDE_DIR="$(dirname "${BUILD_SCRIPT_DIR}")"
    DOCKER_DIR="$(dirname "${CLIENTSIDE_DIR}")"
    LIBS_DIR="${DOCKER_DIR}/libs"
    TOP_ROOT_DIR="$(dirname "${DOCKER_DIR}")"
    HANDOVER_DIR="${TOP_ROOT_DIR}/project_handover"
    STAGE3_CONFIG_DIR="${CLIENTSIDE_DIR}/stage_3_sdk/configs"
    STAGE3_SCRIPT_DIR="${CLIENTSIDE_DIR}/stage_3_sdk/scripts"

    FILE_ENV_PATH="${HANDOVER_DIR}/.env"

    # Load .env file
    source "${FILE_ENV_PATH}"

    source "${LIBS_DIR}/bash_modules/env_opts.sh"

    # Set default values
    SDK_INSTALL_PATH="${SDK_INSTALL_PATH:-/opt/sdk}"
}


func_build_docker_image(){
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
        --build-arg SDK_GIT_DEFAULT_BRANCH="${SDK_GIT_DEFAULT_BRANCH}" \
        --build-arg IMAGE_NAME="${IMAGE_NAME}" \
        --build-arg PROJECT_VERSION="${PROJECT_VERSION}" \
        -t "${IMAGE_NAME}:stage3" \
        -f "${BUILD_SCRIPT_DIR}/Dockerfile" \
        "${BUILD_SCRIPT_DIR}" 2>&1 | tee "${BUILD_SCRIPT_DIR}/build_log.txt"

    # Clean up processed files (清理生成的文件)
    # rm -f "${BUILD_SCRIPT_DIR}"/configs/*.{sh,conf}

    # check if docker build failed and halt the script if it did
    exit_status=${PIPESTATUS[0]}
    if [ $exit_status -ne 0 ]; then
        echo "In ${BUILD_SCRIPT_PATH}, Docker build failed with exit status: $exit_status"
        exit $exit_status
    fi
}

main(){
    func_setup_env
    func_utils_process_templates ${FILE_ENV_PATH} ${STAGE3_CONFIG_DIR} ${STAGE3_CONFIG_DIR}
    func_utils_process_templates ${FILE_ENV_PATH} ${STAGE3_SCRIPT_DIR} ${STAGE3_SCRIPT_DIR}
    func_build_docker_image
}

main "$@"