################################################################################
# File: docker/stage_2_tools/scripts/install_cuda.sh
#
# Description: CUDA installation script
#              Installs CUDA toolkit and dependencies
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

# Install CUDA dependencies
apt-get update && apt-get install -y \
    wget \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Add CUDA repository and install CUDA toolkit
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb
dpkg -i cuda-keyring_1.0-1_all.deb
rm cuda-keyring_1.0-1_all.deb

apt-get update && apt-get install -y \
    cuda-toolkit-${CUDA_VERSION} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*