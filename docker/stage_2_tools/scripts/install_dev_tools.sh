################################################################################
# File: docker/stage_2_tools/scripts/install_dev_tools.sh
#
# Description: Main script for installing development tools
#              Installs compilers, debuggers, and development utilities
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

# Source tool versions
source /tmp/tool_versions.conf

# Category 1: Core Build Tools and Compilers
# Essential compilation and build system tools
apt-get update && apt-get install -y \
    build-essential \
    cmake \
    ninja-build \
    make \
    autoconf \
    automake \
    libtool \
    meson \
    pkg-config \
    ccache

# Category 2: Development and Debug Tools
# Tools for debugging, code analysis and development
apt-get install -y \
    gdb \
    valgrind \
    clang \
    clang-format \
    clang-tidy \
    lldb \
    cppcheck \
    minicom

# Category 3: Documentation and Visualization Tools
apt-get install -y \
    doxygen \
    graphviz

# Category 4: Version Control and Development Utilities
apt-get install -y \
    git \
    python2.7 \
    python3 \
    python3-pip

# Category 5: Kernel Development Tools
apt-get install -y \
    device-tree-compiler \
    liblz4-tool \
    liblz4-dev \
    libssl-dev \
    expect \
    libncurses5-dev \
    bison \
    flex \
    texinfo \
    exuberant-ctags \
    cscope

# Category 6: Node.js and JavaScript Development
install_node() {
    echo "Installing nvm and Node.js..."
    # Install nvm
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

    # Add nvm to current shell session
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # Install Node.js LTS version
    if ! nvm install --lts; then
        echo "Failed to install Node.js LTS"
        return 1
    fi

    # Use the installed version
    if ! nvm use --lts; then
        echo "Failed to use Node.js LTS"
        return 1
    fi

    # Add nvm setup to user profile
    cat >> /home/$DEV_USERNAME/.bashrc << EOF
export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "\$NVM_DIR/bash_completion" ] && \. "\$NVM_DIR/bash_completion"  # This loads nvm bash_completion
EOF

    return 0
}

# Call install_node and exit if it fails
if ! install_node; then
    echo "Critical: Node.js environment setup failed. Exiting..."
    exit 1
fi

# Python package installation helper
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

# Install Python packages if versions are defined
[ ! -z "${CMAKE_FORMAT_VERSION}" ] && install_python_package "cmake-format" "${CMAKE_FORMAT_VERSION}"
[ ! -z "${PRE_COMMIT_VERSION}" ] && install_python_package "pre-commit" "${PRE_COMMIT_VERSION}"

# Install ARM toolchain if specified
if [ "${INSTALL_ARM_TOOLCHAIN}" = "true" ]; then
    apt-get update && apt-get install -y \
        gcc-arm-linux-gnueabi \
        g++-arm-linux-gnueabi \
        gcc-arm-linux-gnueabihf \
        g++-arm-linux-gnueabihf
fi

# Cleanup
apt-get clean && rm -rf /var/lib/apt/lists/*
