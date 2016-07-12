#!/bin/bash

DIR=$(dirname $0)
$DIR/../engine/reporting/build_spendings_output.py
$DIR/../engine/reporting/build_calories_output.py
#$DIR/../engine/reporting/build_hoursofwork_output.py
#$DIR/../engine/reporting/build_workout_output.py
