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

# =============================================================================
# 所有构建参数定义 - 第一阶段定义，所有后续阶段自动继承
# =============================================================================

# -----------------------------------------------------------------------------
# 项目信息 (6个)
# -----------------------------------------------------------------------------
ARG PROJECT_MAINTAINER
ARG PROJECT_EMAIL
ARG PROJECT_COPYRIGHT
ARG PROJECT_LICENSE
ARG PROJECT_VERSION
ARG PROJECT_RELEASE_DATE

# -----------------------------------------------------------------------------
# 基础配置 (11个)
# -----------------------------------------------------------------------------
ARG PRODUCT_NAME
ARG IMAGE_NAME
ARG CONTAINER_NAME
ARG DEV_USERNAME
ARG DEV_GROUP
ARG DEV_USER_PASSWORD
ARG DEV_USER_ROOT_PASSWORD
ARG DEV_UID
ARG DEV_GID
ARG TIMEZONE
ARG DEBIAN_FRONTEND

# -----------------------------------------------------------------------------
# 构建配置 (1个)
# -----------------------------------------------------------------------------
ARG DOCKER_BUILDKIT

# -----------------------------------------------------------------------------
# 开发工具配置 (7个)
# -----------------------------------------------------------------------------
ARG INSTALL_CUDA
ARG INSTALL_OPENCV
ARG INSTALL_HOST_CMAKE
ARG INSTALL_MAN_DOC
ARG INSTALL_TOOLCHAIN
ARG INSTALL_DISTCC
ARG NPM_USE_CHINA_MIRROR

# -----------------------------------------------------------------------------
# 工作区配置 (16个)
# -----------------------------------------------------------------------------
ARG WORKSPACE_ROOT
ARG WORKSPACE_1ST_SOURCE_SUBDIR
ARG WORKSPACE_2ND_BUILD_SUBDIR
ARG WORKSPACE_3RD_LOGS_SUBDIR
ARG WORKSPACE_4TH_TEMP_SUBDIR
ARG WORKSPACE_5TH_DOCS_SUBDIR
ARG WORKSPACE_6TH_TOOLS_SUBDIR
ARG WORKSPACE_DEFAULT_PROJECT_NAME
ARG WORKSPACE_DEFAULT_BUILD_TYPE
ARG WORKSPACE_BUILD_THREADS
ARG WORKSPACE_ENABLE_AUTO_SAVE
ARG WORKSPACE_ENABLE_ERROR_REPORTING
ARG WORKSPACE_LOG_LEVEL
ARG WORKSPACE_ENABLE_VSC_INTEGRATION
ARG WORKSPACE_ENABLE_REMOTE_DEBUG
ARG WORKSPACE_DEBUG_PORT

# -----------------------------------------------------------------------------
# 注册表配置 (3个)
# -----------------------------------------------------------------------------
ARG UBUNTU_SERVER_IP
ARG UBUNTU_SERVER_PORT
ARG REGISTRY_URL

# -----------------------------------------------------------------------------
# SDK配置 (4个)
# -----------------------------------------------------------------------------
ARG SDK_INSTALL_PATH
ARG SDK_GIT_REPO
ARG SDK_GIT_KEY_FILE
ARG SDK_GIT_DEFAULT_BRANCH

# -----------------------------------------------------------------------------
# Docker卷配置 (1个)
# -----------------------------------------------------------------------------
ARG VOLUMES_ROOT

# -----------------------------------------------------------------------------
# Samba配置 (5个)
# -----------------------------------------------------------------------------
ARG SAMBA_PUBLIC_ACCOUNT_NAME
ARG SAMBA_PUBLIC_ACCOUNT_PASSWORD
ARG SAMBA_PRIVATE_ACCOUNT_NAME
ARG SAMBA_PRIVATE_ACCOUNT_PASSWORD
ARG ENABLE_VSC_INTEGRATION

# -----------------------------------------------------------------------------
# 容器运行时配置 (8个)
# -----------------------------------------------------------------------------
ARG ENABLE_SSH
ARG CLIENT_SSH_PORT
ARG SERVER_SSH_PORT
ARG ENABLE_SYSLOG
ARG ENABLE_GDB_SERVER
ARG GDB_PORT
ARG ENABLE_CORE_DUMPS
ARG CORE_PATTERN

