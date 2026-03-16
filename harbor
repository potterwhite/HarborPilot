#!/bin/bash
################################################################################
# Script Name: temp_test.sh
# Description: Build multi-stage Docker image and push to registry
# Usage: ./build-dev-env.sh
#
# Author: @PotterWhite
# created date: 2024-11-28
# last modified: 2025-06-29
################################################################################

# set -e
if [ "${V}" == "1" ]; then
    set -x
fi

################################################################################
# Main function to orchestrate the entire build process
################################################################################
main() {
    SECONDS=0
    echo "Build process started at: "
    echo "###################################"
    echo "#   $(LC_ALL=C date +%a\ %b%d.%Y\ %H:%M:%S)"
    echo "###################################"

    BUILD_SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
    # echo "BUILD_SCRIPT_PATH=${BUILD_SCRIPT_PATH}"
    BUILD_SCRIPT_DIR="$(dirname ${BUILD_SCRIPT_PATH})"
    # echo "BUILD_SCRIPT_DIR=${BUILD_SCRIPT_DIR}"
    TOP_ROOT_DIR="${BUILD_SCRIPT_DIR}"
    TOP_CONFIGS_DIR="${TOP_ROOT_DIR}/configs"
    HANDOVER_DIR="${TOP_ROOT_DIR}/project_handover"
    # src env means they are the original files
    PLATFORM_ENV_SRC_DIR="${TOP_CONFIGS_DIR}/platforms"
    # PLATFORM_ENV_SRC_PATH="${PLATFORM_ENV_SRC_DIR}/.env"
    PLATFORM_INDEPENDENT_ENV_SRC_DIR="${TOP_CONFIGS_DIR}/platform-independent"
    PLATFORM_INDEPENDENT_ENV_SRC_PATH="${PLATFORM_INDEPENDENT_ENV_SRC_DIR}/common.env"
    # dest env means destination files, which are used for
    PLATFORM_ENV_DEST_PATH="${HANDOVER_DIR}/.env"
    PLATFORM_INDEPENDENT_ENV_DEST_PATH="${HANDOVER_DIR}/.env-independent"
    ##################################################################
    while true; do
        1_specify_platform
        if [ $? -eq 0 ]; then
            break
        fi
    done

    source ${PLATFORM_INDEPENDENT_ENV_DEST_PATH}
    echo "Loading environment variables from ${PLATFORM_INDEPENDENT_ENV_DEST_PATH}"

    source ${PLATFORM_ENV_DEST_PATH}
    echo "Loading environment variables from ${PLATFORM_ENV_DEST_PATH}"

    1_1_setup_volume_soft_link || exit 1

    2_build_images || exit 1

    3_prepare_version_info || exit 1

    4_tag_images || exit 1

    5_push_images || exit 1

    6_cleanup_images || exit 1

    local duration=$SECONDS
    echo -e "\n=== Build Process Completed Successfully ==="
    echo "Total execution time: $((duration / 3600))h $((duration % 3600 / 60))m $((duration % 60))s"
}

