################################################################################
# File: docker/stage_1_base/Dockerfile
#
# Description: Base stage Dockerfile for embedded development environment
#              Sets up the fundamental Ubuntu system with essential packages
#
# Author: PotterWhite
# Created: 2024-11-21
# Last Modified: 2025-07-14
#
# Copyright (c) 2024 [Your Company/Name]
# License: MIT
################################################################################
ARG OS_VERSION=22.04

FROM ubuntu:${OS_VERSION} AS stage_1st_base

RUN echo -e "\n========= Stage 1st =========\n\n"

SHELL ["/bin/bash", "-c"]

# =============================================================================
# All build arguments definition - Defined in the first stage, inherited by all subsequent stages
# =============================================================================

# -----------------------------------------------------------------------------
# Project Information (6 arguments)
# -----------------------------------------------------------------------------
ARG PROJECT_MAINTAINER
ARG PROJECT_EMAIL
ARG PROJECT_COPYRIGHT
ARG PROJECT_LICENSE
ARG PROJECT_VERSION
ARG PROJECT_RELEASE_DATE

# -----------------------------------------------------------------------------
# Base Configuration (12 arguments)
# -----------------------------------------------------------------------------
ARG PRODUCT_NAME
ARG OS_DISTRIBUTION
ARG OS_VERSION
ARG IMAGE_NAME
ARG LATEST_IMAGE_TAG
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
# Build Configuration (1 argument)
# -----------------------------------------------------------------------------
ARG DOCKER_BUILDKIT
ARG BUILD_DATE

# -----------------------------------------------------------------------------
# Development Tools Configuration (10 arguments)
# -----------------------------------------------------------------------------
ARG INSTALL_CUDA
ARG INSTALL_OPENCV
ARG INSTALL_HOST_CMAKE
ARG INSTALL_MAN_DOC
ARG NPM_USE_CHINA_MIRROR
ARG CONAN_VERSION
ARG CMAKE_FORMAT_VERSION
ARG PRE_COMMIT_VERSION
ARG CUDA_VERSION
ARG OPENCV_VERSION

# -----------------------------------------------------------------------------
# Workspace Configuration (16 arguments)
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
# Registry Configuration (5 arguments)
# -----------------------------------------------------------------------------
ARG HAVE_GITLAB_SERVER
ARG GITLAB_SERVER_IP
ARG GITLAB_SERVER_PORT
ARG HARBOR_SERVER_IP
ARG HARBOR_SERVER_PORT
ARG HAVE_HARBOR_SERVER
ARG REGISTRY_URL

# -----------------------------------------------------------------------------
# SDK Configuration (6 arguments)
# -----------------------------------------------------------------------------
ARG INSTALL_SDK
ARG SDK_INSTALL_PATH
ARG CHIP_FAMILY
ARG SDK_GIT_REPO
ARG SDK_GIT_KEY_FILE
ARG SDK_GIT_DEFAULT_BRANCH

# -----------------------------------------------------------------------------
# Docker Volumes Configuration (1 argument)
# -----------------------------------------------------------------------------
ARG VOLUMES_ROOT

# -----------------------------------------------------------------------------
# Samba Configuration (5 arguments)
# -----------------------------------------------------------------------------
ARG SAMBA_PUBLIC_ACCOUNT_NAME
ARG SAMBA_PUBLIC_ACCOUNT_PASSWORD
ARG SAMBA_PRIVATE_ACCOUNT_NAME
ARG SAMBA_PRIVATE_ACCOUNT_PASSWORD
ARG ENABLE_VSC_INTEGRATION  # Moved here from a duplicate entry

# -----------------------------------------------------------------------------
# Container Runtime Configuration (9 arguments)
# -----------------------------------------------------------------------------
ARG ENABLE_SSH
ARG CLIENT_SSH_PORT
ARG ENABLE_SYSLOG
ARG ENABLE_GDB_SERVER
ARG GDB_PORT
ARG ENABLE_CORE_DUMPS
ARG CORE_PATTERN
ARG USE_NVIDIA_GPU

# -----------------------------------------------------------------------------
# Proxy Configuration
# -----------------------------------------------------------------------------
ARG HAS_PROXY
ARG HTTP_PROXY_IP
ARG HTTPS_PROXY_IP

