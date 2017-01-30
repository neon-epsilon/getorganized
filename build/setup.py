#!/usr/bin/env python
# -*- coding: utf-8 -*-

# import module ../config/config.py
import pathlib, sys
dir_name = (pathlib.Path.cwd() / pathlib.Path(__file__)).parent
sys.path.append(str(dir_name.parent / 'engine' / 'config'))
import config

schema_filename = dir_name / 'schema.sql'
initial_data_filename = dir_name / 'initial_data.sql'
schema_shared_filename = dir_name / 'schema_shared.sql'
initial_data_shared_filename = dir_name / 'initial_data_shared.sql'
generate_static_content_script_filename = dir_name / 'generate_static_content.py'

# set up database
print('setting up database')
import pymysql # Not MySQLdb. Because of a bug MySQLdb can't handle large queries.
# fetch from database
connection = pymysql.connect(host=config.db_host, user=config.db_user, passwd=config.db_password, database=config.db_name)
with connection as cursor:
    # initiate database
    with open( str( schema_filename) ) as f:
        query = f.read()
    cursor.execute(query)
    # populate the database with data
    with open( str( initial_data_filename) ) as f:
        query = f.read()
    cursor.execute(query)
connection.close()

print('setting up shared database')
# fetch from database
connection = pymysql.connect(host=config.db_shared_host, user=config.db_shared_user, passwd=config.db_shared_password, database=config.db_shared_name)
with connection as cursor:
    # initiate database
    with open( str( schema_shared_filename) ) as f:
        query = f.read()
    cursor.execute(query)
    # populate the database with data
    with open( str( initial_data_shared_filename) ) as f:
        query = f.read()
    cursor.execute(query)
connection.close()

# generate static content
print('generating static content')
import subprocess
subprocess.Popen(['python', str( generate_static_content_script_filename )]).wait()

print('done')
