#!/bin/bash

set -euo pipefail
IFS=$'\n\t'
set -x

python generate_calories_output.py >/dev/null 2>/dev/null
python generate_spendings_output.py >/dev/null 2>/dev/null
python generate_hoursofwork_output.py >/dev/null 2>/dev/null
