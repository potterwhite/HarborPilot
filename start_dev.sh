#!/bin/bash

set -e

# Print start message
echo "Starting development environment setup..."

# Call build script
echo "Building development environment..."
if [ -f "./scripts/build.sh" ]; then
    ./scripts/build.sh
else
    echo "Error: build.sh not found!"
    exit 1
fi

# Call run script
echo "Starting container..."
if [ -f "./scripts/run.sh" ]; then
    ./scripts/run.sh
else
    echo "Error: run.sh not found!"
    exit 1
fi

# Print usage instructions
echo -e "\n=== Development Environment Ready ==="
echo "To enter the container:"
echo "  docker exec -it \${PROJECT_NAME:-embedded-dev} bash"
echo "For GUI support (optional):"
echo "  1. Install VcXsrv (Windows) or XQuartz (macOS)"
echo "  2. Start X server"
echo "=================================="