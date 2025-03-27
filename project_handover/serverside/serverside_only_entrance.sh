#!/bin/bash

# #########################
# # Force to run as root
# #########################
# if [ "$EUID" -ne 0 ]; then
#     echo "Please run as root"
#     exec sudo "$0" "$@"  # 重新以sudo执行整个脚本
# fi

#####################################################################################
# 1st group
#####################################################################################
func_1_1_setup_environment_variables() {

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

    TEMP_DOCKERCOMPOSE_FILENAME="DockerComposeOfServerSide"
}

func_1_2_check_docker_group() {
    # 检查当前用户是否在docker组
    if ! groups "$USER" | grep -q "docker"; then
        func_1_7_print_msg "Current user is not in the docker group" "${RED}"
        func_1_7_print_msg "This may cause permission issues with docker commands" "${YELLOW}"
        func_1_7_print_msg "Do you want to add current user to docker group? [Y/n]: " "${YELLOW}"
        read -r answer
        if [[ ! "$answer" =~ ^[Nn]$ ]]; then
            if sudo usermod -aG docker "$USER"; then
                func_1_7_print_msg "Successfully added user to docker group" "${GREEN}"
                func_1_7_print_msg "Do you want to apply changes now?(You will need to exec current script again) [Y/n]: " "${YELLOW}"
                read -r apply
                if [[ ! "$apply" =~ ^[Nn]$ ]]; then
                    # 立即应用更改
                    exec newgrp docker  # 使用exec替换当前shell
                else
                    func_1_7_print_msg "Please log out and log back in for changes to take effect" "${YELLOW}"
                    func_1_7_print_msg "Continue anyway? [y/N]: " "${YELLOW}"
                    read -r continue
                    if [[ ! "$continue" =~ ^[Yy]$ ]]; then
                        exit 1
                    fi
                fi
            fi
        else
            func_1_7_print_msg "You may need to use 'sudo' for docker commands" "${YELLOW}"
            func_1_7_print_msg "Continue anyway? [y/N]: " "${YELLOW}"
            read -r continue
            if [[ ! "$continue" =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    fi
}

func_1_3_check_docker_login() {
    local registry="${REGISTRY_URL}"

    while true; do
        # 检查登录状态
        if docker manifest inspect --insecure "${REGISTRY_URL}/${SERVERSIDE_IMAGE_NAME}:latest" >/dev/null 2>&1; then
            func_1_7_print_msg "Already logged in to registry ${registry}" "${GREEN}"
            return 0
        fi

        func_1_7_print_msg "Need to login to registry ${registry}" "${YELLOW}"

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
            func_1_7_print_msg "Successfully logged in to registry ${registry}" "${GREEN}"
            return 0
        else
            # 处理已知的错误类型
            if echo "$login_output" | grep -q "unauthorized"; then
                func_1_7_print_msg "Authentication failed: Invalid username or password" "${RED}"
            elif echo "$login_output" | grep -q "no such host"; then
                func_1_7_print_msg "Connection failed: Registry host not found" "${RED}"
            elif echo "$login_output" | grep -q "connection refused"; then
                func_1_7_print_msg "Connection failed: Registry service not available" "${RED}"
            else
                # 未知错误，直接显示原始错误信息
                func_1_7_print_msg "Login failed with error:" "${RED}"
                echo "$login_output"
            fi
            sleep 1
        fi
    done
}

func_1_4_image_exists() {
    docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^${REGISTRY_URL}/${SERVERSIDE_IMAGE_NAME}:latest$"
}

# Function to check if container exists
func_1_5_container_exists() {
    docker ps -a --format '{{.Names}}' | grep -q "^${SERVERSIDE_CONTAINER_NAME}$"
}

# Function to check if container is running
func_1_6_if_container_running() {
    docker ps --format '{{.Names}}' | grep -q "^${SERVERSIDE_CONTAINER_NAME}$"
}

# Function to print messages
func_1_7_print_msg() {
    echo -e "${2:-$GREEN}$1${NC}"
}

func_1_8_show_help() {
    cat << DELIM
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
DELIM
}

#####################################################################################
# 2nd group
#####################################################################################

# Function to start development environment
func_2_1_start_dev_env() {
    if func_1_6_if_container_running; then
        while true; do
            func_1_7_print_msg "Container is already running!"
            func_1_7_print_msg "Please choose an option (press Ctrl+C to cancel):" "${YELLOW}"
            func_1_7_print_msg "1. Enter the container" "${YELLOW}"
            func_1_7_print_msg "2. Restart container" "${YELLOW}"
            func_1_7_print_msg "3. Remove(container & image) and recreate" "${YELLOW}"
            func_1_7_print_msg "(You can always enter container manually using: docker exec -it ${SERVERSIDE_CONTAINER_NAME} bash)" "${GREEN}"

            # Wait for user input
            read -p "Enter your choice (1-3): " choice || exit 1  # Handle Ctrl+D (EOF)

            case $choice in
                1)
                    docker exec -it ${SERVERSIDE_CONTAINER_NAME} bash
                    break
                    ;;
                2)
                    func_2_2_stop_dev_env
                    _start_container_without_prompt
                    func_1_7_print_msg "Enter container? [Y/n]: " "${YELLOW}"
                    read -r answer
                    answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]' | xargs)
                    if [[ "$answer" == "y" || "$answer" == "yes" ]]; then
                        docker exec -it ${SERVERSIDE_CONTAINER_NAME} bash
                    else
                        func_1_7_print_msg "You can always enter container manually using: " "${GREEN}"
                        func_1_7_print_msg "\t\tdocker exec -it ${SERVERSIDE_CONTAINER_NAME} bash" "${YELLOW}"
                        func_1_7_print_msg "\nSee you next time!" "${GREEN}"
                    fi
                    break
                    ;;
                3)
                    func_2_3_remove_dev_env
                    func_2_3_1_remove_dev_env_image
                    func_2_4_retrieve_latest_image
                    _start_container_without_prompt
                    func_1_7_print_msg "Enter container? [Y/n]: " "${YELLOW}"
                    read -r answer
                    if [[ ! "$answer" =~ ^[Nn]$ ]]; then
                        docker exec -it ${SERVERSIDE_CONTAINER_NAME} bash
                    else
                        func_1_7_print_msg "You can always enter container manually using: " "${GREEN}"
                        func_1_7_print_msg "\t\tdocker exec -it ${SERVERSIDE_CONTAINER_NAME} bash" "${YELLOW}"
                        func_1_7_print_msg "\nSee you next time!" "${GREEN}"
                    fi
                    break
                    ;;
                *)
                    func_1_7_print_msg "Invalid choice! Please try again..." "${RED}"
                    sleep 1
                    clear
                    ;;
            esac
        done
        return 0
    fi

    _start_container_without_prompt
    func_1_7_print_msg "Enter container? [Y/n]: " "${YELLOW}"
    read -r answer
    if [[ ! "$answer" =~ ^[Nn]$ ]]; then
        docker exec -it ${SERVERSIDE_CONTAINER_NAME} bash
    else
        func_1_7_print_msg "You can always enter container manually using: " "${GREEN}"
        func_1_7_print_msg "\t\tdocker exec -it ${SERVERSIDE_CONTAINER_NAME} bash" "${YELLOW}"
        func_1_7_print_msg "\nSee you next time!" "${GREEN}"
    fi
}

