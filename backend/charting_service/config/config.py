# set up relevant variables
import pathlib
import configparser

# set up webroot
file_name = pathlib.Path.cwd() / pathlib.Path(__file__)
www_root = file_name.parent.parent.parent

# set up database login data
__parser = configparser.ConfigParser()
__parser.read( str(www_root / 'config' / 'config.ini') )

db_name = __parser.get('DB', 'name').strip('"')
db_host = __parser.get('DB', 'host').strip('"')
db_user = __parser.get ('DB', 'user').strip('"')
db_password = __parser.get('DB', 'password').strip('"')

db_name_shoppinglist = __parser.get('DB_shoppinglist', 'name').strip('"')
db_host_shoppinglist = __parser.get('DB_shoppinglist', 'host').strip('"')
db_user_shoppinglist = __parser.get ('DB_shoppinglist', 'user').strip('"')
db_password_shoppinglist = __parser.get('DB_shoppinglist', 'password').strip('"')
