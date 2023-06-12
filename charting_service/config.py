import configparser
import pathlib
import pytz

file_name = pathlib.Path.cwd() / 'config' / 'config.ini'

# set up database login data
parser = configparser.ConfigParser()
parser.read(str(file_name))

timezone=pytz.timezone("Europe/Zurich")

db_host = parser.get('DB', 'host').strip('"')
db_name = parser.get('DB', 'name').strip('"')
db_user = parser.get ('DB', 'user').strip('"')
db_password = parser.get('DB', 'password').strip('"')

db_host_shoppinglist = parser.get('DB_shoppinglist', 'host').strip('"')
db_name_shoppinglist = parser.get('DB_shoppinglist', 'name').strip('"')
db_user_shoppinglist = parser.get ('DB_shoppinglist', 'user').strip('"')
db_password_shoppinglist = parser.get('DB_shoppinglist', 'password').strip('"')