# Function to stop development environment
func_2_2_stop_dev_env() {
    if func_1_6_if_container_running; then
        func_1_7_print_msg "Stopping development environment..."
        docker stop  ${SERVERSIDE_CONTAINER_NAME}
    else
        func_1_7_print_msg "Container is not running" "${YELLOW}"
    fi
}

# Function to remove development environment
func_2_3_remove_dev_env() {
    # 1. 先处理容器
    if func_1_5_container_exists "${SERVERSIDE_CONTAINER_NAME}"; then
        func_1_7_print_msg "Removing server side container..."
        if ! docker rm "${SERVERSIDE_CONTAINER_NAME}" -f; then
            func_1_7_print_msg "Failed to remove container" "${RED}"
            return 1
        fi
    fi
}

func_2_3_1_remove_dev_env_image() {
    # 2. 再处理镜像
    if func_1_4_image_exists "${SERVERSIDE_IMAGE_NAME}"; then
        func_1_7_print_msg "Removing server side image..."
        if ! docker rmi "${REGISTRY_URL}/${SERVERSIDE_IMAGE_NAME}:latest"; then
            func_1_7_print_msg "Failed to remove image" "${RED}"
            return 1
        fi
    fi
}

func_2_4_retrieve_latest_image() {
    # 3. 最后尝试拉取新镜像
    func_1_7_print_msg "Pulling latest server side image..."
    if ! docker pull "${REGISTRY_URL}/${SERVERSIDE_IMAGE_NAME}:latest"; then
        func_1_7_print_msg "Failed to pull new image" "${RED}"
        return 1
    fi
}

