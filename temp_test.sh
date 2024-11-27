#!/bin/bash

set -e

source project_handover/.env

docker/stage_1_base/build.sh
docker/stage_2_tools/build.sh
docker/stage_3_sdk/build.sh
docker/stage_4_config/build.sh
docker/stage_5_final/build.sh

project_handover/ubuntu_only_entrance.sh start

# docker exec -it -u developer embedded-dev bash
docker exec -it ${CONTAINER_NAME} bash
