
#!/bin/bash

################################################################################
# File: start_dev_env.sh
# Description: One-click development environment management script
################################################################################

# Configuration
IMAGE_NAME="embedded-dev"
IMAGE_TAG="stage5"
CONTAINER_NAME="embedded-dev"
DEV_USERNAME="developer"

# Default configuration (can be overridden by environment variables)
: "${WORKSPACE_ROOT:=/development}"
: "${SSH_PORT:=22}"
: "${GDB_PORT:=2345}"
: "${DEBUG_PORT:=3000}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to print messages
print_msg() {
    echo -e "${2:-$GREEN}$1${NC}"
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
version: '3.8'

services:
  dev-env:
    image: ${IMAGE_NAME}:${IMAGE_TAG}
    container_name: ${CONTAINER_NAME}
    hostname: ${CONTAINER_NAME}
    user: "${DEV_USERNAME}"
    restart: unless-stopped
    privileged: true

    volumes:
      - ./workspace/src:/home/${DEV_USERNAME}/workspace/src
      - ./workspace/build:/home/${DEV_USERNAME}/workspace/build
      - ./workspace/logs:/home/${DEV_USERNAME}/workspace/logs
      - ./workspace/temp:/home/${DEV_USERNAME}/workspace/temp
      - /dev:/dev
      - ~/.ssh:/home/${DEV_USERNAME}/.ssh:ro

    ports:
      - "${SSH_PORT}:22"
      - "${DEBUG_PORT}:3000"
      - "${GDB_PORT}:2345"

    environment:
      - TZ=UTC
      - DISPLAY=\${DISPLAY}
      - WORKSPACE_ENABLE_REMOTE_DEBUG=true
      - WORKSPACE_LOG_LEVEL=INFO

    devices:
      - "/dev/ttyUSB0:/dev/ttyUSB0"
      - "/dev/bus/usb:/dev/bus/usb"

    working_dir: /home/${DEV_USERNAME}/workspace

    networks:
      - dev-net

networks:
  dev-net:
    driver: bridge
EOF
}

# Function to create workspace directories
create_workspace() {
    mkdir -p workspace/{src,build,logs,temp}
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
        create_workspace
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
    "start"|"")
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
    *)
        print_msg "Usage: $0 [start|stop|restart|recreate|remove]" "${YELLOW}"
        exit 1
        ;;
esac