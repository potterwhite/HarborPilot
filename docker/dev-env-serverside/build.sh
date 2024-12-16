#!/bin/bash

set -e

BUILD_SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd ${BUILD_SCRIPT_DIR}

echo "BUILD_SCRIPT_DIR=${BUILD_SCRIPT_DIR}"
echo "current_dir=$(pwd -P)"

# read -r ${OHNO}
# Load .env file
set -a
source "${BUILD_SCRIPT_DIR}/../../project_handover/.env"
set +a

# ROOT_DIR="$(cd "${BUILD_SCRIPT_DIR}/../../" && pwd)"
TEMP_TOOLCHAIN_SRC_GCC="${BUILD_SCRIPT_DIR}/../dev-env-clientside/stage_2_tools/offline_packages/gcc/${TOOLCHAIN_TARBALL_NAME}"
TEMP_TOOLCHAIN_SRC_INSTALL_GCC="${BUILD_SCRIPT_DIR}/../dev-env-clientside/stage_2_tools/offline_packages/gcc/install_gcc.sh"
TEMP_TOOLCHAIN_SRC_CONFIG_PATH="${BUILD_SCRIPT_DIR}/../dev-env-clientside/stage_2_tools/configs/tool_versions.conf"

TEMP_TOOLCHAIN_TARBALLS_DIR="TeMp_toolchains"
TEMP_TOOLCHAIN_TARGET_GCC="${TEMP_TOOLCHAIN_TARBALLS_DIR}/${TOOLCHAIN_TARBALL_NAME}"
TEMP_TOOLCHAIN_TARGET_INSTALL_GCC="${TEMP_TOOLCHAIN_TARBALLS_DIR}/install_gcc.sh"
TEMP_TOOLCHAIN_TARGET_CONFIG_PATH="${TEMP_TOOLCHAIN_TARBALLS_DIR}/tool_versions.conf"

TEMP_ENTRYPOINT_SCRIPT_DIR="TeMp_configs"
TEMP_ENTRYPOINT_SCRIPT_FILE="entrypoint.sh"
TEMP_DOCKERFILE_NAME="DockerfileOfServerSide"

read_module() {
    cat "${BUILD_SCRIPT_DIR}/../dockerfile_modules/$1.df" | envsubst
}

toolchain_preparation() {
    mkdir -p ${TEMP_TOOLCHAIN_TARBALLS_DIR}

    cp ${TEMP_TOOLCHAIN_SRC_GCC} ${TEMP_TOOLCHAIN_TARGET_GCC}
    cp ${TEMP_TOOLCHAIN_SRC_INSTALL_GCC} ${TEMP_TOOLCHAIN_TARGET_INSTALL_GCC}
    cp ${TEMP_TOOLCHAIN_SRC_CONFIG_PATH} ${TEMP_TOOLCHAIN_TARGET_CONFIG_PATH}

    ls -lha ${TEMP_TOOLCHAIN_TARBALLS_DIR}
}

