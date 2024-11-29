#!/bin/bash
################################################################################
# Script Name: temp_test.sh
# Description: Build multi-stage Docker image and push to registry
# Author: @MrJamesLZA
# Date: 2024-11-28
################################################################################

set -e

################################################################################
# Main function to orchestrate the entire build process
################################################################################
main() {
    echo "Loading environment variables from project_handover/.env"
    source project_handover/.env

    # Build is optional, other steps are mandatory
    if 1_prompt_for_build; then
        2_build_images || exit 1
    else
        echo "Build stages skipped."
    fi

    3_prepare_version_info || exit 1
    4_tag_and_push_images || exit 1
    5_cleanup_images || exit 1

    echo -e "\n=== Build Process Completed Successfully ==="
}

################################################################################
# 1. Prompt user for build confirmation with countdown
# Returns:
#   0 if build should proceed, 1 if build should be skipped
################################################################################
1_prompt_for_build() {
    echo -e "\nDo you want to build all five stages of Docker images?"
    echo "Default: Yes (Press 'n' to skip, any other key to continue)"

    for i in 3 2 1; do
        echo -ne "\rStarting in $i seconds... "
        for ((j=0; j<10; j++)); do
            read -t 0.1 -n 1 input
            if [ $? -eq 0 ]; then
                echo -e "\n"
                if [[ "${input,,}" == "n" ]]; then
                    echo "Skipping build stages..."
                    return 1
                else
                    echo "Proceeding with build..."
                    return 0
                fi
            fi
        done
    done

    echo -e "\nProceeding with default build..."
    return 0
}

################################################################################
# 2. Build all stages of Docker images
# Returns:
#   0 on success, 1 on failure
################################################################################
2_build_images() {
    echo -e "\n=== 1. Building Docker Images ==="

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
        if ! docker/$script/build.sh; then
            echo "Error: Failed to build $name"
            return 1
        fi
    done

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
    return 0
}

################################################################################
# 4. Tag and push images to registry
# Returns:
#   0 on success, 1 on failure
################################################################################
4_tag_and_push_images() {
    echo -e "\n=== 3. Tagging and Pushing Images ==="

    # Tag images
    _tag_image "${PROJECT_VERSION}" || return 1
    _tag_image "latest" || return 1

    # Push images
    _push_and_verify_image "${PROJECT_VERSION}" || return 1
    _push_and_verify_image "latest" || return 1

    return 0
}

################################################################################
# Helper function to tag a single image
# Arguments:
#   $1 - Tag name
# Returns:
#   0 on success, 1 on failure
################################################################################
_tag_image() {
    local tag="$1"
    echo "Executing: docker tag ${IMAGE_NAME}:${LATEST_IMAGE_TAG} ${REGISTRY_URL}/${IMAGE_NAME}:${tag}"
    docker tag ${IMAGE_NAME}:${LATEST_IMAGE_TAG} ${REGISTRY_URL}/${IMAGE_NAME}:${tag} || return 1
}

################################################################################
# Helper function to push and verify a single image
# Arguments:
#   $1 - Tag name
# Returns:
#   0 on success, 1 on failure
################################################################################
_push_and_verify_image() {
    local tag="$1"
    echo "Pushing ${tag} tag to registry..."
    echo "Executing: docker push ${REGISTRY_URL}/${IMAGE_NAME}:${tag}"

    # Capture the push output
    local push_output
    push_output=$(docker push ${REGISTRY_URL}/${IMAGE_NAME}:${tag})
    local push_status=$?

    echo "${push_output}"

    # Verify by checking for digest in push output
    if [ $push_status -eq 0 ] && echo "${push_output}" | grep -q "digest: sha256:"; then
        local digest=$(echo "${push_output}" | grep "digest: sha256:" | tail -n1 | awk '{print $3}')
        echo "✓ ${tag} tag verified successfully (digest: ${digest})"
        return 0
    else
        echo "✗ Error: Failed to push or verify ${tag} tag"
        return 1
    fi
}

################################################################################
# 5. Clean up intermediate images
# Returns:
#   0 on success, 1 on failure
################################################################################
5_cleanup_images() {
    echo -e "\n=== 4. Cleaning Up Intermediate Images ==="
    echo "Finding and removing intermediate images for ${IMAGE_NAME}"
    echo "Keeping final image ID: ${FINAL_IMAGE_ID}"

    docker images | grep "${IMAGE_NAME}" | grep -v "${REGISTRY_URL}" | \
    awk '{print $3}' | while read -r id; do
        if [ "$id" != "$FINAL_IMAGE_ID" ]; then
            echo "Removing image ID: $id"
            docker rmi -f "$id" || true
        fi
    done

    return 0
}

# Execute main function
main "$@"
