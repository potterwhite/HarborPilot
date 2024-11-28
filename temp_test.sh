#!/bin/bash

set -e

source project_handover/.env

# Build all stages
docker/stage_1_base/build.sh
docker/stage_2_tools/build.sh
docker/stage_3_sdk/build.sh
docker/stage_4_config/build.sh
docker/stage_5_final/build.sh

# Registry configuration from environment
REGISTRY="192.168.3.178:5000"
VERSION="${VERSION:-v0.6.1}"  # Use environment variable or default to v0.6.1

# Store the final image ID for later cleanup
FINAL_IMAGE_ID=$(docker images ${IMAGE_NAME}:${LATEST_IMAGE_TAG} -q)

echo "Tagging image ${IMAGE_NAME}:${LATEST_IMAGE_TAG} as ${REGISTRY}/${IMAGE_NAME}:${VERSION}"
docker tag ${IMAGE_NAME}:${LATEST_IMAGE_TAG} ${REGISTRY}/${IMAGE_NAME}:${VERSION}

echo "Tagging image as latest"
docker tag ${IMAGE_NAME}:${LATEST_IMAGE_TAG} ${REGISTRY}/${IMAGE_NAME}:latest

echo "Pushing images to registry..."
docker push ${REGISTRY}/${IMAGE_NAME}:${VERSION}
docker push ${REGISTRY}/${IMAGE_NAME}:latest

echo "Cleaning up intermediate images..."
# Remove all images with name ${IMAGE_NAME} except the final one
docker images | grep "${IMAGE_NAME}" | grep -v "${REGISTRY}" | awk '{print $3}' | while read -r id; do
    if [ "$id" != "$FINAL_IMAGE_ID" ]; then
        docker rmi -f "$id" || true
    fi
done

echo "Image push and cleanup completed successfully"
