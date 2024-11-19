#!/bin/bash
set -e

# Load environment variables
source .env

# Run container
docker compose up -d

# Enter container
docker compose exec dev bash