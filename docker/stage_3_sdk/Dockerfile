################################################################################
# File: docker/stage_3_sdk/Dockerfile
#
# Description: SDK installation stage Dockerfile
#              Installs and configures embedded development SDK
#
# Author: [Your Name]
# Created: 2024-11-21
# Last Modified: 2024-11-28
#
# Copyright (c) 2024 [Your Company/Name]
# License: MIT
################################################################################

ARG IMAGE_NAME=embedded-dev
FROM ${IMAGE_NAME}:stage2

# Build arguments
ARG DEBIAN_FRONTEND
ARG SDK_INSTALL_PATH
ARG SDK_GIT_REPO
ARG SDK_GIT_KEY_FILE
ARG SDK_GIT_HOST
ARG PROJECT_VERSION

# Configuration and installation scripts
COPY configs/sdk_config.conf /tmp/
COPY scripts/install_sdk.sh /tmp/
COPY scripts/compile_sdk.sh /tmp/

# Copy processed git operation scripts
COPY configs/*.sh /usr/local/bin/

# Git analysis script
COPY scripts/analyze_dir_structure.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/analyze_dir_structure.sh

# Verify the processed scripts
RUN cat /usr/local/bin/verify_ssh_key.sh && \
    echo "--------------------------------" && \
    cat /usr/local/bin/pull_sdk.sh && \
    echo "--------------------------------" && \
    cat /usr/local/bin/push_sdk.sh && \
    echo "--------------------------------" && \
    cat /usr/local/bin/version_of_dev_env.sh

# Install SDK
RUN /tmp/install_sdk.sh

# Clean up
RUN rm -rf /tmp/install_sdk.sh \
           /tmp/sdk_config.conf \
           /tmp/compile_sdk.sh \
           /tmp/offline_packages
