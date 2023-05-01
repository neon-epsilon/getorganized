#!/bin/bash

# Use the charting service to generate charts.

set -euo pipefail
IFS=$'\n\t'
set -x

SCRIPT_DIR=$(dirname -- "$(readlink -f -- "$0")")

docker run -it --rm --network=host -v $SCRIPT_DIR/../generated/:/usr/app/generated charting_service python ./generate_spendings_output.py
