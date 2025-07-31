#!/bin/bash

################################################################################
# File: 2_1_start_dev_env.sh
# Description: Development environment management script
################################################################################

set -e
if [ "${V}" == "1" ];then
    set -x
fi

#############################################################################
#                1st group
#############################################################################
1_0_gen_environment_variables() {

    # 1st task: source .env to retrive all environments
    BUILD_SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
    BUILD_SCRIPT_DIR="$(dirname ${BUILD_SCRIPT_PATH})"
    ENV_PATH="${BUILD_SCRIPT_DIR}/../../.env"
    if [ -f ${ENV_PATH} ]; then
        source ${ENV_PATH}
        echo -e "Done source .env\n"
    else
        echo -e "\nNo ${ENV_PATH} exist, quit"
        exit 1
    fi

    # 2nd task: determine final image name for docker compose yaml
    if [ "${HAVE_HARBOR_SERVER}" == "TRUE" ];then
        FINAL_IMAGE_NAME="${REGISTRY_URL}/${IMAGE_NAME}:latest"
    else
        FINAL_IMAGE_NAME="${IMAGE_NAME}:latest"
    fi

    # Colors for output
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
}


1_1_check_docker_group() {
    if ! groups "$USER" | grep -q "docker"; then
        utils_print_msg "Current user is not in the docker group" "${RED}"
        utils_print_msg "Do you want to add current user to docker group? [Y/n]: " "${YELLOW}"
        read -r answer
        if [[ ! "$answer" =~ ^[Nn]$ ]]; then
            if sudo usermod -aG docker "$USER"; then
                utils_print_msg "Successfully added user to docker group" "${GREEN}"
                utils_print_msg "Do you want to apply changes now? [Y/n]: " "${YELLOW}"
                read -r apply
                if [[ ! "$apply" =~ ^[Nn]$ ]]; then
                    exec newgrp docker
                else
                    utils_print_msg "Please log out and log back in" "${YELLOW}"
                    utils_print_msg "Continue anyway? [y/N]: " "${YELLOW}"
                    read -r continue
                    if [[ ! "$continue" =~ ^[Yy]$ ]]; then
                        exit 1
                    fi
                fi
            fi
        fi
    fi
}

1_2_check_docker_login() {
    if [  "${HAVE_HARBOR_SERVER}" == "FALSE" ];then
        return 0;
    fi

    local registry="${REGISTRY_URL}"

    while true; do
        # if docker manifest inspect --insecure "${FINAL_IMAGE_NAME}" >/dev/null 2>&1; then
        #     utils_print_msg "Already logged in to registry ${registry}" "${GREEN}"
        #     return 0
        # fi

        #------------------------------------------------------------------------------
        # 尝试使用现有凭证登录，并捕获输出
        login_output=$(docker login "${registry}" 2>&1)
        login_status=$?

        # 检查输出中是否包含成功登录的标志
        if [ $login_status -eq 0 ] && echo "$login_output" | grep -q "Authenticating with existing credentials"; then
            utils_print_msg "Already logged in to registry ${registry}" "${GREEN}"
            return 0
        fi

        #------------------------------------------------------------------------------
        utils_print_msg "Need to login to registry ${registry}" "${YELLOW}"
        read -p "Enter username: " username
        read -s -p "Enter password: " password
        echo

        login_output=$(echo "$password" | docker login "${registry}" -u "${username}" --password-stdin 2>&1)
        login_status=$?

        if [ $login_status -eq 0 ]; then
            utils_print_msg "Successfully logged in to registry ${registry}" "${GREEN}"
            return 0
        else
            if echo "$login_output" | grep -q "unauthorized"; then
                utils_print_msg "Authentication failed" "${RED}"
            elif echo "$login_output" | grep -q "no such host"; then
                utils_print_msg "Registry host not found" "${RED}"
            elif echo "$login_output" | grep -q "connection refused"; then
                utils_print_msg "Registry not available" "${RED}"
            else
                utils_print_msg "Login failed:" "${RED}"
                echo "$login_output"
            fi
            sleep 1
        fi
    done
}

