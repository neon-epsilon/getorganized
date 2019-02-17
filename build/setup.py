#!/usr/bin/env python
# -*- coding: utf-8 -*-

import pathlib, sys
import pymysql # Not MySQLdb. Because of a bug MySQLdb can't handle large queries.
import subprocess
dir_name = (pathlib.Path.cwd() / pathlib.Path(__file__)).parent
sys.path.append(str(dir_name.parent / 'backend' / 'config'))
# import module ../backend/config/config.py
import config

schema_filename = dir_name / 'schema.sql'
initial_data_filename = dir_name / 'initial_data.sql'
schema_filename_shoppinglist = dir_name / 'schema_shoppinglist.sql'
initial_data_filename_shoppinglist = dir_name / 'initial_data_shoppinglist.sql'
generate_static_content_script_filename = dir_name / 'generate_static_content.py'


print('setting up database')
connection = pymysql.connect(host=config.db_host, user=config.db_user, passwd=config.db_password, database=config.db_name)

print('...creating tables')
with connection as cursor:
    with open( str( schema_filename) ) as f:
        query = f.read()
    cursor.execute(query)

print('...creating initial data')
with connection as cursor:
# We need to repeat the "with"-block.
# Otherwise sql-errors do not raise an exception but the script simply hangs.
    with open( str( initial_data_filename) ) as f:
        query = f.read()
    cursor.execute(query)

connection.close()

connection = pymysql.connect(host=config.db_host_shoppinglist, user=config.db_user_shoppinglist, passwd=config.db_password_shoppinglist, database=config.db_name_shoppinglist)

print('...creating shopping list table')
with connection as cursor:
    with open( str( schema_filename_shoppinglist) ) as f:
        query = f.read()
    cursor.execute(query)

print('...creating initial shopping list data')
with connection as cursor:
# We need to repeat the "with"-block.
# Otherwise sql-errors do not raise an exception but the script simply hangs.
    with open( str( initial_data_filename_shoppinglist) ) as f:
        query = f.read()
    cursor.execute(query)

connection.close()


print('generating static content')
subprocess.Popen(['python', str( generate_static_content_script_filename )]).wait()

print('done')
