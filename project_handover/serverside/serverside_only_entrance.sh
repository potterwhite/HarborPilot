#!/bin/bash

# #########################
# # Force to run as root
# #########################
# if [ "$EUID" -ne 0 ]; then
#     echo "Please run as root"
#     exec sudo "$0" "$@"  # 重新以sudo执行整个脚本
# fi

gen_environment_variables() {

    set -e

    BUILD_SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
    BUILD_SCRIPT_DIR="$(dirname ${BUILD_SCRIPT_PATH})"
    ENV_PATH="${BUILD_SCRIPT_DIR}/../.env"

    # echo -e "BUILD_SCRIPT_PATH=${BUILD_SCRIPT_PATH}\n"
    # echo -e "ENV_PATH=${ENV_PATH}\n"

    if [ -f ${ENV_PATH} ];then
        # cat ${ENV_PATH}
        source ${ENV_PATH}
        echo -e "Done source .env\n"
    else
        echo -e "\nNo ${ENV_PATH} exist, quit"
        exit 1
    fi

    # Colors for output
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
}

check_docker_group() {
    # 检查当前用户是否在docker组
    if ! groups "$USER" | grep -q "docker"; then
        print_msg "Current user is not in the docker group" "${RED}"
        print_msg "This may cause permission issues with docker commands" "${YELLOW}"
        print_msg "Do you want to add current user to docker group? [Y/n]: " "${YELLOW}"
        read -r answer
        if [[ ! "$answer" =~ ^[Nn]$ ]]; then
            if sudo usermod -aG docker "$USER"; then
                print_msg "Successfully added user to docker group" "${GREEN}"
                print_msg "Do you want to apply changes now?(You will need to exec current script again) [Y/n]: " "${YELLOW}"
                read -r apply
                if [[ ! "$apply" =~ ^[Nn]$ ]]; then
                    # 立即应用更改
                    exec newgrp docker  # 使用exec替换当前shell
                else
                    print_msg "Please log out and log back in for changes to take effect" "${YELLOW}"
                    print_msg "Continue anyway? [y/N]: " "${YELLOW}"
                    read -r continue
                    if [[ ! "$continue" =~ ^[Yy]$ ]]; then
                        exit 1
                    fi
                fi
            fi
        else
            print_msg "You may need to use 'sudo' for docker commands" "${YELLOW}"
            print_msg "Continue anyway? [y/N]: " "${YELLOW}"
            read -r continue
            if [[ ! "$continue" =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    fi
}

check_docker_login() {
    local registry="${REGISTRY_URL}"

    while true; do
        # 检查登录状态
        if docker manifest inspect --insecure "${REGISTRY_URL}/${SERVERSIDE_IMAGE_NAME}:latest" >/dev/null 2>&1; then
            print_msg "Already logged in to registry ${registry}" "${GREEN}"
            return 0
        fi

        print_msg "Need to login to registry ${registry}" "${YELLOW}"

        # 读取登录信息
        read -p "Enter username: " username
        read -s -p "Enter password: " password
        echo  # 添加换行

        ###################################
        # 尝试登录并捕获错误信息
        ###################################
        login_output=$(echo "$password" | docker login "${registry}" -u "${username}" --password-stdin 2>&1)
        login_status=$?

        if [ $login_status -eq 0 ]; then
            print_msg "Successfully logged in to registry ${registry}" "${GREEN}"
            return 0
        else
            # 处理已知的错误类型
            if echo "$login_output" | grep -q "unauthorized"; then
                print_msg "Authentication failed: Invalid username or password" "${RED}"
            elif echo "$login_output" | grep -q "no such host"; then
                print_msg "Connection failed: Registry host not found" "${RED}"
            elif echo "$login_output" | grep -q "connection refused"; then
                print_msg "Connection failed: Registry service not available" "${RED}"
            else
                # 未知错误，直接显示原始错误信息
                print_msg "Login failed with error:" "${RED}"
                echo "$login_output"
            fi
            sleep 1
        fi
    done
}

image_exists() {
    docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^${REGISTRY_URL}/${SERVERSIDE_IMAGE_NAME}:latest$"
}

# Function to check if container exists
container_exists() {
    docker ps -a --format '{{.Names}}' | grep -q "^${SERVERSIDE_CONTAINER_NAME}$"
}

# Function to check if container is running
container_running() {
    docker ps --format '{{.Names}}' | grep -q "^${SERVERSIDE_CONTAINER_NAME}$"
}

_create_and_enter_container() {
    docker run -d \
        --name "${SERVERSIDE_CONTAINER_NAME}" \
        --restart unless-stopped \
        -p ${DISTCC_PORT}:3632 \
        -v "${BUILD_SCRIPT_DIR}/volumes:${VOLUMES_ROOT}" \
        -v /etc/localtime:/etc/localtime:ro \
        -e TZ=${TIMEZONE} \
        "${REGISTRY_URL}/${SERVERSIDE_IMAGE_NAME}:latest"
}

# Function to print messages
print_msg() {
    echo -e "${2:-$GREEN}$1${NC}"
}

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


# Helper function to start container without prompt
_start_container_without_prompt() {
    if ! container_exists; then
        print_msg "Creating new development environment..."
        _create_and_enter_container
    else
        print_msg "Starting existing container..."
        docker start ${SERVERSIDE_CONTAINER_NAME}
    fi

    if [ $? -ne 0 ]; then
        print_msg "Failed to start development environment" "${RED}"
        return 1
    fi
    print_msg "Development environment is ready!"
}


# Function to start development environment
start_dev_env() {
    if container_running; then
        while true; do
            print_msg "Container is already running!"
            print_msg "Please choose an option (press Ctrl+C to cancel):" "${YELLOW}"
            print_msg "1. Enter the container" "${YELLOW}"
            print_msg "2. Restart container" "${YELLOW}"
            print_msg "3. Remove(container & image) and recreate" "${YELLOW}"
            print_msg "(You can always enter container manually using: docker exec -it ${SERVERSIDE_CONTAINER_NAME} bash)" "${GREEN}"

            # Wait for user input
            read -p "Enter your choice (1-3): " choice || exit 1  # Handle Ctrl+D (EOF)

            case $choice in
                1)
                    docker exec -it ${SERVERSIDE_CONTAINER_NAME} bash
                    break
                    ;;
                2)
                    stop_dev_env
                    _start_container_without_prompt
                    print_msg "Enter container? [Y/n]: " "${YELLOW}"
                    read -r answer
                    if [[ ! "$answer" =~ ^[Nn]$ ]]; then
                        docker exec -it ${SERVERSIDE_CONTAINER_NAME} bash
                    else
                        print_msg "You can always enter container manually using: " "${GREEN}"
                        print_msg "\t\tdocker exec -it ${SERVERSIDE_CONTAINER_NAME} bash" "${YELLOW}"
                        print_msg "\nSee you next time!" "${GREEN}"
                    fi
                    break
                    ;;
                3)
                    remove_dev_env
                    remove_dev_env_image
                    retrieve_latest_image
                    _start_container_without_prompt
                    print_msg "Enter container? [Y/n]: " "${YELLOW}"
                    read -r answer
                    if [[ ! "$answer" =~ ^[Nn]$ ]]; then
                        docker exec -it ${SERVERSIDE_CONTAINER_NAME} bash
                    else
                        print_msg "You can always enter container manually using: " "${GREEN}"
                        print_msg "\t\tdocker exec -it ${SERVERSIDE_CONTAINER_NAME} bash" "${YELLOW}"
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
        docker exec -it ${SERVERSIDE_CONTAINER_NAME} bash
    else
        print_msg "You can always enter container manually using: " "${GREEN}"
        print_msg "\t\tdocker exec -it ${SERVERSIDE_CONTAINER_NAME} bash" "${YELLOW}"
        print_msg "\nSee you next time!" "${GREEN}"
    fi
}

