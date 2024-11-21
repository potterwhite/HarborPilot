#!/bin/bash

################################################################################
# File: start_dev_env.sh
# Description: Development environment management script
################################################################################

# Get script directory and load environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/.env" ]; then
    source "${SCRIPT_DIR}/.env"
else
    echo "Error: .env file not found"
    exit 1
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to print messages
print_msg() {
    echo -e "${2:-$GREEN}$1${NC}"
}

# Function to show help
show_help() {
    cat << EOF
Usage: $0 [COMMAND]

Commands:
    start     Start development environment
    stop      Stop development environment
    restart   Restart development environment
    recreate  Remove and recreate development environment
    remove    Remove development environment
    -h, --help    Show this help message

Example:
    $0 start     # Start the development environment
EOF
}

# Function to check if container exists
container_exists() {
    docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"
}

# Function to check if container is running
container_running() {
    docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"
}

# Function to generate docker-compose configuration
generate_compose_config() {
    cat << EOF > docker-compose.yaml
services:
  dev-env:
    image: ${IMAGE_NAME}:${LATEST_IMAGE_TAG}
    container_name: ${CONTAINER_NAME}
    hostname: ${CONTAINER_NAME}
    user: "${DEV_USERNAME}"
    restart: unless-stopped
    privileged: true
    tty: true
    stdin_open: true

    volumes:
      - ./volumes:${VOLUMES_ROOT}

    ports:
      - "${SSH_PORT}:22"
      - "${GDB_PORT}:2345"

    environment:
      - TZ=${TIMEZONE}
      - DISPLAY=${DISPLAY}
      - WORKSPACE_ENABLE_REMOTE_DEBUG=${WORKSPACE_ENABLE_REMOTE_DEBUG}
      - WORKSPACE_LOG_LEVEL=${WORKSPACE_LOG_LEVEL}

    devices:
      - "/dev/ttyUSB0:/dev/ttyUSB0"
      - "/dev/bus/usb:/dev/bus/usb"

    working_dir: ${WORKSPACE_ROOT}

    networks:
      - dev-net

networks:
  dev-net:
    driver: bridge
EOF
}


# Function to start development environment
start_dev_env() {
    if container_running; then
        print_msg "Container is already running!"
        print_msg "You can:"
        print_msg "1. Enter the container:   docker exec -it -u ${DEV_USERNAME} ${CONTAINER_NAME} bash" "${YELLOW}"
        print_msg "2. Restart container:     $0 restart" "${YELLOW}"
        print_msg "3. Remove and recreate:   $0 recreate" "${YELLOW}"
        return 0
    fi

    if ! container_exists; then
        print_msg "Creating new development environment..."
        generate_compose_config
        docker compose up -d
    else
        print_msg "Starting existing container..."
        docker start ${CONTAINER_NAME}
    fi

    if [ $? -eq 0 ]; then
        print_msg "Development environment is ready!"
        print_msg "To enter the container: docker exec -it -u ${DEV_USERNAME} ${CONTAINER_NAME} bash" "${YELLOW}"
    else
        print_msg "Failed to start development environment" "${RED}"
        return 1
    fi
}

# Function to stop development environment
stop_dev_env() {
    if container_running; then
        print_msg "Stopping development environment..."
        docker stop ${CONTAINER_NAME}
    else
        print_msg "Container is not running" "${YELLOW}"
    fi
}

# Function to remove development environment
remove_dev_env() {
    if container_exists; then
        print_msg "Removing development environment..."
        docker compose down
        rm -f docker-compose.yaml
    else
        print_msg "Container does not exist" "${YELLOW}"
    fi
}

# Main script logic
case "$1" in
    "start")
        start_dev_env
        ;;
    "stop")
        stop_dev_env
        ;;
    "restart")
        stop_dev_env
        start_dev_env
        ;;
    "recreate")
        remove_dev_env
        start_dev_env
        ;;
    "remove")
        remove_dev_env
        ;;
    "-h"|"--help"|"")
        show_help
        ;;
    *)
        print_msg "Unknown command: $1" "${RED}"
        show_help
        exit 1
        ;;
esac