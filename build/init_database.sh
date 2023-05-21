#!/bin/bash

# Set up a simple dev mysql instance and run it on localhost.

set -euo pipefail
IFS=$'\n\t'
set -x

SCRIPT_DIR=$(dirname -- "$(readlink -f -- "$0")")

docker build -t getorganized-init-database $SCRIPT_DIR/init_database
docker run --rm -it \
	--mount type=bind,source=$SCRIPT_DIR/../config,target=/usr/app/config \
	getorganized-init-database
