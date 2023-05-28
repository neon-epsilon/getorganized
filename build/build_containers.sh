#!/bin/bash

set -euo pipefail
IFS=$'\n\t'
set -x

SCRIPT_DIR=$(dirname -- "$(readlink -f -- "$0")")
ROOT_DIR="$SCRIPT_DIR/.."

docker build -t getorganized-api-and-frontend-service \
	-f $ROOT_DIR/api_and_frontend_service/Dockerfile $ROOT_DIR/api_and_frontend_service
docker build -t getorganized-charting-service \
	-f $ROOT_DIR/charting_service/Dockerfile $ROOT_DIR/charting_service
