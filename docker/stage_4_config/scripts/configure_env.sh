################################################################################
# File: docker/stage_4_config/scripts/configure_env.sh
#
# Description: Environment configuration script
#              Sets up environment variables and user configurations
#
# Author: [Your Name]
# Created: 2024-11-21
# Last Modified: 2024-11-21
#
# Copyright (c) 2024 [Your Company/Name]
# License: MIT
################################################################################

#!/bin/bash
set -e

# Check if configuration file exists
if [ ! -f "/tmp/env_config.conf" ]; then
    echo "Error: Configuration file not found"
    exit 1
fi

# Copy and verify configuration
cp /tmp/env_config.conf /etc/profile.d/env_config.sh
chmod 644 /etc/profile.d/env_config.sh

# Source and verify configuration
if ! source /etc/profile.d/env_config.sh; then
    echo "Error: Failed to load configuration"
    exit 1
fi

echo "Environment configuration completed successfully"