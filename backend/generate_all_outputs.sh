#!/bin/bash

# Use the charting service to generate charts.

set -euo pipefail
IFS=$'\n\t'
set -x

curl -vX POST 'localhost:8000/calories/'
curl -vX POST 'localhost:8000/spendings/'
curl -vX POST 'localhost:8000/hoursofwork/'