# -----------------------------------------------------------------------------
# 服务器端镜像和容器选项 (14个)
# -----------------------------------------------------------------------------
ARG ENABLE_SERVERSIDE
ARG DISTCC_GCC_11_ENABLE
ARG DISTCC_GCC_11_MAIN_PORT
ARG DISTCC_GCC_11_STATS_PORT
ARG DISTCC_GCC_10_ENABLE
ARG DISTCC_GCC_10_MAIN_PORT
ARG DISTCC_GCC_10_STATS_PORT
ARG DISTCC_LOG_LEVEL
ARG DISTCC_LOG_DIR
ARG TOOLCHAIN_TARBALL_NAME
ARG PYTHON_VERSION
ARG TOOLCHAIN_DIR
ARG SERVERSIDE_IMAGE_NAME
ARG SERVERSIDE_CONTAINER_NAME

# -----------------------------------------------------------------------------
# 工具版本配置 (8个)
# -----------------------------------------------------------------------------
ARG CONAN_VERSION
ARG CMAKE_FORMAT_VERSION
ARG PRE_COMMIT_VERSION
ARG CUDA_VERSION
ARG OPENCV_VERSION
ARG GCC_OFFLINE_PACKAGE
ARG GCC_OFFLINE_VERSION
ARG GCC_INSTALL_PATH

# # 环境变量设置 - 仅设置此阶段需要的变量
# ENV DEBIAN_FRONTEND=${DEBIAN_FRONTEND}
# ENV TIMEZONE=${TIMEZONE}
# ENV DEV_USERNAME=${DEV_USERNAME}
# ENV DEV_USER_PASSWORD=${DEV_USER_PASSWORD}
# ENV DEV_UID=${DEV_UID}
# ENV DEV_GID=${DEV_GID}
# ENV DEV_USER_ROOT_PASSWORD=${DEV_USER_ROOT_PASSWORD}

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


################################################################################
# Copy scripts and configs
################################################################################
COPY stage_2_tools/scripts/install_dev_tools.sh /tmp/
COPY stage_2_tools/scripts/install_cuda.sh /tmp/
COPY stage_2_tools/scripts/install_opencv.sh /tmp/
COPY stage_2_tools/scripts/install_distcc_switcher.sh /tmp/
# COPY stage_2_tools/configs/tool_versions.conf /tmp/
COPY stage_2_tools/scripts/gitlfs_tracker.sh /usr/local/bin/

# Copy offline packages if they exist
COPY stage_2_tools/offline_toolchain /tmp/offline_toolchain/

# 创建环境变量配置文件
RUN echo "# 自动生成的工具版本配置" > /tmp/tool_versions.conf && \
    echo "CONAN_VERSION=\"${CONAN_VERSION}\"" >> /tmp/tool_versions.conf && \
    echo "CMAKE_FORMAT_VERSION=\"${CMAKE_FORMAT_VERSION}\"" >> /tmp/tool_versions.conf && \
    echo "PRE_COMMIT_VERSION=\"${PRE_COMMIT_VERSION}\"" >> /tmp/tool_versions.conf && \
    echo "CUDA_VERSION=\"${CUDA_VERSION}\"" >> /tmp/tool_versions.conf && \
    echo "OPENCV_VERSION=\"${OPENCV_VERSION}\"" >> /tmp/tool_versions.conf && \
    echo "GCC_OFFLINE_PACKAGE=\"${GCC_OFFLINE_PACKAGE}\"" >> /tmp/tool_versions.conf && \
    echo "GCC_OFFLINE_VERSION=\"${GCC_OFFLINE_VERSION}\"" >> /tmp/tool_versions.conf && \
    echo "GCC_INSTALL_PATH=\"${GCC_INSTALL_PATH}\"" >> /tmp/tool_versions.conf

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
RUN rm -rf /tmp/offline_toolchain && \
    rm -f /tmp/install_*.sh && \
    rm -f /tmp/tool_versions.conf
