#!/bin/bash

set -e

BUILD_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# ROOT_DIR="$(cd "${BUILD_SCRIPT_DIR}/../../" && pwd)"
TEMP_TOOLCHAIN_TARBALLS_DIR="${BUILD_SCRIPT_DIR}../dev-env-clientside/stage_2_tools/offline_packages/gcc"
TEMP_TOOLCHAIN_INSTALL_CONFIG_PATH="${TEMP_TOOLCHAIN_TARBALLS_DIR}/../../configs/tool_version.conf"
TEMP_ENTRYPOINT_SCRIPT_DIR=${BUILD_SCRIPT_DIR}/configs
TEMP_ENTRYPOINT_SCRIPT_FILE=${TEMP_ENTRYPOINT_SCRIPT_DIR}/entrypoint.sh 

# Load .env file
set -a
source "${BUILD_SCRIPT_DIR}/../../project_handover/.env"
set +a

read_module() {
    cat "${BUILD_SCRIPT_DIR}/../dockerfile_modules/$1.df" | envsubst
}

entrypoint_preparation() {
    mkdir -p ${TEMP_ENTRYPOINT_SCRIPT_DIR}
    touch ${TEMP_ENTRYPOINT_SCRIPT_DIR}/${TEMP_ENTRYPOINT_SCRIPT_FILE}

}

setup_dockerfile() {

    cat > Dockerfile << DELIM
FROM ubuntu:22.04

$(read_module apt_source)
$(read_module base_packages)

RUN apt-get update && apt-get install -y \
    distcc \
    && rm -rf /var/lib/apt/lists/*

#############################################
#  toolchian init
#############################################
RUN mkdir -p ${TOOLCHAIN_DIR}
COPY ${TEMP_TOOLCHAIN_INSTALL_CONFIG_PATH} /tmp
COPY ${TEMP_TOOLCHAIN_TARBALLS_DIR}/install_gcc.sh /tmp
COPY ${TEMP_TOOLCHAIN_TARBALLS_DIR}/${TOOLCHAIN_TARBALL_NAME} /tmp

RUN ls -lha /tmp && \
    chmod +x /tmp/install_gcc.sh && \
    /tmp/install_gcc.sh 

#############################################
#  entrypoint init
#############################################
# COPY ${TEMP_ENTRYPOINT_SCRIPT_DIR}/${TEMP_ENTRYPOINT_SCRIPT_FILE} /usr/local/bin/${TEMP_ENTRYPOINT_SCRIPT_FILE}

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
DELIM

#     tee Dockerfile > /dev/null << DELIM
# ${dockerfile_content}
# DELIM

}

# 在适当位置添加
build_distcc_image() {
    print_msg "Building distcc image for ${DISTCC_CONTAINER_NAME}..."

    # 使用与主开发环境相同的工具链
    docker build \
        --progress=plain \
        --no-cache \
        --network=host \
        -t "${REGISTRY_URL}/${DISTCC_CONTAINER_NAME}:${PROJECT_VERSION}" \
        -f ${BUILD_SCRIPT_DIR}/DockerfileOfServerSide \
        ${DISTCC_IMAGE_NAME}
}

cleanup(){
    echo "Done cleanup()"
}

main() {

    setup_dockerfile

    # build_distcc_image

    # cleanup

    echo "Serverside building completed."
}


# Ensure cleanup runs even if script fails
trap cleanup EXIT

main "$@"

