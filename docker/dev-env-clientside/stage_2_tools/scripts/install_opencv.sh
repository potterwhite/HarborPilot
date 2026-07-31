#!/bin/bash
################################################################################
# File: docker/stage_2_tools/scripts/install_opencv.sh
#
# Description: OpenCV installation script
#              Installs OpenCV and its dependencies
#
# Author: PotterWhite
# Created: 2024-11-21
# Last Modified: 2026-07-31
#
# Copyright (c) 2024
# License: MIT
################################################################################
set -e

# Source tool versions
source /tmp/tool_versions.conf

# Validate version format (e.g. 4.9.0 or 5.x)
if ! echo "${OPENCV_VERSION}" | grep -qE '^[0-9]+\.[0-9]+(\.[0-9]+)?$'; then
    echo "Error: OPENCV_VERSION '${OPENCV_VERSION}' is not a valid version format (expected X.Y or X.Y.Z)"
    exit 1
fi

# Warn on 5.x — may have compatibility issues with 4.x-dependent software
if [[ "${OPENCV_VERSION}" =~ ^5\. ]]; then
    echo "WARNING: OpenCV 5.x may have compatibility issues with software built against 4.x."
    echo "  - Verify your SDK and downstream dependencies support OpenCV 5.x."
    echo ""
fi

# Install OpenCV dependencies
apt-get update && apt-get install -y \
    libgtk2.0-dev \
    pkg-config \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Download and build OpenCV
cd /tmp
wget -O opencv.zip https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip
unzip opencv.zip
rm opencv.zip
cd opencv-${OPENCV_VERSION}

mkdir build && cd build
cmake -D CMAKE_BUILD_TYPE=RELEASE \
      -D CMAKE_INSTALL_PREFIX=/usr/local \
      -D WITH_CUDA=${INSTALL_CUDA} \
      ..
make -j$(nproc)
make install
ldconfig

# Cleanup
cd /tmp
rm -rf opencv-${OPENCV_VERSION}