# 1_2_check_docker_login() {
#     # utils_print_msg "Do you want to login to a registry? [Y/n]: " "${YELLOW}"
#     # read -r need_login
#     # while [[ "$need_login" =~ ^[Nn]$ ]]; do
#     #     utils_print_msg "Skipping registry login. Using local image if available." "${GREEN}"
#     #     return 0
#     # done
#     if [  "${HAVE_HARBOR_SERVER}" == "FALSE" ];then
#         return 0;
#     fi

#     utils_print_msg "Enter registry URL (leave empty for default: ${REGISTRY_URL}): " "${YELLOW}"
#     read -r custom_registry
#     local registry="${custom_registry:-${REGISTRY_URL}}"
#     # local registry="${REGISTRY_URL}"

#     while true; do
#         # if docker manifest inspect --insecure "${FINAL_IMAGE_NAME}" >/dev/null 2>&1; then
#         #     utils_print_msg "Already logged in to registry ${registry}" "${GREEN}"
#         #     return 0
#         # fi

#         #------------------------------------------------------------------------------
#         # 尝试使用现有凭证登录，并捕获输出
#         login_output=$(docker login "${registry}" 2>&1)
#         login_status=$?

#         # 检查输出中是否包含成功登录的标志
#         if [ $login_status -eq 0 ] && echo "$login_output" | grep -q "Authenticating with existing credentials"; then
#             utils_print_msg "Already logged in to registry ${registry}" "${GREEN}"
#             return 0
#         fi

#         #------------------------------------------------------------------------------
#         utils_print_msg "Need to login to registry ${registry}" "${YELLOW}"
#         read -p "Enter username: " username
#         read -s -p "Enter password: " password
#         echo

#         login_output=$(echo "$password" | docker login "${registry}" -u "${username}" --password-stdin 2>&1)
#         login_status=$?

#         if [ $login_status -eq 0 ]; then
#             utils_print_msg "Successfully logged in to registry ${registry}" "${GREEN}"
#             return 0
#         else
#             if echo "$login_output" | grep -q "unauthorized"; then
#                 utils_print_msg "Authentication failed" "${RED}"
#             elif echo "$login_output" | grep -q "no such host"; then
#                 utils_print_msg "Registry host not found" "${RED}"
#             elif echo "$login_output" | grep -q "connection refused"; then
#                 utils_print_msg "Registry not available" "${RED}"
#             else
#                 utils_print_msg "Login failed:" "${RED}"
#                 echo "$login_output"
#             fi
#             sleep 1
#         fi
#     done
# }

