#!/bin/bash

################################################################################
# File: docker/stage_1_base/scripts/setup_base.sh
#
# Description: Base system setup script for the development environment
#              Installs essential packages and configures basic system settings
#
# Author: [Your Name]
# Created: 2024-03-21
# Last Modified: 2024-03-21
#
# Copyright (c) 2024 [Your Company/Name]
# License: MIT
################################################################################

set -e

# Update system and install essential packages
apt-get update && apt-get upgrade -y
apt-get install -y \
    build-essential \
    curl \
    git \
    locales \
    sudo \
    vim \
    wget \
    tzdata \
    python3 \
    python3-pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Configure locale
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8

# Create non-root user
groupadd --gid $USER_GID $USERNAME
useradd --uid $USER_UID --gid $USER_GID -m $USERNAME
echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME
chmod 0440 /etc/sudoers.d/$USERNAME

# Set timezone
ln -fs /usr/share/zoneinfo/$TZ /etc/localtime
dpkg-reconfigure -f noninteractive tzdata
