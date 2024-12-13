#!/bin/bash

# This script is auto-generated during docker build
# DO NOT EDIT MANUALLY

PROJECT_VERSION="0.5.7"

echo "Current Version of SDK Development Environment is: 0.5.7"

# Show SDK Version
SDK_VERSION="__SDK_VERSION__"
echo "Current SDK Version: ${SDK_VERSION}"

# Show Docker Login Status
echo -e "\nDocker Registry Login Status:"
if [ -f ~/.docker/config.json ]; then
    echo "Logged in to:"
    jq -r '.auths | keys[]' ~/.docker/config.json 2>/dev/null || echo "No registry login found"
else
    echo "Not logged in to any Docker registry"
fi