#############################################################################
#                2nd group
#############################################################################
# Function to start development environment
2_1_start_dev_env() {
    if 3_4_container_running; then
        while true; do
            utils_print_msg "Container is already running!"
            utils_print_msg "Please choose an option (press Ctrl+C to cancel):" "${YELLOW}"
            utils_print_msg "1. Enter the container" "${YELLOW}"
            utils_print_msg "2. Restart container" "${YELLOW}"
            utils_print_msg "3. Remove(container & image) and recreate" "${YELLOW}"
            utils_print_msg "(You can always enter container manually using: docker exec -it -u ${DEV_USERNAME} ${CONTAINER_NAME} bash)" "${GREEN}"

            # Wait for user input
            read -p "Enter your choice (1-3): " choice || exit 1  # Handle Ctrl+D (EOF)

            case $choice in
                1)
                    docker exec -it -u ${DEV_USERNAME} ${CONTAINER_NAME} bash
                    break
                    ;;
                2)
                    2_2_stop_dev_env
                    3_1_start_container_without_prompt
                    utils_print_msg "Enter container? [Y/n]: " "${YELLOW}"
                    read -r answer
                    if [[ ! "$answer" =~ ^[Nn]$ ]]; then
                        docker exec -it -u ${DEV_USERNAME} ${CONTAINER_NAME} bash
                    else
                        utils_print_msg "You can always enter container manually using: " "${GREEN}"
                        utils_print_msg "\t\tdocker exec -it -u ${DEV_USERNAME} ${CONTAINER_NAME} bash" "${YELLOW}"
                        utils_print_msg "\nSee you next time!" "${GREEN}"
                    fi
                    break
                    ;;
                3)
                    2_3_1_remove_dev_env
                    2_3_2_remove_dev_env_image
                    2_4_retrieve_latest_image
                    3_1_start_container_without_prompt
                    utils_print_msg "Enter container? [Y/n]: " "${YELLOW}"
                    read -r answer
                    if [[ ! "$answer" =~ ^[Nn]$ ]]; then
                        docker exec -it -u ${DEV_USERNAME} ${CONTAINER_NAME} bash
                    else
                        utils_print_msg "You can always enter container manually using: " "${GREEN}"
                        utils_print_msg "\t\tdocker exec -it -u ${DEV_USERNAME} ${CONTAINER_NAME} bash" "${YELLOW}"
                        utils_print_msg "\nSee you next time!" "${GREEN}"
                    fi
                    break
                    ;;
                *)
                    utils_print_msg "Invalid choice! Please try again..." "${RED}"
                    sleep 1
                    clear
                    ;;
            esac
        done
        return 0
    fi

    if [ "${HAVE_HARBOR_SERVER}" == "FALSE" ]; then
        # 添加镜像检查
        if ! 3_5_image_exists; then
            utils_print_msg "Local image ${IMAGE_NAME}:latest not found" "${YELLOW}"
            utils_print_msg "You may need to login to a registry or ensure the image is available locally." "${YELLOW}"
            2_4_retrieve_latest_image
            if [ $? -ne 0 ]; then
                utils_print_msg "Failed to retrieve image. Exiting..." "${RED}"
                exit 1
            fi
        fi
    fi

    3_1_start_container_without_prompt
    utils_print_msg "Enter container? [Y/n]: " "${YELLOW}"
    read -r answer
    if [[ ! "$answer" =~ ^[Nn]$ ]]; then
        docker exec -it -u ${DEV_USERNAME} ${CONTAINER_NAME} bash
    else
        utils_print_msg "You can always enter container manually using: " "${GREEN}"
        utils_print_msg "\t\tdocker exec -it -u ${DEV_USERNAME} ${CONTAINER_NAME} bash" "${YELLOW}"
        utils_print_msg "\nSee you next time!" "${GREEN}"
    fi
}

# Function to stop development environment
2_2_stop_dev_env() {
    if 3_4_container_running; then
        utils_print_msg "Stopping development environment..."
        docker stop ${CONTAINER_NAME}
    else
        utils_print_msg "Container is not running" "${YELLOW}"
    fi
}

# Function to remove development environment
2_3_1_remove_dev_env() {
    # 1. 先处理容器
    if 3_6_container_exists "${CONTAINER_NAME}"; then
        utils_print_msg "Removing container..."
        if ! docker rm "${CONTAINER_NAME}" -f; then
            utils_print_msg "Failed to remove container" "${RED}"
            return 1
        fi
    fi
}

2_3_2_remove_dev_env_image() {
    # 2. 再处理镜像
    if 3_5_image_exists "${IMAGE_NAME}"; then
        utils_print_msg "Removing image..."
        if ! docker rmi "${FINAL_IMAGE_NAME}"; then
            utils_print_msg "Failed to remove image" "${RED}"
            return 1
        fi
    fi
}

