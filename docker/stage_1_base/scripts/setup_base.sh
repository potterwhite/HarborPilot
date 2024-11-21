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
    openssh-server \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/run/sshd

sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Configure locale
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8

# Create non-root user
groupadd --gid $DEV_GID $DEV_USERNAME
useradd --uid $DEV_UID --gid $DEV_GID -m $DEV_USERNAME
echo $DEV_USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$DEV_USERNAME
chmod 0440 /etc/sudoers.d/$DEV_USERNAME

# Set timezone
ln -fs /usr/share/zoneinfo/$TIMEZONE /etc/localtime
dpkg-reconfigure -f noninteractive tzdata
