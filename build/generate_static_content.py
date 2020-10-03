#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# import module ../config/config.py
import pathlib, sys
dir_name = (pathlib.Path.cwd() / pathlib.Path(__file__)).parent
sys.path.append(str(dir_name.parent / 'backend' / 'config'))
import config

python_executable =  config.www_root / 'backend' / 'virtualenv' / 'bin' / 'python'

generate_hoursofwork_output_filename =  config.www_root / 'backend' / 'reporting' / 'build_hoursofwork_output.py'
generate_spendings_output_filename =  config.www_root / 'backend' / 'reporting' / 'build_spendings_output.py'
generate_calories_output_filename =  config.www_root / 'backend' / 'reporting' / 'build_calories_output.py'

import subprocess

# generate static content
subprocess.Popen([str(python_executable), str(generate_hoursofwork_output_filename)]).wait()
subprocess.Popen([str(python_executable), str(generate_spendings_output_filename)]).wait()
subprocess.Popen([str(python_executable), str(generate_calories_output_filename)]).wait()