# 2_4_retrieve_latest_image() {
#     # 3. 最后尝试拉取新镜像
#     utils_print_msg "Pulling latest image..."
#     if ! docker pull "${FINAL_IMAGE_NAME}"; then
#         utils_print_msg "Failed to pull new image" "${RED}"
#         return 1
#     fi
# }
2_4_retrieve_latest_image() {
    if 3_5_image_exists; then
        utils_print_msg "Local image ${FINAL_IMAGE_NAME} already exists" "${GREEN}"
        utils_print_msg "Do you want to pull the latest image anyway? [y/N]: " "${YELLOW}"
        read -r pull_anyway
        if [[ ! "$pull_anyway" =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi

    if [ "${HAVE_HARBOR_SERVER}" == "FALSE" ]; then
        utils_print_msg "\nYou do not have any registry server, so you cannot retrieve image online, please do restoration manually.\n" "${GREEN}"
        return 1
    else
        utils_print_msg "Pulling latest image from ${REGISTRY_URL}..." "${GREEN}"
        if ! docker pull "${FINAL_IMAGE_NAME}"; then
            utils_print_msg "Failed to pull new image" "${RED}"
            return 1
        fi
    fi
}

#############################################################################
#                3rd group
#############################################################################
# Helper function to start container without prompt
3_1_start_container_without_prompt() {
    if ! 3_6_container_exists; then
        utils_print_msg "Creating new development environment..."
        3_3_generate_compose_config
        (cd "${BUILD_SCRIPT_DIR}" && docker compose -p ${CONTAINER_NAME} up -d)
    else
        utils_print_msg "Starting existing container..."
        docker start ${CONTAINER_NAME}
    fi

    if [ $? -ne 0 ]; then
        utils_print_msg "Failed to start development environment" "${RED}"
        return 1
    fi
    utils_print_msg "Development environment is ready!"
}


# Function to show help
3_2_show_help() {
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


# Function to generate docker-compose configuration
3_3_generate_compose_config() {
    # fix volumes dir not shift dynamically problem
    # jul31.2025
    local VOLUMES_DIR="$(realpath "${BUILD_SCRIPT_DIR}/../volumes")"
    echo "VOLUMES_DIR=${VOLUMES_DIR}"

    cat << EOF > "${BUILD_SCRIPT_DIR}/docker-compose.yaml"
services:
  dev-env:
    image: ${FINAL_IMAGE_NAME}
    container_name: ${CONTAINER_NAME}
    hostname: ${CONTAINER_NAME}
    user: "${DEV_USERNAME}"
    restart: unless-stopped
    privileged: true
    tty: true
    stdin_open: true

    devices:
      - /dev/ttyUSB0:/dev/ttyUSB0

    volumes:
      - /dev/bus/usb:/dev/bus/usb
      - "${VOLUMES_DIR}:${VOLUMES_ROOT}"
      - samba_public:${WORKSPACE_5TH_DOCS_SUBDIR}/usar-samba-public

    ports:
      - "${CLIENT_SSH_PORT}:22"
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

volumes:
  samba_public:
    driver: local
    driver_opts:
      type: cifs
      device: "//${UBUNTU_SERVER_IP}/public"
      o: "username=${SAMBA_PUBLIC_ACCOUNT_NAME},password=${SAMBA_PUBLIC_ACCOUNT_PASSWORD},uid=${DEV_UID},gid=${DEV_GID},file_mode=0777,dir_mode=0777"
EOF
}
# # Function to generate docker-compose configuration
# 3_3_generate_compose_config() {
#     cat << EOF > "${BUILD_SCRIPT_DIR}/docker-compose.yaml"
# services:
#   dev-env:
#     image: ${FINAL_IMAGE_NAME}
#     container_name: ${CONTAINER_NAME}
#     hostname: ${CONTAINER_NAME}
#     user: "${DEV_USERNAME}"
#     restart: unless-stopped
#     privileged: true
#     tty: true
#     stdin_open: true

#     volumes:
#       - /dev/ttyUSB0:/dev/ttyUSB0
#       - /dev/bus/usb:/dev/bus/usb
#       - "${BUILD_SCRIPT_DIR}/../volumes:${VOLUMES_ROOT}"
#       - samba_public:${WORKSPACE_5TH_DOCS_SUBDIR}/usar-samba-public

#     ports:
#       - "${CLIENT_SSH_PORT}:22"
#       - "${GDB_PORT}:2345"

#     environment:
#       - TIMEZONE=${TIMEZONE}
#       - DISPLAY=${DISPLAY}
#       - WORKSPACE_ENABLE_REMOTE_DEBUG=${WORKSPACE_ENABLE_REMOTE_DEBUG}
#       - WORKSPACE_LOG_LEVEL=${WORKSPACE_LOG_LEVEL}

#     working_dir: ${WORKSPACE_ROOT}

#     networks:
#       - dev-net

# networks:
#   dev-net:
#     driver: bridge

# volumes:
#   samba_public:
#     driver: local
#     driver_opts:
#       type: cifs
#       device: "//${UBUNTU_SERVER_IP}/public"
#       o: "username=${SAMBA_PUBLIC_ACCOUNT_NAME},password=${SAMBA_PUBLIC_ACCOUNT_PASSWORD},uid=${DEV_UID},gid=${DEV_GID},file_mode=0777,dir_mode=0777"
# EOF
# }

# Function to check if container is running
3_4_container_running() {
    docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"
}

# 3_5_image_exists() {
#     docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^${FINAL_IMAGE_NAME}$"
# }
3_5_image_exists() {
    docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^${FINAL_IMAGE_NAME}$"
}

# Function to check if container exists
3_6_container_exists() {
    docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"
}


#############################################################################
#                utils
#############################################################################
#-------------------------------------------------------------------------------
# Unified prompt function with timeout and Ctrl+C/Esc handling
# Arguments:
#   $1 - Prompt message
#   $2 - Timeout in seconds
# Returns:
#   0 if user confirms, 1 if user denies or timeout occurs
#-------------------------------------------------------------------------------
utils_prompt_with_timeout() {
    local message="$1"
    local timeout="$2"

    echo -e "\n--------------------"
    echo -e "${message}"
    echo -e "--------------------"

    echo "Default: Yes (Press 'n' to skip, any other key to continue, Ctrl+C or Esc to cancel)"

    trap 'echo -e "\nSkipping..."; return 1' SIGINT

    for ((i=timeout; i>0; i--)); do
        echo -ne "\rStarting in $i seconds... "
        read -t 1 -n 1 input
        if [ $? -eq 0 ]; then
            echo -e "\n"
            if [[ "${input,,}" == "n" || "${input}" == $'\e' ]]; then
                return 1
            else
                return 0
            fi
        fi
    done

    echo -e "\nProceeding with default action..."
    return 0
}

# Function to print messages
utils_print_msg() {
    echo -e "${2:-$GREEN}$1${NC}"
}


#############################################################################
#                Main script logic
#############################################################################
main(){
    case "$1" in
        "start")
            1_0_gen_environment_variables
            1_1_check_docker_group
            1_2_check_docker_login
            2_1_start_dev_env
            ;;
        "stop")
            1_0_gen_environment_variables
            1_1_check_docker_group
            1_2_check_docker_login
            2_2_stop_dev_env
            ;;
        "restart")
            1_0_gen_environment_variables
            1_1_check_docker_group
            1_2_check_docker_login
            2_2_stop_dev_env
            2_1_start_dev_env
            ;;
        "recreate")
            1_0_gen_environment_variables
            1_1_check_docker_group
            1_2_check_docker_login
            2_3_1_remove_dev_env
            2_3_2_remove_dev_env_image
            2_4_retrieve_latest_image
            2_1_start_dev_env
            ;;
        "remove")
            1_0_gen_environment_variables
            1_1_check_docker_group
            1_2_check_docker_login
            2_3_1_remove_dev_env
            ;;
        "-h"|"--help"|"")
            1_0_gen_environment_variables
            3_2_show_help
            ;;
        *)
            1_0_gen_environment_variables
            utils_print_msg "Unknown command: $1" "${RED}"
            3_2_show_help
            exit 1
            ;;
    esac

}

main "$@"
