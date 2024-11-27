################################################################################
# File: docker/stage_3_sdk/Dockerfile
#
# Description: SDK installation stage Dockerfile
#              Installs and configures embedded development SDK
#
# Author: [Your Name]
# Created: 2024-11-21
# Last Modified: 2024-11-21
#
# Copyright (c) 2024 [Your Company/Name]
# License: MIT
################################################################################

ARG IMAGE_NAME=embedded-dev
FROM ${IMAGE_NAME}:stage2

# Build arguments
ARG SDK_VERSION
ARG SDK_INSTALL_PATH
ARG SDK_PACKAGE
ARG DEBIAN_FRONTEND

# Create SDK installation directory
RUN mkdir -p ${SDK_INSTALL_PATH}

# Copy SDK installation files and scripts
COPY offline_packages/${SDK_PACKAGE} /tmp/offline_packages/
COPY configs/sdk_config.conf /tmp/
COPY scripts/install_sdk.sh /tmp/
COPY scripts/analyze_dir_structure.sh /usr/local/bin/
COPY scripts/compile_sdk.sh /tmp/

# Install SDK
RUN ls -lha /tmp/offline_packages/ && \
    chmod +x /tmp/install_sdk.sh && \
    SDK_PACKAGE=${SDK_PACKAGE} /tmp/install_sdk.sh && \
    chmod +x /usr/local/bin/analyze_dir_structure.sh && \
    chmod +x /tmp/compile_sdk.sh && \
    # /tmp/compile_sdk.sh && \
    rm -rf /tmp/install_sdk.sh /tmp/sdk_config.conf \
            /tmp/compile_sdk.sh /tmp/offline_packages

# Set SDK environment variables
# ENV SDK_VERSION=${SDK_VERSION}
# ENV SDK_INSTALL_PATH=${SDK_INSTALL_PATH}
# ENV SDK_PACKAGE=${SDK_PACKAGE}
# ENV DEBIAN_FRONTEND=${DEBIAN_FRONTEND}
# ENV SDK_ROOT=${SDK_INSTALL_PATH}
# ENV PATH=${SDK_INSTALL_PATH}/bin:$PATH