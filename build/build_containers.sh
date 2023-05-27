#!/bin/bash

set -euo pipefail
IFS=$'\n\t'
set -x

SCRIPT_DIR=$(dirname -- "$(readlink -f -- "$0")")

docker build -t getorganized-api-and-frontend-service -f $SCRIPT_DIR/../api_and_frontend_service/Dockerfile .
docker build -t getorganized-charting-service -f $SCRIPT_DIR/../charting_service/Dockerfile .