# =============================================================================
# Persist ARG values as ENV so all subsequent stages can access them.
# Docker ARGs are scoped per-stage; ENV values propagate through all stages.
# Only non-sensitive variables are listed here.
# =============================================================================
ENV WORKSPACE_ROOT=${WORKSPACE_ROOT} \
    WORKSPACE_1ST_SOURCE_SUBDIR=${WORKSPACE_1ST_SOURCE_SUBDIR} \
    WORKSPACE_2ND_BUILD_SUBDIR=${WORKSPACE_2ND_BUILD_SUBDIR} \
    WORKSPACE_3RD_LOGS_SUBDIR=${WORKSPACE_3RD_LOGS_SUBDIR} \
    WORKSPACE_4TH_TEMP_SUBDIR=${WORKSPACE_4TH_TEMP_SUBDIR} \
    WORKSPACE_5TH_DOCS_SUBDIR=${WORKSPACE_5TH_DOCS_SUBDIR} \
    WORKSPACE_6TH_TOOLS_SUBDIR=${WORKSPACE_6TH_TOOLS_SUBDIR} \
    WORKSPACE_DEFAULT_PROJECT_NAME=${WORKSPACE_DEFAULT_PROJECT_NAME} \
    WORKSPACE_DEFAULT_BUILD_TYPE=${WORKSPACE_DEFAULT_BUILD_TYPE} \
    WORKSPACE_BUILD_THREADS=${WORKSPACE_BUILD_THREADS} \
    WORKSPACE_ENABLE_AUTO_SAVE=${WORKSPACE_ENABLE_AUTO_SAVE} \
    WORKSPACE_ENABLE_ERROR_REPORTING=${WORKSPACE_ENABLE_ERROR_REPORTING} \
    WORKSPACE_LOG_LEVEL=${WORKSPACE_LOG_LEVEL} \
    WORKSPACE_ENABLE_VSC_INTEGRATION=${WORKSPACE_ENABLE_VSC_INTEGRATION} \
    WORKSPACE_ENABLE_REMOTE_DEBUG=${WORKSPACE_ENABLE_REMOTE_DEBUG} \
    WORKSPACE_DEBUG_PORT=${WORKSPACE_DEBUG_PORT} \
    DEV_USERNAME=${DEV_USERNAME} \
    DEV_GROUP=${DEV_GROUP} \
    DEV_UID=${DEV_UID} \
    DEV_GID=${DEV_GID} \
    TIMEZONE=${TIMEZONE} \
    PRODUCT_NAME=${PRODUCT_NAME} \
    OS_VERSION=${OS_VERSION} \
    OS_DISTRIBUTION=${OS_DISTRIBUTION} \
    IMAGE_NAME=${IMAGE_NAME} \
    CONTAINER_NAME=${CONTAINER_NAME} \
    PROJECT_VERSION=${PROJECT_VERSION} \
    PROJECT_MAINTAINER=${PROJECT_MAINTAINER} \
    PROJECT_EMAIL=${PROJECT_EMAIL} \
    PROJECT_COPYRIGHT=${PROJECT_COPYRIGHT} \
    PROJECT_LICENSE=${PROJECT_LICENSE} \
    PROJECT_RELEASE_DATE=${PROJECT_RELEASE_DATE} \
    SDK_INSTALL_PATH=${SDK_INSTALL_PATH} \
    CHIP_FAMILY=${CHIP_FAMILY} \
    SDK_GIT_REPO=${SDK_GIT_REPO} \
    SDK_GIT_KEY_FILE=${SDK_GIT_KEY_FILE} \
    SDK_GIT_DEFAULT_BRANCH=${SDK_GIT_DEFAULT_BRANCH} \
    VOLUMES_ROOT=${VOLUMES_ROOT} \
    INSTALL_SDK=${INSTALL_SDK} \
    REGISTRY_URL=${REGISTRY_URL} \
    HARBOR_SERVER_IP=${HARBOR_SERVER_IP} \
    HARBOR_SERVER_PORT=${HARBOR_SERVER_PORT} \
    HAVE_HARBOR_SERVER=${HAVE_HARBOR_SERVER} \
    HAVE_GITLAB_SERVER=${HAVE_GITLAB_SERVER} \
    GITLAB_SERVER_IP=${GITLAB_SERVER_IP} \
    GITLAB_SERVER_PORT=${GITLAB_SERVER_PORT} \
    ENABLE_SSH=${ENABLE_SSH} \
    CLIENT_SSH_PORT=${CLIENT_SSH_PORT} \
    ENABLE_GDB_SERVER=${ENABLE_GDB_SERVER} \
    GDB_PORT=${GDB_PORT} \
    ENABLE_CORE_DUMPS=${ENABLE_CORE_DUMPS} \
    CORE_PATTERN=${CORE_PATTERN} \
    USE_NVIDIA_GPU=${USE_NVIDIA_GPU} \
    INSTALL_CUDA=${INSTALL_CUDA} \
    INSTALL_OPENCV=${INSTALL_OPENCV} \
    INSTALL_HOST_CMAKE=${INSTALL_HOST_CMAKE} \
    INSTALL_MAN_DOC=${INSTALL_MAN_DOC} \
    NPM_USE_CHINA_MIRROR=${NPM_USE_CHINA_MIRROR} \
    CONAN_VERSION=${CONAN_VERSION} \
    CMAKE_FORMAT_VERSION=${CMAKE_FORMAT_VERSION} \
    PRE_COMMIT_VERSION=${PRE_COMMIT_VERSION} \
    CUDA_VERSION=${CUDA_VERSION} \
    OPENCV_VERSION=${OPENCV_VERSION} \
    BUILD_DATE=${BUILD_DATE} \
    HAS_PROXY=${HAS_PROXY} \
    HTTP_PROXY_IP=${HTTP_PROXY_IP} \
    HTTPS_PROXY_IP=${HTTPS_PROXY_IP}

