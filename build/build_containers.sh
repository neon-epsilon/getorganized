#!/bin/bash

set -euo pipefail
IFS=$'\n\t'
set -x

SCRIPT_DIR=$(dirname -- "$(readlink -f -- "$0")")

docker build -t database_setup -f $SCRIPT_DIR/database_setup/Dockerfile .
docker build -f $SCRIPT_DIR/../backend/charting_service/Dockerfile -t charting_service .
