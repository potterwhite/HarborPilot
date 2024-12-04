#!/bin/bash
################################################################################
# Script Name: install_sdk.sh
# Description: Initialize SDK directory and Git repository
# Author: @MrJamesLZA
# Date: 2024-11-28
################################################################################

set -e

# Check required variables
if [ -z "${SDK_INSTALL_PATH}" ] || [ -z "${SDK_GIT_REPO}" ]; then
    echo "Error: Required environment variables are not set"
    echo "Please ensure SDK_INSTALL_PATH and SDK_GIT_REPO are defined"
    exit 1
fi

echo "Creating SDK directory structure..."
mkdir -p ${SDK_INSTALL_PATH}

echo "Setting initial ownership..."
chown -R developer:developer ${SDK_INSTALL_PATH}

echo "Setting up Git repository..."
cd ${SDK_INSTALL_PATH}

# Switch to developer user for Git operations
echo "Switching to developer user for Git operations..."
su - developer -c "
    cd ${SDK_INSTALL_PATH} && \
    git config --global init.defaultBranch main && \
    git config --global --add safe.directory ${SDK_INSTALL_PATH} && \
    git lfs install && \
    git init
    if [ \$? -eq 0 ]; then
        echo 'Git repository initialized successfully'
        git remote add origin ${SDK_GIT_REPO}
        echo 'Git remote added: ${SDK_GIT_REPO}'
    else
        echo 'Failed to initialize Git repository'
        exit 1
    fi
"


# # Add to PATH using /etc/environment
# echo "Adding Linux Upgrade Tool to PATH..."
# CURRENT_PATH=$(grep '^PATH=' /etc/environment | cut -d'"' -f2)
# # echo "PATH=${GCC_INSTALL_PATH}/${GCC_DIR}/bin:\$PATH" >> /etc/environment
# echo "PATH=\"${CURRENT_PATH}:${SDK_INSTALL_PATH}/tools/linux/Linux_Upgrade_Tool/Linux_Upgrade_Tool\"" > /etc/environment
ln -s ${SDK_INSTALL_PATH}/tools/linux/Linux_Upgrade_Tool/Linux_Upgrade_Tool/upgrade_tool /usr/local/bin/upgrade_tool

# Verify installation
echo "Verifying installation..."
echo "SDK directory contents:"
ls -la ${SDK_INSTALL_PATH}

# Check remote repository only if .git directory exists
if [ -d "${SDK_INSTALL_PATH}/.git" ]; then
    echo "Git remote configuration:"
    cd ${SDK_INSTALL_PATH} && \
    git config --global --add safe.directory ${SDK_INSTALL_PATH} && \
    git remote -v
else
    echo "Warning: Git repository not properly initialized"
    exit 1
fi

echo "SDK installation completed successfully"
exit 0


