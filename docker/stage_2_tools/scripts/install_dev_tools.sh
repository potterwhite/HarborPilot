################################################################################
# File: docker/stage_2_tools/scripts/install_dev_tools.sh
#
# Description: Main script for installing development tools
#              Installs compilers, debuggers, and development utilities
#
# Author: [Your Name]
# Created: 2024-03-21
# Last Modified: 2024-03-21
#
# Copyright (c) 2024 [Your Company/Name]
# License: MIT
################################################################################

#!/bin/bash
set -e

# Source tool versions
source /tmp/tool_versions.conf

# Install development tools
apt-get update && apt-get install -y \
    cmake \
    ninja-build \
    gdb \
    valgrind \
    clang \
    clang-format \
    clang-tidy \
    lldb \
    ccache \
    cppcheck \
    doxygen \
    graphviz \
    pkg-config \
    autoconf \
    automake \
    libtool \
    meson \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install additional Python packages with timeout and retry (添加超时和重试机制)
install_python_package() {
    local package=$1
    local version=$2
    local max_retries=3
    local retry=0

    while [ $retry -lt $max_retries ]; do
        if pip3 install --no-cache-dir \
           -i https://mirrors.aliyun.com/pypi/simple/ \
           --trusted-host mirrors.aliyun.com \
           --timeout 30 \
           "${package}==${version}"; then
            return 0
        fi
        echo "Retry installing ${package} (${retry}/${max_retries})"
        retry=$((retry + 1))
        sleep 5
    done
    echo "Warning: Failed to install ${package}, continuing anyway..."
    return 0
}

# Install Python packages if versions are defined (如果定义了版本则安装)
[ ! -z "${CMAKE_FORMAT_VERSION}" ] && install_python_package "cmake-format" "${CMAKE_FORMAT_VERSION}"
[ ! -z "${PRE_COMMIT_VERSION}" ] && install_python_package "pre-commit" "${PRE_COMMIT_VERSION}"

# Install ARM toolchain if specified
if [ "${INSTALL_ARM_TOOLCHAIN}" = "true" ]; then
    apt-get update && apt-get install -y \
        gcc-arm-linux-gnueabi \
        g++-arm-linux-gnueabi \
        gcc-arm-linux-gnueabihf \
        g++-arm-linux-gnueabihf \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*
fi