# Copy scripts
COPY stage_1_base/scripts/setup_base.sh /tmp/

# First install certificates and basic tools
RUN apt-get update && \
    apt-get install -y ca-certificates bash && \
    update-ca-certificates

# Then clean apt cache and re-update sources
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
# Author: PotterWhite
# Created: 2024-11-21
# Last Modified: 2024-11-21
#
# Copyright (c) 2024 [Your Company/Name]
# License: MIT
################################################################################

# Use stage 1 as base
FROM stage_1st_base AS stage_2nd_tools

RUN echo -e "\n========= Stage 2nd =========\n\n"

################################################################################
# Copy scripts and configs
################################################################################
COPY stage_2_tools/scripts/install_dev_tools.sh /tmp/
COPY stage_2_tools/scripts/install_cuda.sh /tmp/
COPY stage_2_tools/scripts/install_opencv.sh /tmp/
# COPY stage_2_tools/configs/tool_versions.conf /tmp/
COPY stage_2_tools/scripts/gitlfs_tracker.sh /usr/local/bin/

# Generate tool version configuration file
RUN echo "# Auto-generated tool version configuration" > /tmp/tool_versions.conf && \
    echo "CONAN_VERSION=\"${CONAN_VERSION}\"" >> /tmp/tool_versions.conf && \
    echo "CMAKE_FORMAT_VERSION=\"${CMAKE_FORMAT_VERSION}\"" >> /tmp/tool_versions.conf && \
    echo "PRE_COMMIT_VERSION=\"${PRE_COMMIT_VERSION}\"" >> /tmp/tool_versions.conf && \
    echo "CUDA_VERSION=\"${CUDA_VERSION}\"" >> /tmp/tool_versions.conf && \
    echo "OPENCV_VERSION=\"${OPENCV_VERSION}\"" >> /tmp/tool_versions.conf

################################################################################
# Install all tools if configured enabled
################################################################################
# Install CUDA if configured enabled
RUN if [ "${INSTALL_CUDA}" = "true" ]; then \
        echo -e "\n\n##########################################################\n(1/4)Installing CUDA...\n##########################################################\n\n"; \
        chmod +x /tmp/install_cuda.sh && \
        /tmp/install_cuda.sh; \
        echo -e "\n\n##########################################################\n(1/4)CUDA is installed, Done\n##########################################################\n\n"; \
    else \
        rm -f /tmp/install_cuda.sh; \
        echo -e "\n\n##########################################################\n(1/4)CUDA is not installed, Removed install_cuda.sh, Done\n##########################################################\n\n"; \
    fi

# Install dev tools BEFORE OpenCV so that cmake and other build essentials
# are available when install_opencv.sh runs its cmake build step
RUN echo -e "\n\n##########################################################\n(2/4)Installing dev tools...\n##########################################################\n\n"; \
    chmod +x /tmp/install_dev_tools.sh && \
    /tmp/install_dev_tools.sh && \
    echo -e "\n\n##########################################################\n(2/4)Dev Tools are installed, Done\n##########################################################\n\n";

# Install OpenCV if configured enabled (requires cmake from previous step)
RUN if [ "${INSTALL_OPENCV}" = "true" ]; then \
        echo -e "\n\n##########################################################\n(3/4)Installing OpenCV...\n##########################################################\n\n"; \
        chmod +x /tmp/install_opencv.sh && \
        /tmp/install_opencv.sh; \
        echo -e "\n\n##########################################################\n(3/4)OpenCV is installed, Done\n##########################################################\n\n"; \
    else \
        rm -f /tmp/install_opencv.sh; \
        echo -e "\n\n##########################################################\n(3/4)OpenCV is not installed, Removed install_opencv.sh, Done\n##########################################################\n\n"; \
    fi