################################################################################
# Unified prompt function with timeout and Ctrl+C/Esc handling
# Arguments:
#   $1 - Prompt message
#   $2 - Timeout in seconds
# Returns:
#   0 if user confirms, 1 if user denies or timeout occurs
################################################################################
prompt_with_timeout() {
    local message="$1"
    local timeout="$2"

    echo -e "\n--------------------"
    echo -e "${message}"
    echo -e "--------------------"

    echo "Default: Yes (Press 'n' to skip, any other key to continue, Ctrl+C or Esc to cancel)"

    trap 'echo -e "\nSkipping..."; return 1' SIGINT

    for ((i = timeout; i > 0; i--)); do
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

1_specify_platform() {
    TARGET_DIR="${PLATFORM_ENV_SRC_DIR}"
    declare -a platforms_array=()

    while IFS= read -r -d '' file_path; do
        filename="$(basename ${file_path})"
        basename="${filename%.env}"

        if [ -n ${basename} ]; then
            platforms_array+=(${basename})
        fi

    done < <(find ${TARGET_DIR} -maxdepth 1 -type f -name "*.env" -print0)

    # echo ${platforms_array}
    #-------------------------------------------------------
    if [ "${#platforms_array[@]}" == "0" ]; then
        echo "No platforms exists, return now"
        return 1
    fi
    echo
    echo "Now we have below platforms:"
    i=0
    for platform in ${platforms_array[@]}; do
        ((i++))
        echo -e "  [${i}].${platform}"
    done

    # echo ${platforms_array[1]}
    #-------------------------------------------------------
    read -p "Please type the index your choice(e.g. if you wanna choose ${platforms_array[0]}, you can type 1):" user_type

    platform_number="$((${#platforms_array[@]}))"
    # echo "platform_number=${platform_number}"

    if ! [[ "${user_type}" =~ ^[0-9]+$ ]]; then
        echo "✗ Error: Invalid input. Please enter a number."
        return 1 # 使用 1 而不是 -1，更符合 shell 习惯
    fi

    if [ ${user_type} -lt 1 ] || [ ${user_type} -gt ${platform_number} ]; then
        echo "$user_type is not valid, plase input from 1 to ${platform_number}"
        return 1
    fi

    target_platform="${platforms_array[((${user_type} - 1))]}"
    echo ${target_platform}
    cd ${TOP_ROOT_DIR}

    # 1st. create configs/platforms/.env
    if [ -e ${PLATFORM_ENV_DEST_PATH} ]; then
        rm -f ${PLATFORM_ENV_DEST_PATH}
    fi
    ln -sf "${PLATFORM_ENV_SRC_DIR}/${target_platform}.env" "${PLATFORM_ENV_DEST_PATH}"

    # # 2nd. create project_handover/.env
    # if [ -e "${HANDOVER_DIR}/.env" ];then
    #     rm -f "${HANDOVER_DIR}/.env"
    # fi
    # ln -sf "${PLATFORM_ENV_SRC_DIR}/${target_platform}.env" "${HANDOVER_DIR}/.env"

    # 3rd. create project_handover/common.env
    if [ -e ${PLATFORM_INDEPENDENT_ENV_DEST_PATH} ]; then
        rm -f ${PLATFORM_INDEPENDENT_ENV_DEST_PATH}
    fi
    ln -sf ${PLATFORM_INDEPENDENT_ENV_SRC_PATH} ${PLATFORM_INDEPENDENT_ENV_DEST_PATH}

    ls -lha ${PLATFORM_ENV_DEST_PATH}
    ls -lha ${PLATFORM_INDEPENDENT_ENV_DEST_PATH}

    # # 4th. create project_handover/client soft link
    # if [ -e ${HANDOVER_CLIENTSIDE_DEST_PATH} ]; then
    #     rm -f ${HANDOVER_CLIENTSIDE_DEST_PATH}
    # fi
    # ln -sf "${HANDOVER_CLIENTSIDE_SRC_DIR}/clientside-${target_platform}" "${HANDOVER_CLIENTSIDE_DEST_PATH}"
    # ls -lha ${HANDOVER_CLIENTSIDE_DEST_PATH}

    echo
    echo "--- Setup env files (${target_platform}) Successfully ---"
    echo
}

1_1_setup_volume_soft_link(){
    VOLUME_SRC_DIR="${HOST_VOLUME_DIR}"
    VOLUME_DEST_DIR="${HANDOVER_DIR}/clientside/volumes"

    if [ ! -d ${VOLUME_SRC_DIR} ]; then
        echo "fault: VOLUME_SRC_DIR=${VOLUME_SRC_DIR}, it is not exist"
        exit 1
    fi

    ln -nsf ${VOLUME_SRC_DIR} ${VOLUME_DEST_DIR}
    ls -lha ${VOLUME_DEST_DIR}
}

################################################################################
# 2. Build all stages of Docker images
# Returns:
#   0 on success, 1 on failure
################################################################################
2_build_images() {
    # Build is optional, other steps are mandatory
    if prompt_with_timeout "Build [ClientSide] images?" 10; then
        _build_images_clientside || exit 1
    else
        echo "Build clientside image stages skipped."
    fi

    # Build is optional, other steps are mandatory
    if [ "${ENABLE_SERVERSIDE}" == "true" ]; then
        if prompt_with_timeout \"Build [ServerSide] images?\" 10; then
            _build_images_serverside || exit 1
        else
            echo "Build serverside image stages skipped."
        fi
    fi
}

_build_images_clientside() {
    echo -e "\n=== 1. Building ClientSide Docker Images ==="

    local stages=(
        "Base image:stage_1_base"
        "Tools:stage_2_tools"
        "SDK:stage_3_sdk"
        "Configuration:stage_4_config"
        "Final image:stage_5_final"
    )

    if ! ${BUILD_SCRIPT_DIR}/docker/dev-env-clientside/build.sh; then
        echo "Error: Failed to build $name"
        return 1
    fi

    # for stage in "${stages[@]}"; do
    #     local name="${stage%%:*}"
    #     local script="${stage#*:}"
    #     echo "Building stage: $name"
    #     if ! ${BUILD_SCRIPT_DIR}/docker/dev-env-clientside/$script/build.sh; then
    #         echo "Error: Failed to build $name"
    #         return 1
    #     fi
    # done

    return 0
}

_build_images_serverside() {
    echo -e "\n=== 1. Building ServerSide Docker Images ==="

    echo "Start Building ServerSide Dev Env"
    ${BUILD_SCRIPT_DIR}/docker/dev-env-serverside/build.sh
    echo "Done with ServerSide Dev Env Building."

    return 0
}

################################################################################
# 3. Prepare version information and store final image ID
# Returns:
#   0 on success, 1 on failure
################################################################################
3_prepare_version_info() {
    echo -e "\n=== 2. Preparing Version Information ==="
    echo "Using version: ${PROJECT_VERSION:-v0.6.1}"
    VERSION="${PROJECT_VERSION:-v0.6.1}"

    echo "Getting final image ID for ${IMAGE_NAME}:${LATEST_IMAGE_TAG}"
    FINAL_IMAGE_ID=$(docker images ${IMAGE_NAME}:${LATEST_IMAGE_TAG} -q)
    if [ -z "$FINAL_IMAGE_ID" ]; then
        echo "Error: Failed to get final image ID-${IMAGE_NAME}:${LATEST_IMAGE_TAG}"
        return 1
    fi
    echo "Final image ID: ${FINAL_IMAGE_ID}"

    # 添加服务端镜像ID获取
    if [[ "${ENABLE_SERVERSIDE}" == "true" ]]; then
        echo "Getting serverside image ID for ${SERVERSIDE_IMAGE_NAME}:${PROJECT_VERSION}"
        FINAL_SERVERSIDE_IMAGE_ID=$(docker images ${SERVERSIDE_IMAGE_NAME}:${PROJECT_VERSION} -q)
        if [ -z "$FINAL_SERVERSIDE_IMAGE_ID" ]; then
            echo "Warning: No existing serverside image found with ID, this is normal for first push"
            FINAL_SERVERSIDE_IMAGE_ID="not_found" # 设置一个默认值，避免后续清理时出错
        else
            echo "Final serverside image ID: ${FINAL_SERVERSIDE_IMAGE_ID}"
        fi
    fi

    return 0
}

################################################################################
# Helper function to tag a single image
# Arguments:
#   $1 - Image name
#   $2 - Source tag
#   $3 - Target tag
# Returns:
#   0 on success, 1 on failure
################################################################################
_tag_single_image() {
    # local image_name="$1"
    # local source_tag="$2"
    # local target_tag="$3"
    # local full_source="${image_name}:${source_tag}"
    # local full_target="${REGISTRY_URL}/${image_name}:${target_tag}"
    local source="${1}"
    local target="${2}"

    echo "Executing: docker tag ${source} ${target}"
    if ! docker tag "${source}" "${target}"; then
        echo "✗ Error: Failed to tag ${source} as ${target}"
        return 1
    fi
    return 0
}

################################################################################
# Helper function to tag images
# Arguments:
#   $1 - Tag name
# Returns:
#   0 on success, 1 on failure
################################################################################
_tag_image_onair() {
    local result=0
    local tag_num="${PROJECT_VERSION}"
    local tag_latest="latest"
    local is_local="${1}"
    local full_client_source="${IMAGE_NAME}:${tag_num}"

    if [ "${is_local}" != "local" ]; then
        # 1.1 Tag client image with version number
        local full_target="${REGISTRY_URL}/${IMAGE_NAME}:${tag_num}"

        if ! _tag_single_image "${full_client_source}" "${full_target}"; then
            echo "✗ Error: Failed to tag client image ${full_client_source} as ${full_target}"
            result=1
        fi
    fi

    # 1.2 Tag client image as tag latest
    if [ "${is_local}" == "local" ]; then
        local full_target_latest="${IMAGE_NAME}:${tag_latest}"
    else
        local full_target_latest="${REGISTRY_URL}/${IMAGE_NAME}:${tag_latest}"
    fi
    if ! _tag_single_image "${full_client_source}" "${full_target_latest}"; then
        echo "✗ Error: Failed to tag client image ${full_client_source} as ${full_target_latest}"
        result=1
    fi

    if [[ "${ENABLE_SERVERSIDE}" == "true" ]]; then
        local full_server_source="${SERVERSIDE_IMAGE_NAME}:${tag_num}"

        # 2.1 Tag server image with version number
        if [ "${is_local}" != "local" ]; then
            local full_server_target="${REGISTRY_URL}/${SERVERSIDE_IMAGE_NAME}:${tag_num}"
            if ! _tag_single_image "${full_server_source}" "${full_server_target}"; then
                echo "✗ Error: Failed to tag server image ${full_server_source} as ${full_server_target}"
                result=1
            fi
        fi

        # 2.2 Tag server image as tag latest
        if [ "${is_local}" == "local" ]; then
            local full_server_target_latest="${SERVERSIDE_IMAGE_NAME}:${tag_latest}"
        else
            local full_server_target_latest="${REGISTRY_URL}/${SERVERSIDE_IMAGE_NAME}:${tag_latest}"
        fi
        if ! _tag_single_image "${full_server_source}" "${full_server_target_latest}"; then
            echo "✗ Error: Failed to tag server image ${full_server_source} as ${full_server_target_latest}"
            result=1
        fi
    fi

    return ${result}
}

################################################################################
# 4. Tag and push images to registry
# Returns:
#   0 on success, 1 on failure
################################################################################
4_tag_images() {

    if prompt_with_timeout "Tag images?" 10; then
        echo -e "\n=== 3. Tagging Images ==="
        local result=0

        # Tag images
        echo "Tagging images..."
        if [ "${HAVE_HARBOR_SERVER}" == "TRUE" ]; then
            _tag_image_onair "onair"
        else
            _tag_image_onair "local"
        fi

        echo "Done with tagging images."

    else
        echo "Tagging stages skipped."
    fi

    return ${result}
}

5_push_images() {
    local result="0"

    if [ "${HAVE_HARBOR_SERVER}" == "TRUE" ]; then
        if prompt_with_timeout "Push images to the registry?" 10; then
            echo -e "\n=== 4. Pushing Images ==="

            # Push images only if tagging was successful
            echo "Pushing images..."
            if ! _push_and_verify_image "${PROJECT_VERSION}"; then
                echo "✗ Error: Failed to push version ${PROJECT_VERSION}"
                result=1
            fi

            if ! _push_and_verify_image "latest"; then
                echo "✗ Error: Failed to push latest version"
                result=1
            fi

        else
            echo "Push stages skipped."
        fi
    fi

    return ${result}
}

################################################################################
# Helper function to push and verify a single image
# Arguments:
#   $1 - Tag name
# Returns:
#   0 on success, 1 on failure
################################################################################
_push_and_verify_single_image() {
    local image_name="$1"
    local tag="$2"
    local full_image_name="${REGISTRY_URL}/${image_name}:${tag}"

    echo -e "\n##############################\nPushing ${image_name}:${tag} to registry...\n##############################"
    echo "Executing: docker push ${full_image_name}"

    # 1st stage: push image
    if docker push "${full_image_name}"; then
        # 如果 docker push 成功（退出码为 0），则执行这里的代码
        echo "✓ ${image_name}:${tag} pushed successfully"
    else
        # 如果 docker push 失败（退出码为非 0），则执行这里的代码
        echo "✗ Error: Failed to push ${image_name}:${tag}"
        return 1
    fi
    #------------------------------------
    # local push_output
    # push_output="$(docker push "${full_image_name}" 2>&1)"

    # if [ "${push_output}" == "" ]; then
    #     echo "✗ Error: Failed to push ${image_name}:${tag}"
    #     return 1
    # else
    #     echo "✓ ${image_name}:${tag} pushed successfully"
    # fi

    #############################################################
    # verify the image on the server
    #############################################################

    echo -e "\nExecuting: docker manifest inspect ${full_image_name}"

    # 2nd stage: manifest
    local manifest_output
    manifest_output=$(docker manifest inspect "${full_image_name}")

    if [ $? -ne 0 ]; then
        echo "✗ Error: Failed to inspect manifest for ${image_name}:${tag}. Is it really in the registry?"
        echo "Inspect output: ${manifest_output}"
        return 1
    fi

    # 3rd stage: verify manifest output
    local digest=$(echo "${manifest_output}" | jq -r '.config.digest')
    # local digest=$(echo "${manifest_output}" | grep -o 'sha256:[a-f0-9]*' | head -n 1)

    if [ -z "${digest}" ]; then
        echo "✗ Error: Could not extract digest for ${image_name}:${tag} from manifest."
        echo "Digest output: ${digest}"
        return 1
    fi

    echo "Digest found: ${digest}"
    echo "✓ ${image_name}:${tag} inspected successfully, digest is ${digest}"

    #-------------------------------------------
    # # echo -e "\nExecuting: docker manifest inspect --insecure ${full_image_name}"
    # # if docker manifest inspect --insecure "${full_image_name}" >/dev/null 2>&1; then
    # echo -e "\nExecuting: docker manifest inspect ${full_image_name}"
    # # docker manifest inspect "${full_image_name}"
    # local digest
    # # digest=$(echo "${push_output}" | grep "digest:" | awk '{print $2}')
    # digest=$(echo "${push_output}" | grep "digest:" | awk '{print $3}' )
    # # echo "push_output=${push_output}"
    # # echo
    # # echo "start"
    # # echo $(echo "${push_output}" | grep "digest:" | awk "$(print $2)")
    # # echo "end"
    # # echo
    # echo "digest=${digest}"
    # docker inspect "${full_image_name}@${digest}" 2>&1 > /dev/null
    # if [ $? -eq 0 ]; then
    #     echo "✓ ${image_name}:${tag} inspected successfully"
    #     return 0
    # else
    #     echo "✗ Error: Failed to verify ${image_name}:${tag}"
    #     return 1
    # fi
}

_push_and_verify_single_image_old() {
    local image_name="$1"
    local tag="$2"
    local full_image_name="${REGISTRY_URL}/${image_name}:${tag}"

    echo -e "\n##############################\nPushing ${image_name}:${tag} to registry...\n##############################"
    echo "Executing: docker push ${full_image_name}"

    if ! docker push "${full_image_name}"; then
        echo "✗ Error: Failed to push ${image_name}:${tag}"
        return 1
    fi

    #############################################################
    # verify the image on the server
    #############################################################

    # echo -e "\nExecuting: docker manifest inspect --insecure ${full_image_name}"
    # if docker manifest inspect --insecure "${full_image_name}" >/dev/null 2>&1; then
    echo -e "\nExecuting: docker manifest inspect ${full_image_name}"
    docker manifest inspect "${full_image_name}"
    if [ $? -eq 0 ]; then
        echo "✓ ${image_name}:${tag} pushed successfully"
        return 0
    else
        echo "✗ Error: Failed to verify ${image_name}:${tag}"
        return 1
    fi
}

_push_and_verify_image() {
    local tag="$1"
    local result=0

    # 推送客户端镜像
    if ! _push_and_verify_single_image "${IMAGE_NAME}" "${tag}"; then
        echo "✗ Error: Failed to push/verify client image"
        result=1
    fi

    # 如果启用了服务端，推送服务端镜像
    if [[ "${ENABLE_SERVERSIDE}" == "true" ]]; then
        if ! _push_and_verify_single_image "${SERVERSIDE_IMAGE_NAME}" "${tag}"; then
            echo "✗ Error: Failed to push/verify server image"
            result=1
        fi
    fi

    return ${result}
}

################################################################################
# 5. Clean up intermediate images
# Returns:
#   0 on success, 1 on failure
################################################################################
6_cleanup_images() {

    if prompt_with_timeout "Clean all mid-stage images?" 10; then
        echo -e "\n=== 5. Cleaning Up Intermediate Images ==="

        # 清理客户端镜像
        echo "Finding and removing intermediate images for ${IMAGE_NAME}"
        echo "Keeping final image ID: ${FINAL_IMAGE_ID}"
        # docker images | grep "${IMAGE_NAME}" | grep -v "${REGISTRY_URL}" | \
        # awk '{print $3}' | while read -r id; do
        #     if [ "$id" != "$FINAL_IMAGE_ID" ]; then
        #         echo "Removing image ID: $id"
        #         docker rmi -f "$id" || true
        #     fi
        # done
        if [[ "${USE_REGISTRY_FILTER}" == "true" && -n "${REGISTRY_URL}" ]]; then
            # 有 REGISTRY_URL 时，排除 REGISTRY_URL 中的镜像
            docker images | grep "${IMAGE_NAME}" | grep -v "${REGISTRY_URL}" |
                awk '{print $3}' | while read -r id; do
                if [ "$id" != "${FINAL_IMAGE_ID}" ]; then
                    echo "Removing image ID: $id"
                    docker rmi -f "$id" || true
                fi
            done
        else
            # 无 REGISTRY_URL 或不使用过滤时，直接清理所有中间镜像
            docker images | grep "${IMAGE_NAME}" |
                awk '{print $3}' | while read -r id; do
                if [ "$id" != "${FINAL_IMAGE_ID}" ]; then
                    echo "Removing image ID: $id"
                    docker rmi -f "$id" || true
                fi
            done
        fi

        # 清理服务端镜像
        if [[ "${ENABLE_SERVERSIDE}" == "true" ]]; then
            echo "Finding and removing intermediate images for ${SERVERSIDE_IMAGE_NAME}"
            echo "Keeping final serverside image ID: ${FINAL_SERVERSIDE_IMAGE_ID}"
            docker images | grep "${SERVERSIDE_IMAGE_NAME}" | grep -v "$ {REGISTRY_URL}" |
                awk '{print $3}' | while read -r id; do
                if [ "$id" != "$FINAL_SERVERSIDE_IMAGE_ID" ]; then
                    echo "Removing serverside image ID: $id"
                    docker rmi -f "$id" || true
                fi
            done
        fi
    fi # end of if [ prompt_with_timeout "Clean all mid-stage images?" 10 ];then

    return 0
}

# Execute main function
main "$@"
