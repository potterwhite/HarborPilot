################################################################################
# File: docker/stage_2_tools/scripts/install_opencv.sh
#
# Description: OpenCV installation script
#              Installs OpenCV and its dependencies
#
# Author: MrJamesLZAZ
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