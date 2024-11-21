#!/bin/bash

set -e

docker/stage_1_base/build.sh
docker/stage_2_tools/build.sh
docker/stage_3_sdk/build.sh
docker/stage_4_config/build.sh
docker/stage_5_final/build.sh

project_handover/start_dev_env.sh recreate

# docker exec -it -u developer embedded-dev bash
docker exec -it embedded-dev bash