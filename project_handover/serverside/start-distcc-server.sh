#!/bin/bash

# 获取项目名称
PROJECT_NAME=$1
if [ -z "$PROJECT_NAME" ]; then
    echo "Usage: $0 <project_name>"
    exit 1
fi

# 启动 distcc 服务容器
docker run -d \
    --name "distcc-${PROJECT_NAME}" \
    --restart unless-stopped \
    -v /opt/toolchains:/opt/toolchains:ro \
    "${REGISTRY_URL}/distcc-${PROJECT_NAME}:latest"

echo "Distcc server for ${PROJECT_NAME} is running"