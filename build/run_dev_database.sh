#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
set -x

docker run --name getorganized_database --rm -e MYSQL_ROOT_PASSWORD=root -d -p 3306:3306 mysql:8.0
