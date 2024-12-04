#!/bin/bash

################################################################################
# File: start_dev_env.sh
# Description: Development environment management script
################################################################################

# Get script directory and load environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "${SCRIPT_DIR}")"
if [ -f "${PARENT_DIR}/.env" ]; then
    source "${PARENT_DIR}/.env"
    # cat "${PARENT_DIR}/.env"
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
    cat << EOF > "${SCRIPT_DIR}/docker-compose.yaml"
services:
  dev-env:
    image: ${REGISTRY_URL}/${IMAGE_NAME}:latest
    container_name: ${CONTAINER_NAME}
    hostname: ${CONTAINER_NAME}
    user: "${DEV_USERNAME}"
    restart: unless-stopped
    privileged: true
    tty: true
    stdin_open: true

    volumes:
      - /dev:/dev
      - "${SCRIPT_DIR}/../volumes:${VOLUMES_ROOT}"

    ports:
      - "${SSH_PORT}:22"
      - "${GDB_PORT}:2345"

    environment:
      - TIMEZONE=${TIMEZONE}
      - DISPLAY=${DISPLAY}
      - WORKSPACE_ENABLE_REMOTE_DEBUG=${WORKSPACE_ENABLE_REMOTE_DEBUG}
      - WORKSPACE_LOG_LEVEL=${WORKSPACE_LOG_LEVEL}

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
        while true; do
            print_msg "Container is already running!"
            print_msg "Please choose an option (press Ctrl+C to cancel):" "${YELLOW}"
            print_msg "1. Enter the container" "${YELLOW}"
            print_msg "2. Restart container" "${YELLOW}"
            print_msg "3. Remove and recreate" "${YELLOW}"
            print_msg "(You can always enter container manually using: docker exec -it -u ${DEV_USERNAME} ${CONTAINER_NAME} bash)" "${GREEN}"

            # Wait for user input
            read -p "Enter your choice (1-3): " choice || exit 1  # Handle Ctrl+D (EOF)

            case $choice in
                1)
                    docker exec -it -u ${DEV_USERNAME} ${CONTAINER_NAME} bash
                    break
                    ;;
                2)
                    stop_dev_env
                    _start_container_without_prompt
                    print_msg "Enter container? [Y/n]: " "${YELLOW}"
                    read -r answer
                    if [[ ! "$answer" =~ ^[Nn]$ ]]; then
                        docker exec -it -u ${DEV_USERNAME} ${CONTAINER_NAME} bash
                    else
                        print_msg "You can always enter container manually using: " "${GREEN}"
                        print_msg "\t\tdocker exec -it -u ${DEV_USERNAME} ${CONTAINER_NAME} bash" "${YELLOW}"
                        print_msg "\nSee you next time!" "${GREEN}"
                    fi
                    break
                    ;;
                3)
                    remove_dev_env
                    _start_container_without_prompt
                    print_msg "Enter container? [Y/n]: " "${YELLOW}"
                    read -r answer
                    if [[ ! "$answer" =~ ^[Nn]$ ]]; then
                        docker exec -it -u ${DEV_USERNAME} ${CONTAINER_NAME} bash
                    else
                        print_msg "You can always enter container manually using: " "${GREEN}"
                        print_msg "\t\tdocker exec -it -u ${DEV_USERNAME} ${CONTAINER_NAME} bash" "${YELLOW}"
                        print_msg "\nSee you next time!" "${GREEN}"
                    fi
                    break
                    ;;
                *)
                    print_msg "Invalid choice! Please try again..." "${RED}"
                    sleep 1
                    clear
                    ;;
            esac
        done
        return 0
    fi

    _start_container_without_prompt
    print_msg "Enter container? [Y/n]: " "${YELLOW}"
    read -r answer
    if [[ ! "$answer" =~ ^[Nn]$ ]]; then
        docker exec -it -u ${DEV_USERNAME} ${CONTAINER_NAME} bash
    else
        print_msg "You can always enter container manually using: " "${GREEN}"
        print_msg "\t\tdocker exec -it -u ${DEV_USERNAME} ${CONTAINER_NAME} bash" "${YELLOW}"
        print_msg "\nSee you next time!" "${GREEN}"
    fi
}

# Helper function to start container without prompt
_start_container_without_prompt() {
    if ! container_exists; then
        print_msg "Creating new development environment..."
        generate_compose_config
        (cd "${SCRIPT_DIR}" && docker compose up -d)
    else
        print_msg "Starting existing container..."
        docker start ${CONTAINER_NAME}
    fi

    if [ $? -ne 0 ]; then
        print_msg "Failed to start development environment" "${RED}"
        return 1
    fi
    print_msg "Development environment is ready!"
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
        (cd "${SCRIPT_DIR}" && docker compose down)
        rm -f "${SCRIPT_DIR}/docker-compose.yaml"
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