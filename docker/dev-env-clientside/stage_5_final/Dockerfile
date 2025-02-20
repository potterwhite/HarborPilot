################################################################################
# File: docker/stage_5_final/Dockerfile
#
# Description: Final stage Dockerfile for embedded development environment
#              Integrates all previous stages and finalizes the setup
#
# Author: ${PROJECT_MAINTAINER}
# Created: 2024-11-21
# Last Modified: 2024-11-21
#
# Copyright (c) 2024 ${PROJECT_COPYRIGHT}
# License: ${PROJECT_LICENSE}
################################################################################

ARG IMAGE_NAME=embedded-dev
FROM ${IMAGE_NAME}:stage4

# Build arguments
ARG BUILD_DATE
ARG VERSION
ARG PROJECT_MAINTAINER
ARG PROJECT_EMAIL
ARG PROJECT_COPYRIGHT
ARG PROJECT_LICENSE
ARG PROJECT_RELEASE_DATE
# User configuration arguments
ARG DEV_USERNAME
ARG DEV_UID
ARG DEV_GID
ARG DEV_GROUP

# Volumes configuration arguments
ARG VOLUMES_ROOT

# Workspace configuration arguments
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

# Runtime configuration arguments
ARG ENABLE_SSH
ARG CLIENT_SSH_PORT
ARG ENABLE_SYSLOG
ARG ENABLE_GDB_SERVER
ARG GDB_PORT
# ARG ENABLE_CORE_DUMPS
# ARG CORE_PATTERN
# ARG MAX_FILE_DESCRIPTORS
# ARG MAX_PROCESSES
# ARG MEMORY_LIMIT

# Labels
LABEL maintainer="${PROJECT_MAINTAINER} <${PROJECT_EMAIL}>"
LABEL build_date=$BUILD_DATE
LABEL version=$VERSION
LABEL copyright="${PROJECT_COPYRIGHT}"
LABEL license="${PROJECT_LICENSE}"
LABEL released_date="${PROJECT_RELEASE_DATE}"

# Copy configuration files
COPY configs/workspace.conf /etc/workspace.conf
COPY configs/entrypoint.conf /etc/entrypoint.conf

# # Verify config files
# RUN set -ex && \
#     echo "=== Content of /etc/entrypoint.conf ===" && \
#     cat /etc/entrypoint.conf && \
#     echo "=== Content of /etc/workspace.conf ===" && \
#     cat /etc/workspace.conf

# Copy scripts
COPY scripts/setup_workspace.sh /usr/local/bin/
COPY scripts/entrypoint.sh /usr/local/bin/

# Set execute permissions
RUN chmod +x /usr/local/bin/setup_workspace.sh \
    && chmod +x /usr/local/bin/entrypoint.sh

# Setup workspace and permissions
RUN set -ex && \
    /usr/local/bin/setup_workspace.sh

# # Convert ARGs to ENVs for runtime
# ENV DEV_USERNAME=${DEV_USERNAME} \
#     DEV_UID=${DEV_UID} \
#     DEV_GID=${DEV_GID} \
#     DEV_GROUP=${DEV_GROUP} \
#     VOLUMES_ROOT=${VOLUMES_ROOT} \
#     WORKSPACE_ROOT=${WORKSPACE_ROOT} \
#     WORKSPACE_1ST_SOURCE_SUBDIR=${WORKSPACE_1ST_SOURCE_SUBDIR} \
#     WORKSPACE_2ND_BUILD_SUBDIR=${WORKSPACE_2ND_BUILD_SUBDIR} \
#     WORKSPACE_3RD_LOGS_SUBDIR=${WORKSPACE_3RD_LOGS_SUBDIR} \
#     WORKSPACE_4TH_TEMP_SUBDIR=${WORKSPACE_4TH_TEMP_SUBDIR} \
#     WORKSPACE_DEFAULT_PROJECT_NAME=${WORKSPACE_DEFAULT_PROJECT_NAME} \
#     WORKSPACE_DEFAULT_BUILD_TYPE=${WORKSPACE_DEFAULT_BUILD_TYPE} \
#     WORKSPACE_BUILD_THREADS=${WORKSPACE_BUILD_THREADS} \
#     WORKSPACE_ENABLE_AUTO_SAVE=${WORKSPACE_ENABLE_AUTO_SAVE} \
#     WORKSPACE_ENABLE_ERROR_REPORTING=${WORKSPACE_ENABLE_ERROR_REPORTING} \
#     WORKSPACE_LOG_LEVEL=${WORKSPACE_LOG_LEVEL} \
#     WORKSPACE_ENABLE_VSC_INTEGRATION=${WORKSPACE_ENABLE_VSC_INTEGRATION} \
#     WORKSPACE_ENABLE_REMOTE_DEBUG=${WORKSPACE_ENABLE_REMOTE_DEBUG} \
#     WORKSPACE_DEBUG_PORT=${WORKSPACE_DEBUG_PORT} \
#     ENABLE_SSH=${ENABLE_SSH} \
#     CLIENT_SSH_PORT=${CLIENT_SSH_PORT} \
#     ENABLE_SYSLOG=${ENABLE_SYSLOG} \
#     ENABLE_GDB_SERVER=${ENABLE_GDB_SERVER} \
#     GDB_PORT=${GDB_PORT} \
#     ENABLE_CORE_DUMPS=${ENABLE_CORE_DUMPS} \
#     CORE_PATTERN=${CORE_PATTERN} \
#     MAX_FILE_DESCRIPTORS=${MAX_FILE_DESCRIPTORS} \
#     MAX_PROCESSES=${MAX_PROCESSES} \
#     MEMORY_LIMIT=${MEMORY_LIMIT}

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