# Function to stop development environment
stop_dev_env() {
    if container_running; then
        print_msg "Stopping development environment..."
        docker stop  ${SERVERSIDE_CONTAINER_NAME}
    else
        print_msg "Container is not running" "${YELLOW}"
    fi
}


# Function to remove development environment
remove_dev_env() {
    # 1. 先处理容器
    if container_exists "${SERVERSIDE_CONTAINER_NAME}"; then
        print_msg "Removing server side container..."
        if ! docker rm "${SERVERSIDE_CONTAINER_NAME}" -f; then
            print_msg "Failed to remove container" "${RED}"
            return 1
        fi
    fi
}

remove_dev_env_image() {
    # 2. 再处理镜像
    if image_exists "${SERVERSIDE_IMAGE_NAME}"; then
        print_msg "Removing server side image..."
        if ! docker rmi "${REGISTRY_URL}/${SERVERSIDE_IMAGE_NAME}:latest"; then
            print_msg "Failed to remove image" "${RED}"
            return 1
        fi
    fi
}

retrieve_latest_image() {
    # 3. 最后尝试拉取新镜像
    print_msg "Pulling latest server side image..."
    if ! docker pull "${REGISTRY_URL}/${SERVERSIDE_IMAGE_NAME}:latest"; then
        print_msg "Failed to pull new image" "${RED}"
        return 1
    fi
}

case "$1" in
    "start")
        gen_environment_variables
        check_docker_group
        check_docker_login
        start_dev_env
        ;;
    "stop")
        gen_environment_variables
        check_docker_group
        check_docker_login
        stop_dev_env
        ;;
    "restart")
        gen_environment_variables
        check_docker_group
        check_docker_login
        stop_dev_env
        start_dev_env
        ;;
    "recreate")
        gen_environment_variables
        check_docker_group
        check_docker_login
        remove_dev_env
        remove_dev_env_image
        retrieve_latest_image
        start_dev_env
        ;;
    "remove")
        gen_environment_variables
        check_docker_group
        check_docker_login
        remove_dev_env
        ;;
    "-h"|"--help"|"")
        gen_environment_variables
        show_help
        ;;
    *)
        gen_environment_variables
        print_msg "Unknown command: $1" "${RED}"
        show_help
        exit 1
        ;;
esac