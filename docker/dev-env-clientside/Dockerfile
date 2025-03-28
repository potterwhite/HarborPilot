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

FROM ubuntu:22.04 AS Stage_1st_Base

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
