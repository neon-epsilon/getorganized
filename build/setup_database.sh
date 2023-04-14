#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
set -x

SCRIPT_DIR=$(dirname -- "$( readlink -f -- "$0"; )")

cp $SCRIPT_DIR/../config/config.{ini,py} build/database_setup
docker build -t database_setup $SCRIPT_DIR/database_setup

docker run -it --rm database_setup python ./setup.py
