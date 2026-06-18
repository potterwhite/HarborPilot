#!/bin/bash
################################################################################
# Module: build.sh
# Description: Docker build, tag, and push functions for HarborPilot
# Functions: 2_build_images, _build_images_clientside, _tag_single_image,
#            _tag_image_onair, 4_tag_images, _push_and_verify_single_image,
#            _push_and_verify_image, 5_push_images, 6_cleanup_images
################################################################################

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
}

################################################################################
# Build clientside Docker image
# Returns:
#   0 on success, 1 on failure
################################################################################
_build_images_clientside() {
    echo -e "\n=== 1. Building ClientSide Docker Images ==="

    if ! ${BUILD_SCRIPT_DIR}/docker/dev-env-clientside/build.sh; then
        echo "Error: Failed to build clientside image"
        return 1
    fi

    return 0
}

################################################################################
# 3. Prepare version information and store final image ID
# Returns:
#   0 on success, 1 on failure
################################################################################
3_prepare_version_info() {
    echo -e "\n=== 2. Preparing Version Information ==="
    echo "Using version: ${PROJECT_VERSION:-1.6.0}"
    VERSION="${PROJECT_VERSION:-1.6.0}"

    echo "Getting final image ID for ${IMAGE_NAME}:${LATEST_IMAGE_TAG}"
    FINAL_IMAGE_ID=$(docker images ${IMAGE_NAME}:${LATEST_IMAGE_TAG} -q)
    if [ -z "$FINAL_IMAGE_ID" ]; then
        echo "Error: Failed to get final image ID-${IMAGE_NAME}:${LATEST_IMAGE_TAG}"
        return 1
    fi
    echo "Final image ID: ${FINAL_IMAGE_ID}"

    return 0
}

################################################################################
# Helper function to tag a single image
# Arguments:
#   $1 - Source image (name:tag)
#   $2 - Target image (name:tag)
# Returns:
#   0 on success, 1 on failure
################################################################################
_tag_single_image() {
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
#   $1 - Tag mode ("onair" or "local")
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

    return ${result}
}

################################################################################
# 4. Tag and push images to registry
# Returns:
#   0 on success, 1 on failure
################################################################################
4_tag_images() {
    local result=0

    if prompt_with_timeout "Tag images?" 10; then
        echo -e "\n=== 3. Tagging Images ==="

        # Tag images
        echo "Tagging images..."
        if [[ "${HAVE_HARBOR_SERVER}" == "TRUE" ]]; then
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

################################################################################
# Helper function to push and verify a single image
# Arguments:
#   $1 - Image name
#   $2 - Tag name
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
        echo "✓ ${image_name}:${tag} pushed successfully"
    else
        echo "✗ Error: Failed to push ${image_name}:${tag}"
        return 1
    fi

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

    if [ -z "${digest}" ]; then
        echo "✗ Error: Could not extract digest for ${image_name}:${tag} from manifest."
        echo "Digest output: ${digest}"
        return 1
    fi

    echo "Digest found: ${digest}"
    echo "✓ ${image_name}:${tag} inspected successfully, digest is ${digest}"
}

################################################################################
# Helper function to push and verify an image
# Arguments:
#   $1 - Tag name
# Returns:
#   0 on success, 1 on failure
################################################################################
_push_and_verify_image() {
    local tag="$1"
    local result=0

    # Push client image
    if ! _push_and_verify_single_image "${IMAGE_NAME}" "${tag}"; then
        echo "✗ Error: Failed to push/verify client image"
        result=1
    fi

    return ${result}
}

################################################################################
# 5. Push images to registry
# Returns:
#   0 on success, 1 on failure
################################################################################
5_push_images() {
    local result="0"

    echo -e "\n=== 4. Pushing Images ==="

    if [ "${HAVE_HARBOR_SERVER}" == "TRUE" ]; then
        if prompt_with_timeout "Push images to the registry?" 10; then

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
    else
        echo -e "\n**[Skip]Because of HAVE_HARBOR_SERVER is not \"TRUE\"=${HAVE_HARBOR_SERVER}!, the image pushing has been Skipped.**"
    fi

    return ${result}
}

################################################################################
# 6. Clean up intermediate images
# Returns:
#   0 on success, 1 on failure
################################################################################
6_cleanup_images() {

    if prompt_with_timeout "Clean all mid-stage images?" 10; then
        echo -e "\n=== 5. Cleaning Up Intermediate Images ==="

        # Cleanup client images
        echo "Finding and removing intermediate images for ${IMAGE_NAME}"
        echo "Keeping final image ID: ${FINAL_IMAGE_ID}"

        local final_id="${FINAL_IMAGE_ID}"
        if [[ "${USE_REGISTRY_FILTER}" == "true" && -n "${REGISTRY_URL}" ]]; then
            docker images --format '{{.Repository}}:{{.Tag}} {{.ID}}' | grep "${IMAGE_NAME}" | grep -v "${REGISTRY_URL}" |
                awk '{print $2}' | sort -u | while read -r id; do
                if [ "$id" != "${final_id}" ] && [ -n "$id" ]; then
                    echo "Removing image ID: $id"
                    docker rmi -f "$id" 2>/dev/null || true
                fi
            done
        else
            docker images --format '{{.Repository}}:{{.Tag}} {{.ID}}' | grep "${IMAGE_NAME}" |
                awk '{print $2}' | sort -u | while read -r id; do
                if [ "$id" != "${final_id}" ] && [ -n "$id" ]; then
                    echo "Removing image ID: $id"
                    docker rmi -f "$id" 2>/dev/null || true
                fi
            done
        fi
    fi

    return 0
}