#####################################################################################
# 3rd group
#####################################################################################
func_3_2_generate_compose_file() {
    # 生成 docker-compose.yml
    cat > "${BUILD_SCRIPT_DIR}/${TEMP_DOCKERCOMPOSE_FILENAME}" << DELIM
services:
  dev-env-serverside:
    image: ${REGISTRY_URL}/${SERVERSIDE_IMAGE_NAME}:latest
    container_name: ${SERVERSIDE_CONTAINER_NAME}
    hostname: ${SERVERSIDE_CONTAINER_NAME}
    restart: unless-stopped
    ports:
      - ${SERVER_SSH_PORT}:22
      - 3632:3632
DELIM

    if [ "${ENABLE_SSH}" == "true" ]; then
        # 根据条件添加端口映射
        if [ "${DISTCC_GCC_10_ENABLE}" == "true" ]; then
            echo "      - ${DISTCC_GCC_10_MAIN_PORT}:${DISTCC_GCC_10_MAIN_PORT}" >> "${BUILD_SCRIPT_DIR}/${TEMP_DOCKERCOMPOSE_FILENAME}"
            echo "      - ${DISTCC_GCC_10_STATS_PORT}:${DISTCC_GCC_10_STATS_PORT}" >> "${BUILD_SCRIPT_DIR}/${TEMP_DOCKERCOMPOSE_FILENAME}"
        fi

        if [ "${DISTCC_GCC_11_ENABLE}" == "true" ]; then
            echo "      - ${DISTCC_GCC_11_MAIN_PORT}:${DISTCC_GCC_11_MAIN_PORT}" >> "${BUILD_SCRIPT_DIR}/${TEMP_DOCKERCOMPOSE_FILENAME}"
            echo "      - ${DISTCC_GCC_11_STATS_PORT}:${DISTCC_GCC_11_STATS_PORT}" >> "${BUILD_SCRIPT_DIR}/${TEMP_DOCKERCOMPOSE_FILENAME}"
        fi
    fi # ENABLE_SSH

    # 继续生成其余配置
    cat >> "${BUILD_SCRIPT_DIR}/${TEMP_DOCKERCOMPOSE_FILENAME}" << DELIM
    volumes:
      - ./volumes:${VOLUMES_ROOT}
      - /etc/localtime:/etc/localtime:ro
    environment:
      - TZ=${TIMEZONE}
      - ROOT_PASSWORD=${DEV_USER_ROOT_PASSWORD}
DELIM

    # 启动容器
    if ! docker compose -f "${BUILD_SCRIPT_DIR}/${TEMP_DOCKERCOMPOSE_FILENAME}" up -d; then
        func_1_7_print_msg "Failed to create container" "${RED}"
        return 1
    fi

    func_1_7_print_msg "Container created successfully" "${GREEN}"
    return 0
}

# Helper function to start container without prompt
_start_container_without_prompt() {
    if ! func_1_5_container_exists; then
        func_1_7_print_msg "Creating new development environment..."
        func_3_2_generate_compose_file
    else
        func_1_7_print_msg "Starting existing container..."
        docker start ${SERVERSIDE_CONTAINER_NAME}
    fi

    if [ $? -ne 0 ]; then
        func_1_7_print_msg "Failed to start development environment" "${RED}"
        return 1
    fi
    func_1_7_print_msg "Development environment is ready!"
}

#####################################################################################
# 4th group: main entrance
#####################################################################################
main() {
    case "$1" in
        "start")
            func_1_1_setup_environment_variables
            func_1_2_check_docker_group
            func_1_3_check_docker_login
            func_2_1_start_dev_env
            ;;
        "stop")
            func_1_1_setup_environment_variables
            func_1_2_check_docker_group
            func_1_3_check_docker_login
            func_2_2_stop_dev_env
            ;;
        "restart")
            func_1_1_setup_environment_variables
            func_1_2_check_docker_group
            func_1_3_check_docker_login
            func_2_2_stop_dev_env
            func_2_1_start_dev_env
            ;;
        "recreate")
            func_1_1_setup_environment_variables
            func_1_2_check_docker_group
            func_1_3_check_docker_login
            func_2_3_remove_dev_env
            func_2_3_1_remove_dev_env_image
            func_2_4_retrieve_latest_image
            func_2_1_start_dev_env
            ;;
        "remove")
            func_1_1_setup_environment_variables
            func_1_2_check_docker_group
            func_1_3_check_docker_login
            func_2_3_remove_dev_env
            ;;
        "-h"|"--help"|"")
            func_1_1_setup_environment_variables
            func_1_8_show_help
            ;;
        *)
            func_1_1_setup_environment_variables
            func_1_7_print_msg "Unknown command: $1" "${RED}"
            func_1_8_show_help
            exit 1
            ;;
    esac
}

main "$@"