# Install gitlfs tracker, a diy git lfs tracker to help git operations
RUN chmod +x /usr/local/bin/gitlfs_tracker.sh



################################################################################
# Clean up
################################################################################
RUN rm -f /tmp/install_*.sh && \
    rm -f /tmp/tool_versions.conf

RUN echo -e "\n========= Stage 2nd Complete =========\n\n"

################################################################################
# File: docker/stage_3_sdk/Dockerfile
#
# Description: SDK installation stage Dockerfile
#              Installs and configures embedded development SDK
#
# Author: PotterWhite
# Created: 2024-11-21
# Last Modified: 2024-11-28
#
# Copyright (c) 2024 [Your Company/Name]
# License: MIT
################################################################################

FROM stage_2nd_tools AS stage_3rd_template-processor

RUN echo -e "\n========= Stage 3rd =========\n\n"

COPY ./stage_3_sdk/configs/ /tmp/configs/
COPY ./stage_3_sdk/scripts/ /tmp/scripts/

WORKDIR /tmp

# Render all *_template files using envsubst (provided by gettext-base, already installed)
RUN for template in $(find /tmp/configs /tmp/scripts -name "*_template" 2>/dev/null); do \
        output_file="${template%_template}"; \
        echo "Processing $template -> $output_file"; \
        envsubst < "$template" > "$output_file"; \
        chmod +x "$output_file"; \
    done

FROM stage_3rd_template-processor AS stage_3rd_sdk

RUN find /tmp/

# Configuration and installation scripts
# COPY configs/sdk_config.conf /tmp/
# COPY scripts/install_sdk.sh /tmp/

