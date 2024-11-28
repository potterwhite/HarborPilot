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

# Configuration and installation scripts
COPY configs/sdk_config.conf /tmp/
COPY scripts/install_sdk.sh /tmp/
COPY scripts/compile_sdk.sh /tmp/

# Git scripts templates
COPY configs/pull_sdk.sh_template /tmp/
COPY configs/push_sdk.sh_template /tmp/
COPY configs/verify_ssh_key.sh_template /tmp/

# Git analysis script
COPY scripts/analyze_dir_structure.sh /usr/local/bin/

# Process templates and install scripts
RUN sed -e "s|\${SDK_INSTALL_PATH}|${SDK_INSTALL_PATH}|g" \
        -e "s|\${SDK_GIT_REPO}|${SDK_GIT_REPO}|g" \
        -e "s|\${SDK_GIT_KEY_FILE}|${SDK_GIT_KEY_FILE}|g" \
        -e "s|\${SDK_GIT_HOST}|${SDK_GIT_HOST}|g" \
        /tmp/pull_sdk.sh_template > /usr/local/bin/pull_sdk.sh && \
    sed -e "s|\${SDK_INSTALL_PATH}|${SDK_INSTALL_PATH}|g" \
        -e "s|\${SDK_GIT_REPO}|${SDK_GIT_REPO}|g" \
        -e "s|\${SDK_GIT_KEY_FILE}|${SDK_GIT_KEY_FILE}|g" \
        -e "s|\${SDK_GIT_HOST}|${SDK_GIT_HOST}|g" \
        /tmp/push_sdk.sh_template > /usr/local/bin/push_sdk.sh && \
    sed -e "s|\${SDK_INSTALL_PATH}|${SDK_INSTALL_PATH}|g" \
        -e "s|\${SDK_GIT_REPO}|${SDK_GIT_REPO}|g" \
        -e "s|\${SDK_GIT_KEY_FILE}|${SDK_GIT_KEY_FILE}|g" \
        -e "s|\${SDK_GIT_HOST}|${SDK_GIT_HOST}|g" \
        /tmp/verify_ssh_key.sh_template > /usr/local/bin/verify_ssh_key.sh && \
    chmod +x /usr/local/bin/pull_sdk.sh && \
    chmod +x /usr/local/bin/push_sdk.sh && \
    chmod +x /usr/local/bin/verify_ssh_key.sh && \
    chmod +x /usr/local/bin/analyze_dir_structure.sh

RUN cat /usr/local/bin/verify_ssh_key.sh && \
    echo "--------------------------------" && \
    cat /usr/local/bin/pull_sdk.sh && \
    echo "--------------------------------" && \
    cat /usr/local/bin/push_sdk.sh


# Install SDK
RUN /tmp/install_sdk.sh

# Clean up
RUN rm -rf /tmp/install_sdk.sh \
           /tmp/sdk_config.conf \
           /tmp/compile_sdk.sh \
           /tmp/pull_sdk.sh_template \
           /tmp/push_sdk.sh_template \
           /tmp/verify_ssh_key.sh_template \
           /tmp/offline_packages
