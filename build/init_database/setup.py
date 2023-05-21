#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os, pathlib, pymysql

import config

file_path = pathlib.Path( os.path.realpath(__file__) )
dir_path = file_path.parent

schema_filename = dir_path / 'schema.sql'
initial_data_filename = dir_path / 'initial_data.sql'
schema_filename_shoppinglist = dir_path / 'schema_shoppinglist.sql'
initial_data_filename_shoppinglist = dir_path / 'initial_data_shoppinglist.sql'
generate_static_content_script_filename = dir_path / 'generate_static_content.py'

def execute_sql_file(filename, connection):
    with connection.cursor() as cursor:
        # We need to repeat the "with"-block.
        # Otherwise sql-errors do not raise an exception but the script simply hangs.
        with open(filename) as f:
            sql_file = f.read()
        sql_commands = sql_file.split(';')
        for query in sql_commands:
            # execute query only if non empty
            query = query.strip()
            if query: cursor.execute(query)


print('setting up database')
connection = pymysql.connect(host=config.db_host, user=config.db_user, passwd=config.db_password)

with connection.cursor() as cursor:
    cursor.execute(
        f"CREATE DATABASE IF NOT EXISTS {config.db_name}"
    )
    cursor.execute(
        f"USE {config.db_name}"
    )

print('...creating tables')
execute_sql_file(str(schema_filename), connection)

print('...creating initial data')
execute_sql_file(str(initial_data_filename), connection)

connection.close()

connection = pymysql.connect(host=config.db_host_shoppinglist, user=config.db_user_shoppinglist, passwd=config.db_password_shoppinglist)

with connection.cursor() as cursor:
    cursor.execute(
        f"CREATE DATABASE IF NOT EXISTS {config.db_name_shoppinglist}"
    )
    cursor.execute(
        f"USE {config.db_name_shoppinglist}"
    )

print('...creating shopping list table')
execute_sql_file(str(schema_filename_shoppinglist), connection)

print('...creating initial shopping list data')
execute_sql_file(str(initial_data_filename_shoppinglist), connection)

connection.close()

print('done')
