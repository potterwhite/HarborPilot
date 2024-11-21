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

FROM embedded-dev:stage4

# Build arguments
ARG BUILD_DATE
ARG VERSION
ARG PROJECT_MAINTAINER
ARG PROJECT_EMAIL
ARG PROJECT_COPYRIGHT
ARG PROJECT_LICENSE

# User configuration arguments
ARG DEV_USERNAME
ARG DEV_UID
ARG DEV_GID
ARG DEV_GROUP

# Volumes configuration arguments
ARG VOLUMES_ROOT

# Workspace configuration arguments
ARG WORKSPACE_ROOT
ARG WORKSPACE_SOURCE_DIR
ARG WORKSPACE_BUILD_DIR
ARG WORKSPACE_LOGS_DIR
ARG WORKSPACE_TEMP_DIR
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
ARG SSH_PORT
ARG ENABLE_SYSLOG
ARG ENABLE_GDB_SERVER
ARG GDB_PORT
ARG ENABLE_CORE_DUMPS
ARG CORE_PATTERN
ARG MAX_FILE_DESCRIPTORS
ARG MAX_PROCESSES
ARG MEMORY_LIMIT

# Labels
LABEL maintainer="${PROJECT_MAINTAINER} <${PROJECT_EMAIL}>"
LABEL build_date=$BUILD_DATE
LABEL version=$VERSION
LABEL copyright="${PROJECT_COPYRIGHT}"
LABEL license="${PROJECT_LICENSE}"

# Copy configuration files
COPY configs/workspace.conf /etc/workspace.conf
COPY configs/entrypoint.conf /etc/entrypoint.conf

# Verify config files
RUN set -ex && \
    echo "=== Content of /etc/entrypoint.conf ===" && \
    cat /etc/entrypoint.conf && \
    echo "=== Content of /etc/workspace.conf ===" && \
    cat /etc/workspace.conf

# Copy scripts
COPY scripts/setup_workspace.sh /usr/local/bin/
COPY scripts/setup_permissions.sh /usr/local/bin/
COPY scripts/entrypoint.sh /usr/local/bin/

# Set execute permissions
RUN chmod +x /usr/local/bin/setup_workspace.sh \
    && chmod +x /usr/local/bin/setup_permissions.sh \
    && chmod +x /usr/local/bin/entrypoint.sh

# Setup workspace and permissions
RUN set -ex && \
    /usr/local/bin/setup_workspace.sh && \
    /usr/local/bin/setup_permissions.sh

# Set working directory
WORKDIR ${WORKSPACE_ROOT}

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"]

# Convert ARGs to ENVs for runtime
ENV DEV_USERNAME=${DEV_USERNAME} \
    DEV_UID=${DEV_UID} \
    DEV_GID=${DEV_GID} \
    DEV_GROUP=${DEV_GROUP} \
    VOLUMES_ROOT=${VOLUMES_ROOT} \
    WORKSPACE_ROOT=${WORKSPACE_ROOT} \
    WORKSPACE_SOURCE_DIR=${WORKSPACE_SOURCE_DIR} \
    WORKSPACE_BUILD_DIR=${WORKSPACE_BUILD_DIR} \
    WORKSPACE_LOGS_DIR=${WORKSPACE_LOGS_DIR} \
    WORKSPACE_TEMP_DIR=${WORKSPACE_TEMP_DIR} \
    WORKSPACE_DEFAULT_PROJECT_NAME=${WORKSPACE_DEFAULT_PROJECT_NAME} \
    WORKSPACE_DEFAULT_BUILD_TYPE=${WORKSPACE_DEFAULT_BUILD_TYPE} \
    WORKSPACE_BUILD_THREADS=${WORKSPACE_BUILD_THREADS} \
    WORKSPACE_ENABLE_AUTO_SAVE=${WORKSPACE_ENABLE_AUTO_SAVE} \
    WORKSPACE_ENABLE_ERROR_REPORTING=${WORKSPACE_ENABLE_ERROR_REPORTING} \
    WORKSPACE_LOG_LEVEL=${WORKSPACE_LOG_LEVEL} \
    WORKSPACE_ENABLE_VSC_INTEGRATION=${WORKSPACE_ENABLE_VSC_INTEGRATION} \
    WORKSPACE_ENABLE_REMOTE_DEBUG=${WORKSPACE_ENABLE_REMOTE_DEBUG} \
    WORKSPACE_DEBUG_PORT=${WORKSPACE_DEBUG_PORT} \
    ENABLE_SSH=${ENABLE_SSH} \
    SSH_PORT=${SSH_PORT} \
    ENABLE_SYSLOG=${ENABLE_SYSLOG} \
    ENABLE_GDB_SERVER=${ENABLE_GDB_SERVER} \
    GDB_PORT=${GDB_PORT} \
    ENABLE_CORE_DUMPS=${ENABLE_CORE_DUMPS} \
    CORE_PATTERN=${CORE_PATTERN} \
    MAX_FILE_DESCRIPTORS=${MAX_FILE_DESCRIPTORS} \
    MAX_PROCESSES=${MAX_PROCESSES} \
    MEMORY_LIMIT=${MEMORY_LIMIT}