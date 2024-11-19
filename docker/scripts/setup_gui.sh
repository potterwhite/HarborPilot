#!/bin/bash
set -e

# Install required dependencies first
apt-get update
apt-get install -y curl gnupg2

# Add VSCode repository
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list

# Update and install VSCode
apt-get update
apt-get install -y code

# Create VSCode config directory
mkdir -p /root/.vscode