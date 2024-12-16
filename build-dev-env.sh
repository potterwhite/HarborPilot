#!/bin/bash
################################################################################
# Script Name: temp_test.sh
# Description: Build multi-stage Docker image and push to registry
# Usage: ./build-dev-env.sh
#
# Author: @MrJamesLZA
# created date: 2024-11-28
# last modified: 2024-12-03
################################################################################

set -e

################################################################################
# Main function to orchestrate the entire build process
################################################################################
main() {
    SECONDS=0
    echo "Build process started at: "
    echo "###################################"
    echo "#   $(LC_ALL=C date +%a\ %b%d.%Y\ %H:%M:%S)"
    echo "###################################"

    echo "Loading environment variables from project_handover/.env"
    source project_handover/.env

    2_build_images || exit 1

    3_prepare_version_info || exit 1

    4_tag_images || exit 1

    5_push_images || exit 1

    6_cleanup_images || exit 1

    local duration=$SECONDS
    echo -e "\n=== Build Process Completed Successfully ==="
    echo "Total execution time: $((duration/3600))h $((duration%3600/60))m $((duration%60))s"
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

################################################################################
# 2. Build all stages of Docker images
# Returns:
#   0 on success, 1 on failure
################################################################################
2_build_images(){
    # Build is optional, other steps are mandatory
    if prompt_with_timeout "Build [ClientSide] images?" 10; then
        _build_images_clientside || exit 1
    else
        echo "Build clientside image stages skipped."
    fi

    # Build is optional, other steps are mandatory
    if prompt_with_timeout "Build [ServerSide] images?" 10; then
        _build_images_serverside || exit 1
    else
        echo "Build serverside image stages skipped."
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

    for stage in "${stages[@]}"; do
        local name="${stage%%:*}"
        local script="${stage#*:}"
        echo "Building stage: $name"
        if ! docker/dev-env-clientside/$script/build.sh; then
            echo "Error: Failed to build $name"
            return 1
        fi
    done

    # echo "Start Building ServerSide Dev Env"
    # docker/dev-env-serverside/build.sh
    # echo "Done with ServerSide Dev Env Building."

    return 0
}

_build_images_serverside() {
    echo -e "\n=== 1. Building ServerSide Docker Images ==="

    echo "Start Building ServerSide Dev Env"
    docker/dev-env-serverside/build.sh
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
        echo "Error: Failed to get final image ID"
        return 1
    fi
    echo "Final image ID: ${FINAL_IMAGE_ID}"

    # 添加服务端镜像ID获取
    if [[ "${ENABLE_SERVERSIDE}" == "true" ]]; then
        echo "Getting serverside image ID for ${SERVERSIDE_IMAGE_NAME}:${PROJECT_VERSION}"
        FINAL_SERVERSIDE_IMAGE_ID=$(docker images ${SERVERSIDE_IMAGE_NAME}:${PROJECT_VERSION} -q)
        if [ -z "$FINAL_SERVERSIDE_IMAGE_ID" ]; then
            echo "Warning: No existing serverside image found with ID, this is normal for first push"
            FINAL_SERVERSIDE_IMAGE_ID="not_found"  # 设置一个默认值，避免后续清理时出错
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
    local image_name="$1"
    local source_tag="$2"
    local target_tag="$3"
    local full_source="${image_name}:${source_tag}"
    local full_target="${REGISTRY_URL}/${image_name}:${target_tag}"

    echo "Executing: docker tag ${full_source} ${full_target}"
    if ! docker tag "${full_source}" "${full_target}"; then
        echo "✗ Error: Failed to tag ${image_name} with ${target_tag}"
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
_tag_image() {
    local tag="$1"
    local result=0

    # Tag client image
    if ! _tag_single_image "${IMAGE_NAME}" "${LATEST_IMAGE_TAG}" "${tag}"; then
        echo "✗ Error: Failed to tag client image"
        result=1
    fi

    # Tag server image if enabled
    if [[ "${ENABLE_SERVERSIDE}" == "true" ]]; then
        if ! _tag_single_image "${SERVERSIDE_IMAGE_NAME}" "${PROJECT_VERSION}" "${tag}"; then
            echo "✗ Error: Failed to tag server image"
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
        if ! _tag_image "${PROJECT_VERSION}"; then
            echo "✗ Error: Failed to tag images with version ${PROJECT_VERSION}"
            result=1
        fi

        if ! _tag_image "latest"; then
            echo "✗ Error: Failed to tag images as latest"
            result=1
        fi

        echo "Done with tagging images."

    else
        echo "Tagging stages skipped."
    fi

    return ${result}
}

5_push_images() {

    if prompt_with_timeout "Push images to the registry?" 10; then
        echo -e "\n=== 4. Pushing Images ==="
        local result=0

        # Push images only if tagging was successful
        if [ ${result} -eq 0 ]; then
            echo "Pushing images..."
            if ! _push_and_verify_image "${PROJECT_VERSION}"; then
                echo "✗ Error: Failed to push version ${PROJECT_VERSION}"
                result=1
            fi

            if ! _push_and_verify_image "latest"; then
                echo "✗ Error: Failed to push latest version"
                result=1
            fi
        fi

    else
        echo "Push stages skipped."
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

    if ! docker push "${full_image_name}"; then
        echo "✗ Error: Failed to push ${image_name}:${tag}"
        return 1
    fi

    #############################################################
    # verify the image on the server
    #############################################################

    echo -e "\nExecuting: docker manifest inspect --insecure ${full_image_name}"
    if docker manifest inspect --insecure "${full_image_name}" >/dev/null 2>&1; then
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
        docker images | grep "${IMAGE_NAME}" | grep -v "${REGISTRY_URL}" | \
        awk '{print $3}' | while read -r id; do
            if [ "$id" != "$FINAL_IMAGE_ID" ]; then
                echo "Removing image ID: $id"
                docker rmi -f "$id" || true
            fi
        done

        # 清理服务端镜像
        if [[ "${ENABLE_SERVERSIDE}" == "true" ]]; then
            echo "Finding and removing intermediate images for ${SERVERSIDE_IMAGE_NAME}"
            echo "Keeping final serverside image ID: ${FINAL_SERVERSIDE_IMAGE_ID}"
            docker images | grep "${SERVERSIDE_IMAGE_NAME}" | grep -v "$ {REGISTRY_URL}" | \
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
