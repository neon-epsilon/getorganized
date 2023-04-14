#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
set -x

SCRIPT_DIR=$(dirname -- "$( readlink -f -- "$0"; )")

docker build -t getorganized_database $SCRIPT_DIR/dev_database
# MYSQL_ROOT_PASSWORD needs to be set, otherwise the container errors on startup.
docker run --name getorganized_database --rm -e MYSQL_ROOT_PASSWORD=root -d -p 3306:3306 getorganized_database
