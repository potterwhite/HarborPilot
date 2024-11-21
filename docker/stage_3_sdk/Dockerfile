################################################################################
# File: docker/stage_3_sdk/Dockerfile
#
# Description: SDK installation stage Dockerfile
#              Installs and configures embedded development SDK
#
# Author: [Your Name]
# Created: 2024-03-21
# Last Modified: 2024-03-21
#
# Copyright (c) 2024 [Your Company/Name]
# License: MIT
################################################################################

FROM embedded-dev:stage2

# Build arguments
ARG SDK_VERSION
ARG SDK_INSTALL_PATH
ARG SDK_PACKAGE
ARG DEBIAN_FRONTEND=noninteractive

# Create SDK installation directory
RUN mkdir -p ${SDK_INSTALL_PATH}

# Copy SDK installation files and scripts
COPY offline_packages/ /tmp/offline_packages/
COPY scripts/install_sdk.sh /tmp/
COPY configs/sdk_config.conf /tmp/

# Install SDK
RUN ls -lha /tmp/offline_packages/ && \
    chmod +x /tmp/install_sdk.sh && \
    SDK_PACKAGE=${SDK_PACKAGE} /tmp/install_sdk.sh && \
    rm -rf /tmp/install_sdk.sh /tmp/sdk_config.conf

# Set SDK environment variables
ENV SDK_ROOT=${SDK_INSTALL_PATH}
ENV PATH=${SDK_INSTALL_PATH}/bin:$PATH