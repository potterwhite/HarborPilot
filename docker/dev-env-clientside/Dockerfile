################################################################################
# File: docker/stage_1_base/Dockerfile
#
# Description: Base stage Dockerfile for embedded development environment
#              Sets up the fundamental Ubuntu system with essential packages
#
# Author: [Your Name]
# Created: 2024-11-21
# Last Modified: 2024-11-21
#
# Copyright (c) 2024 [Your Company/Name]
# License: MIT
################################################################################

FROM ubuntu:22.04 AS stage_1st_base

SHELL ["/bin/bash", "-c"]

# Build arguments
ARG DEBIAN_FRONTEND
ARG TIMEZONE
ARG DEV_USERNAME
ARG DEV_USER_PASSWORD
ARG DEV_UID
ARG DEV_GID
ARG DEV_USER_ROOT_PASSWORD

ENV DEBIAN_FRONTEND=${DEBIAN_FRONTEND}
ENV TIMEZONE=${TIMEZONE}
ENV DEV_USERNAME=${DEV_USERNAME}
ENV DEV_USER_PASSWORD=${DEV_USER_PASSWORD}
ENV DEV_UID=${DEV_UID}
ENV DEV_GID=${DEV_GID}
ENV DEV_USER_ROOT_PASSWORD=${DEV_USER_ROOT_PASSWORD}

# Copy scripts
COPY stage_1_base/scripts/setup_base.sh /tmp/

# Change apt source to China mirrors
RUN echo "Change apt source to China mirrors" && \
    sed -i 's|http://archive.ubuntu.com/ubuntu/|http://mirrors.aliyun.com/ubuntu/|g' /etc/apt/sources.list && \
    echo -e "Done\n"

# First install certificates and basic tools (首先安装证书和基本工具)
RUN apt-get update && \
    apt-get install -y ca-certificates bash && \
    update-ca-certificates

# Then setup sources and continue (然后设置源并继续)
# COPY configs/apt_sources.list /etc/apt/sources.list
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get update

# Execute base setup
RUN chmod +x /tmp/setup_base.sh && \
    /tmp/setup_base.sh && \
    rm -f /tmp/setup_base.sh

RUN echo -e "Stage 1st completed!\n"

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


# ARG IMAGE_NAME=embedded-dev
# ARG IMAGE_NAME=${IMAGE_NAME}
# ENV IMAGE_NAME=${IMAGE_NAME}
# Use stage 1 as base
FROM stage_1st_base AS stage_2nd_tools

# Build arguments
ARG DEBIAN_FRONTEND
ARG INSTALL_CUDA
ARG INSTALL_OPENCV
ARG INSTALL_DISTCC
ARG DEV_USERNAME
ARG PROJECT_VERSION
ARG PROJECT_MAINTAINER
ARG PROJECT_EMAIL
ARG PROJECT_COPYRIGHT
ARG PROJECT_LICENSE
ARG DISTCC_PORT
ARG UBUNTU_SERVER_IP
ARG SDK_INSTALL_PATH
ARG VOLUMES_ROOT
ARG DEV_USERNAME
ARG DEV_GROUP

################################################################################
# Copy scripts and configs
################################################################################
COPY stage_2_tools/scripts/install_dev_tools.sh /tmp/
COPY stage_2_tools/scripts/install_cuda.sh /tmp/
COPY stage_2_tools/scripts/install_opencv.sh /tmp/
COPY stage_2_tools/scripts/install_distcc_switcher.sh /tmp/
COPY stage_2_tools/configs/tool_versions.conf /tmp/
COPY stage_2_tools/scripts/gitlfs_tracker.sh /usr/local/bin/

# Copy offline packages if they exist
COPY stage_2_tools/offline_toolchain /tmp/offline_toolchain/

################################################################################
# Install all tools if configured enabled
################################################################################
# Install distcc switcher if configured enabled
RUN if [ "${INSTALL_DISTCC}" = "true" ]; then \
        echo -e "\n\n##########################################################\n(1/5)Installing distcc switcher...\n##########################################################\n\n"; \
        chmod +x /tmp/install_distcc_switcher.sh && \
        /tmp/install_distcc_switcher.sh && \
        echo -e "\n\n##########################################################\n(1/5)Distcc switcher is installed, Done\n##########################################################\n\n"; \
    else \
        echo "INSTALL_DISTCC=${INSTALL_DISTCC}"; \
        rm -f /tmp/install_distcc_switcher.sh; \
        echo -e "\n\n##########################################################\n(1/5)Distcc switcher is not installed, Removed install_distcc_switcher.sh, Done\n##########################################################\n\n"; \
    fi

RUN if [ "${INSTALL_TOOLCHAIN}" = "true" ]; then \
        ls -lha /tmp/offline_toolchain && \
        echo -e "\n\n##########################################################\n(2/5)Installing GCC...\n##########################################################\n\n"; \
        chmod +x /tmp/offline_toolchain/gcc/install_gcc.sh && \
        /tmp/offline_toolchain/gcc/install_gcc.sh && \
        echo -e "\n\n##########################################################\n(2/5)GCC is installed, Done\n##########################################################\n\n"; \
    else \
        echo "INSTALL_TOOLCHAIN=${INSTALL_TOOLCHAIN}"; \
        rm -f /tmp/offline_toolchain/gcc/install_gcc.sh; \
        echo -e "\n\n##########################################################\n(2/5)GCC is not installed, Removed, Done\n##########################################################\n\n"; \
    fi

# Install CUDA if configured enabled
RUN if [ "${INSTALL_CUDA}" = "true" ]; then \
        echo -e "\n\n##########################################################\n(3/5)Installing CUDA...\n##########################################################\n\n"; \
        chmod +x /tmp/install_cuda.sh && \
        /tmp/install_cuda.sh; \
        echo -e "\n\n##########################################################\n(3/5)CUDA is installed, Done\n##########################################################\n\n"; \
    else \
        rm -f /tmp/install_cuda.sh; \
        echo -e "\n\n##########################################################\n(3/5)CUDA is not installed, Removed install_cuda.sh, Done\n##########################################################\n\n"; \
    fi

# Install OpenCV if configured enabled
RUN if [ "${INSTALL_OPENCV}" = "true" ]; then \
        chmod +x /tmp/install_opencv.sh && \
        /tmp/install_opencv.sh; \
        echo -e "\n\n##########################################################\n(4/5)OpenCV is installed, Done\n##########################################################\n\n"; \
    else \
        rm -f /tmp/install_opencv.sh; \
        echo -e "\n\n##########################################################\n(4/5)OpenCV is not installed, Removed install_opencv.sh, Done\n##########################################################\n\n"; \
    fi

# Execute tools installation
RUN echo -e "\n\n##########################################################\n(5/5)Installing dev tools...\n##########################################################\n\n"; \
    chmod +x /tmp/install_dev_tools.sh && \
    /tmp/install_dev_tools.sh && \
    echo -e "\n\n##########################################################\n(4/5)Dev Tools are installed, Done\n##########################################################\n\n";

# Install gitlfs tracker, a diy git lfs tracker to help git operations
RUN chmod +x /usr/local/bin/gitlfs_tracker.sh



################################################################################
# Clean up
################################################################################
RUN rm -rf /tmp/offline_toolchain
RUN rm -f /tmp/install_*.sh /tmp/tool_versions.conf
