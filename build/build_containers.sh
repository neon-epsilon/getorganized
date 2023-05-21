#!/bin/bash

set -euo pipefail
IFS=$'\n\t'
set -x

SCRIPT_DIR=$(dirname -- "$(readlink -f -- "$0")")

docker build -t getorganized-charting-service -f $SCRIPT_DIR/../backend/charting_service/Dockerfile .
