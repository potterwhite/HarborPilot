#!/bin/bash

################################################################################
# File: docker/stage_1_base/scripts/setup_base.sh
#
# Description: Base system setup script for the development environment
#              Installs essential packages and configures basic system settings
#
# Author: [Your Name]
# Created: 2024-11-21
# Last Modified: 2024-11-21
#
# Copyright (c) 2024 [Your Company/Name]
# License: MIT
################################################################################

set -e

# Category 1: Essential System Utilities
# Including system management, time/locale handling, and basic tools
apt-get update && apt-get upgrade -y

# Install locales first to avoid locale-gen command not found
apt-get install -y locales

# Configure locale early
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8

# Install other essential packages
apt-get install -y \
    sudo \
    curl \
    wget \
    gnupg \
    gnupg2 \
    apt-transport-https \
    ca-certificates \
    software-properties-common \
    tzdata \
    net-tools \
    openssh-server \
    vim \
    pigz \
    locate \
    && mkdir -p /var/run/sshd

# Create non-root user
groupadd --gid $DEV_GID $DEV_USERNAME
useradd --uid $DEV_UID --gid $DEV_GID -m $DEV_USERNAME
echo $DEV_USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$DEV_USERNAME
chmod 0440 /etc/sudoers.d/$DEV_USERNAME

# Set timezone
ln -fs /usr/share/zoneinfo/$TIMEZONE /etc/localtime
dpkg-reconfigure -f noninteractive tzdata

# Cleanup
apt-get clean && rm -rf /var/lib/apt/lists/*
