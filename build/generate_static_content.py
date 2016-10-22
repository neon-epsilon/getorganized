#!/usr/bin/env python
# -*- coding: utf-8 -*-

# import module ../config/config.py
import pathlib, sys
dir_name = (pathlib.Path.cwd() / pathlib.Path(__file__)).parent
sys.path.append(str(dir_name.parent / 'engine' / 'config'))
import config

generate_hoursofwork_output_filename =  config.www_root / 'engine' / 'reporting' / 'build_hoursofwork_output.py'
generate_spendings_output_filename =  config.www_root / 'engine' / 'reporting' / 'build_spendings_output.py'
generate_calories_output_filename =  config.www_root / 'engine' / 'reporting' / 'build_calories_output.py'

import subprocess

# generate static content
subprocess.Popen(['python', str(generate_hoursofwork_output_filename)]).wait()
subprocess.Popen(['python', str(generate_spendings_output_filename)]).wait()
subprocess.Popen(['python', str(generate_calories_output_filename)]).wait()