entrypoint_preparation() {
    # 首先设置日志相关的环境变量
    local log_dir="/development/docker_volumes/log/distccd"
    local log_level="${DISTCC_LOG_LEVEL:-debug}"

    mkdir -p ${TEMP_ENTRYPOINT_SCRIPT_DIR}
    touch ${TEMP_ENTRYPOINT_SCRIPT_DIR}/${TEMP_ENTRYPOINT_SCRIPT_FILE}

    cat > ${TEMP_ENTRYPOINT_SCRIPT_DIR}/${TEMP_ENTRYPOINT_SCRIPT_FILE} << 'EOF'
#!/bin/bash

# 启用错误追踪
set -e

# 添加调试输出
echo "Starting distcc server..."

# 创建日志目录
if ! mkdir -p /development/docker_volumes/log/distccd; then
    echo "ERROR: Failed to create log directory"
    exit 1
fi

# 获取CPU信息并验证
AVAILABLE_CORES=$(nproc)
if [ -z "${AVAILABLE_CORES}" ] || [ "${AVAILABLE_CORES}" -eq 0 ]; then
    echo "ERROR: Failed to get CPU cores, using default value 1"
    AVAILABLE_CORES=1
fi
echo "Available cores: ${AVAILABLE_CORES}"

# 计算作业数并验证
DISTCC_JOBS=$(( ${AVAILABLE_CORES} * 8/10 ))
if [ "${DISTCC_JOBS}" -lt 1 ]; then
    echo "WARNING: Calculated jobs too low, using default value 1"
    DISTCC_JOBS=1
fi
echo "Setting jobs to: ${DISTCC_JOBS}"

# 启动服务
exec distccd --daemon --no-detach \
    --allow 192.168.0.0/16 \
    --jobs ${DISTCC_JOBS} \
    --log-stderr \
    --log-level debug \
    --log-file /development/docker_volumes/log/distccd/distcc.log \
    --stats \
    --stats-port 3633
EOF
    chmod +x ${TEMP_ENTRYPOINT_SCRIPT_DIR}/${TEMP_ENTRYPOINT_SCRIPT_FILE}
}

setup_dockerfile() {

    cat > "${BUILD_SCRIPT_DIR}/${TEMP_DOCKERFILE_NAME}" << DELIM
FROM ubuntu:22.04

$(read_module apt_source)
$(read_module base_packages)

RUN apt-get update && apt-get install -y \
    distcc \
    && rm -rf /var/lib/apt/lists/*

#############################################
#  toolchian init
#############################################
RUN mkdir -p /tmp/offline_packages/gcc

COPY ${TEMP_TOOLCHAIN_TARGET_GCC} /tmp/offline_packages/gcc/
COPY ${TEMP_TOOLCHAIN_TARGET_INSTALL_GCC} /tmp/offline_packages/gcc/
COPY ${TEMP_TOOLCHAIN_TARGET_CONFIG_PATH} /tmp

RUN ls -lha /tmp/  && \
    ls -lha /tmp/offline_packages/ && \
    ls -lha /tmp/offline_packages/gcc/ && \
    chmod +x /tmp/offline_packages/gcc/install_gcc.sh && \
    /tmp/offline_packages/gcc/install_gcc.sh && \
    echo "source /etc/environment" >> /etc/bash.bashrc && \
    chmod 644 /etc/environment

#############################################
#  entrypoint init
#############################################
COPY ${TEMP_ENTRYPOINT_SCRIPT_DIR}/${TEMP_ENTRYPOINT_SCRIPT_FILE} /usr/local/bin/${TEMP_ENTRYPOINT_SCRIPT_FILE}

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
DELIM
}

# 在适当位置添加
build_distcc_image() {
    echo "Building dev-env-serverside image for ${SERVERSIDE_IMAGE_NAME}..."

    # 使用与主开发环境相同的工具链
    docker build \
        --progress=plain \
        --no-cache \
        --network=host \
        -t "${SERVERSIDE_IMAGE_NAME}:${PROJECT_VERSION}" \
        -f "${BUILD_SCRIPT_DIR}/${TEMP_DOCKERFILE_NAME}" \
        ${BUILD_SCRIPT_DIR}
}

cleanup(){
    rm -rf ${BUILD_SCRIPT_DIR}/${TEMP_TOOLCHAIN_TARBALLS_DIR}
    rm -rf ${BUILD_SCRIPT_DIR}/${TEMP_ENTRYPOINT_SCRIPT_DIR}
    rm -f ${BUILD_SCRIPT_DIR}/${TEMP_DOCKERFILE_NAME}
    echo "Done cleanup()"
}

main() {

    toolchain_preparation

    entrypoint_preparation

    setup_dockerfile

    build_distcc_image

    # cleanup

    echo "Serverside building completed."
}


# Ensure cleanup runs even if script fails
# trap cleanup EXIT

main "$@"

