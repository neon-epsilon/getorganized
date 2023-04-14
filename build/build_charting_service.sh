#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
set -x

SCRIPT_DIR=$(dirname -- "$( readlink -f -- "$0"; )")

cp $SCRIPT_DIR/../config/config.{ini,py} backend/charting_service
docker build -t charting_service $SCRIPT_DIR/../backend/charting_service
