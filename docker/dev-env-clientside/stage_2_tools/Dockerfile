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
ARG DEBIAN_FRONTEND
ARG INSTALL_CUDA
ARG INSTALL_OPENCV
ARG INSTALL_DISTCC
ARG DEV_USERNAME

################################################################################
# Copy scripts and configs
################################################################################
COPY scripts/install_dev_tools.sh /tmp/
COPY scripts/install_cuda.sh /tmp/
COPY scripts/install_opencv.sh /tmp/
COPY scripts/install_distcc_switcher.sh /tmp/
COPY configs/tool_versions.conf /tmp/
COPY scripts/gitlfs_tracker.sh /usr/local/bin/

# Copy offline packages if they exist
COPY offline_packages /tmp/offline_packages/

################################################################################
# Install all tools if configured enabled
################################################################################
# Install distcc switcher if configured enabled
RUN if [ "${INSTALL_DISTCC}" = "true" ]; then \
        echo -e "\n\n##########################################################\nInstalling distcc switcher...\n##########################################################\n\n"; \
        chmod +x /tmp/install_distcc_switcher.sh && \
        /tmp/install_distcc_switcher.sh && \
        echo -e "\n\n##########################################################\nDistcc switcher is installed, Done\n##########################################################\n\n"; \
    else \
        echo "INSTALL_DISTCC=${INSTALL_DISTCC}"; \
        rm -f /tmp/install_distcc_switcher.sh; \
        echo -e "\n\n##########################################################\nDistcc switcher is not installed, Removed install_distcc_switcher.sh, Done\n##########################################################\n\n"; \
    fi


RUN ls -lha /tmp/offline_packages && \
    echo -e "\n\n##########################################################\nInstalling GCC...\n##########################################################\n\n"; \
    chmod +x /tmp/offline_packages/gcc/install_gcc.sh && \
    /tmp/offline_packages/gcc/install_gcc.sh && \
    echo -e "\n\n##########################################################\nGCC is installed, Done\n##########################################################\n\n";

# Execute tools installation
RUN echo -e "\n\n##########################################################\nInstalling dev tools...\n##########################################################\n\n"; \
    chmod +x /tmp/install_dev_tools.sh && \
    /tmp/install_dev_tools.sh && \
    echo -e "\n\n##########################################################\nTools are installed, Done\n##########################################################\n\n";

# Install gitlfs tracker, a diy git lfs tracker to help git operations
RUN chmod +x /usr/local/bin/gitlfs_tracker.sh

# Install CUDA if configured enabled
RUN if [ "${INSTALL_CUDA}" = "true" ]; then \
        echo -e "\n\n##########################################################\nInstalling CUDA...\n##########################################################\n\n"; \
        chmod +x /tmp/install_cuda.sh && \
        /tmp/install_cuda.sh; \
        echo -e "\n\n##########################################################\nCUDA is installed, Done\n##########################################################\n\n"; \
    else \
        rm -f /tmp/install_cuda.sh; \
        echo -e "\n\n##########################################################\nCUDA is not installed, Removed install_cuda.sh, Done\n##########################################################\n\n"; \
    fi

# Install OpenCV if configured enabled
RUN if [ "${INSTALL_OPENCV}" = "true" ]; then \
        chmod +x /tmp/install_opencv.sh && \
        /tmp/install_opencv.sh; \
        echo -e "\n\n##########################################################\nOpenCV is installed, Done\n##########################################################\n\n"; \
    else \
        rm -f /tmp/install_opencv.sh; \
        echo -e "\n\n##########################################################\nOpenCV is not installed, Removed install_opencv.sh, Done\n##########################################################\n\n"; \
    fi


################################################################################
# Clean up
################################################################################
RUN rm -rf /tmp/offline_packages
RUN rm -f /tmp/install_*.sh /tmp/tool_versions.conf
