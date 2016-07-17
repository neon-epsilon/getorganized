#!/usr/bin/env python
import MySQLdb

# import module ../engine/config/config.py
import sys
import pathlib
file_path = pathlib.Path.cwd() / pathlib.Path(__file__)
sys.path.append( str(file_path.parent.parent / 'engine' / 'reporting') )
import config

query = ''
with open( str(file_path.parent / 'skeleton.sql'), 'r' ) as f:
    query = f.read()

con = MySQLdb.connect(config.db_host, config.db_user, config.db_password, config.db_name)
with con:
    cur = con.cursor()
    cur.execute(query)
