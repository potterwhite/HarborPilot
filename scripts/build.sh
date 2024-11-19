#!/bin/bash
set -e

# Load environment variables
source .env

# Build image
docker compose --progress plain build