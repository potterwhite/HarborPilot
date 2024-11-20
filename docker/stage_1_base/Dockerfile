################################################################################
# File: docker/stage_1_base/Dockerfile
#
# Description: Base stage Dockerfile for embedded development environment
#              Sets up the fundamental Ubuntu system with essential packages
#
# Author: [Your Name]
# Created: 2024-03-21
# Last Modified: 2024-03-21
#
# Copyright (c) 2024 [Your Company/Name]
# License: MIT
################################################################################

FROM ubuntu:22.04

# Build arguments
ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=UTC
ARG USERNAME=developer
ARG USER_UID=1000
ARG USER_GID=1000

# Copy scripts
COPY scripts/setup_base.sh /tmp/

# First install certificates (首先安装证书)
RUN apt-get update && \
    apt-get install -y ca-certificates && \
    update-ca-certificates

# Then setup sources and continue (然后设置源并继续)
COPY configs/apt_sources.list /etc/apt/sources.list
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get update

# Execute base setup
RUN chmod +x /tmp/setup_base.sh && \
    /tmp/setup_base.sh && \
    rm -f /tmp/setup_base.sh