# Copy processed git operation scripts
#COPY configs/*.sh /usr/local/bin/
COPY --from=stage_3rd_template-processor /tmp/configs/*.sh /usr/local/bin/
COPY --from=stage_3rd_template-processor /tmp/configs/*.conf /tmp/
COPY --from=stage_3rd_template-processor /tmp/scripts/install_sdk.sh /tmp/
COPY --from=stage_3rd_template-processor /tmp/scripts/analyze_dir_structure.sh /usr/local/bin/

# Git analysis script
RUN chmod +x /usr/local/bin/analyze_dir_structure.sh

# Verify the processed scripts
RUN echo -e "\n\n----------------1st----------------" && \
    ls -lha /usr/local/bin/verify_ssh_key.sh && \
    cat /usr/local/bin/verify_ssh_key.sh

RUN echo -e "\n\n----------------2nd----------------" && \
    ls -lha /usr/local/bin/pull_sdk.sh && \
    cat /usr/local/bin/pull_sdk.sh

RUN echo -e "\n\n----------------3rd----------------" && \
    ls -lha /usr/local/bin/push_sdk.sh && \
    cat /usr/local/bin/push_sdk.sh

RUN echo -e "\n\n----------------4th----------------" && \
    ls -lha /usr/local/bin/version_of_dev_env.sh && \
    cat /usr/local/bin/version_of_dev_env.sh

RUN echo -e "\n\n----------------5th----------------" && \
    ls -lha /tmp/sdk_config.conf && \
    cat /tmp/sdk_config.conf

RUN echo -e "\n\n----------------6th----------------" && \
    ls -lha /tmp/install_sdk.sh && \
    cat /tmp/install_sdk.sh

# Install SDK
# RUN /tmp/install_sdk.sh
RUN /tmp/install_sdk.sh

# Clean up
RUN rm -rf /tmp/*

RUN echo -e "\n========= Stage 3rd Complete =========\n\n"

################################################################################
# File: docker/stage_4_config/Dockerfile
#
# Description: Configuration stage Dockerfile
#              Configures environment variables and system settings
#
# Author: PotterWhite
# Created: 2024-11-21
# Last Modified: 2024-11-28
#
# Copyright (c) 2024 [Your Company/Name]
# License: MIT
################################################################################
FROM stage_3rd_sdk AS stage_4th_template-processor

RUN echo -e "\n========= Stage 4th =========\n\n"

RUN find /tmp/

COPY ./stage_4_config/configs/ /tmp/configs/
COPY ./stage_4_config/scripts/ /tmp/scripts/

RUN find /tmp/

WORKDIR /tmp
# Render all *_template files using envsubst
RUN for template in $(find /tmp/configs /tmp/scripts -name "*_template" 2>/dev/null); do \
        output_file="${template%_template}"; \
        echo "Processing $template -> $output_file"; \
        envsubst < "$template" > "$output_file"; \
        chmod +x "$output_file"; \
    done

FROM stage_4th_template-processor AS stage_4th_config

RUN find /tmp/

# Copy configuration scripts and templates
COPY --from=stage_4th_template-processor /tmp/scripts/configure_env.sh /tmp/
COPY --from=stage_4th_template-processor /tmp/configs/env_config.conf /tmp/

# Conditionally install proxy configuration based on HAS_PROXY flag.
# ARG must be re-declared in this stage to be accessible in RUN commands,
# even though it was already declared in stage_1st_base.
ARG HAS_PROXY
RUN if [ "${HAS_PROXY}" = "true" ]; then \
        cp /tmp/configs/proxy.sh /etc/profile.d/proxy.sh && \
        chmod 644 /etc/profile.d/proxy.sh && \
        echo "Proxy configuration installed (HAS_PROXY=true)."; \
    else \
        echo "Proxy configuration skipped (HAS_PROXY=${HAS_PROXY})."; \
    fi

# Configure environment
RUN chmod +x /tmp/configure_env.sh && \
    /tmp/configure_env.sh && \
    rm -f /tmp/configure_env.sh /tmp/env_config.conf.template && \
    # Update PATH in /etc/environment
    sed -i 's/^session    required     pam_env.so$/session    required     pam_env.so readenv=1/g' /etc/pam.d/login && \
    echo "source /etc/environment" >> /etc/bash.bashrc && \
    chmod 644 /etc/environment

# Clean up
RUN rm -rf /tmp/*

RUN echo -e "\n========= Stage 4th Complete =========\n\n"

################################################################################
# File: docker/stage_5_final/Dockerfile
#
# Description: Final stage Dockerfile for embedded development environment
#              Integrates all previous stages and finalizes the setup
#
# Author: PotterWhite
# Created: 2024-11-21
# Last Modified: 2024-11-28
#
# Copyright (c) 2024 [Your Company/Name]
# License: MIT
################################################################################

FROM stage_4th_config AS stage_5th_template-processor

RUN echo -e "\n========= Stage 5th =========\n\n"

COPY ./stage_5_final/configs/ /tmp/configs/
COPY ./stage_5_final/scripts/ /tmp/scripts/

WORKDIR /tmp
# Render all *_template files using envsubst
RUN for template in $(find /tmp/configs /tmp/scripts -name "*_template" 2>/dev/null); do \
        output_file="${template%_template}"; \
        echo "Processing $template -> $output_file"; \
        envsubst < "$template" > "$output_file"; \
        chmod +x "$output_file"; \
    done

FROM stage_5th_template-processor AS stage_5th_final

# Labels
LABEL maintainer="${PROJECT_MAINTAINER} <${PROJECT_EMAIL}>"
LABEL build_date=$BUILD_DATE
LABEL version="${PROJECT_VERSION}"
LABEL copyright="${PROJECT_COPYRIGHT}"
LABEL license="${PROJECT_LICENSE}"
LABEL released_date="${PROJECT_RELEASE_DATE}"

# Copy configuration files
COPY --from=stage_5th_template-processor /tmp/configs/workspace.conf /etc/workspace.conf
COPY --from=stage_5th_template-processor /tmp/configs/entrypoint.conf /etc/entrypoint.conf

# # Verify config files
# RUN set -ex && \
#     echo "=== Content of /etc/entrypoint.conf ===" && \
#     cat /etc/entrypoint.conf && \
#     echo "=== Content of /etc/workspace.conf ===" && \
#     cat /etc/workspace.conf

# Copy scripts
COPY --from=stage_5th_template-processor /tmp/scripts/setup_workspace.sh /usr/local/bin/
COPY --from=stage_5th_template-processor /tmp/scripts/entrypoint.sh /usr/local/bin/

# Set execute permissions
RUN chmod +x /usr/local/bin/setup_workspace.sh \
    && chmod +x /usr/local/bin/entrypoint.sh

# Setup workspace and permissions
RUN set -ex && \
    /usr/local/bin/setup_workspace.sh

# Set working directory
WORKDIR ${WORKSPACE_ROOT}

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"]


################################################################################
# 1. Ensure bash is installed and set as default shell
################################################################################

RUN chsh -s /bin/bash ${DEV_USERNAME}

# Set default shell for build commands
SHELL ["/bin/bash", "-c"]

# Clean up
RUN rm -rf /tmp/*

RUN echo -e "\n========= Stage 5th Complete =========\n\n"