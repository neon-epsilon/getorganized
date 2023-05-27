#!/bin/bash

# Use the charting service to generate charts.

set -euo pipefail
IFS=$'\n\t'
set -x

CHARTING_SERVICE_URL=localhost:8000

curl -vX POST "$CHARTING_SERVICE_URL/calories/"
curl -vX POST "$CHARTING_SERVICE_URL/spendings/"
curl -vX POST "$CHARTING_SERVICE_URL/hoursofwork/"
