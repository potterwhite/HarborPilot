################################################################################
# File: docker/stage_2_tools/Dockerfile
#
# Description: Development tools stage Dockerfile
#              Installs development tools and utilities for embedded development
#
# Author: [Your Name]
# Created: 2024-11-21
# Last Modified: 2024-11-21
#
# Copyright (c) 2024 [Your Company/Name]
# License: MIT
################################################################################


ARG IMAGE_NAME=embedded-dev
# ARG IMAGE_NAME=${IMAGE_NAME}
# ENV IMAGE_NAME=${IMAGE_NAME}
# Use stage 1 as base
FROM ${IMAGE_NAME}:stage1

# Build arguments
ARG DEBIAN_FRONTEND=${DEBIAN_FRONTEND}
ARG INSTALL_CUDA=${INSTALL_CUDA}
ARG INSTALL_OPENCV=${INSTALL_OPENCV}

# ENV DEBIAN_FRONTEND=${DEBIAN_FRONTEND}
# ENV INSTALL_CUDA=${INSTALL_CUDA}
# ENV INSTALL_OPENCV=${INSTALL_OPENCV}

# Copy scripts and configs
COPY scripts/install_dev_tools.sh /tmp/
COPY scripts/install_cuda.sh /tmp/
COPY scripts/install_opencv.sh /tmp/
COPY configs/tool_versions.conf /tmp/
COPY scripts/gitlfs_tracker.sh /usr/local/bin/

# Copy offline packages if they exist
COPY offline_packages /tmp/offline_packages/

# Install GCC if configured
RUN ls -lha /tmp/offline_packages && \
    chmod +x /tmp/offline_packages/gcc/install_gcc.sh && \
    /tmp/offline_packages/gcc/install_gcc.sh

# Clean up
RUN rm -rf /tmp/offline_packages

# Execute tools installation
RUN chmod +x /tmp/install_dev_tools.sh && \
    chmod +x /tmp/install_cuda.sh && \
    chmod +x /tmp/install_opencv.sh && \
    chmod +x /usr/local/bin/gitlfs_tracker.sh && \
    /tmp/install_dev_tools.sh && \
    if [ "${INSTALL_CUDA}" = "true" ]; then /tmp/install_cuda.sh; fi && \
    if [ "${INSTALL_OPENCV}" = "true" ]; then /tmp/install_opencv.sh; fi && \
    rm -f /tmp/install_*.sh /tmp/tool_versions.conf
