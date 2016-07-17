# set up relevant variables
import pathlib
import configparser

# set up webroot
file_name = pathlib.Path.cwd() / pathlib.Path(__file__)
www_root = file_name.parent.parent.parent

# set up database login data
__parser = configparser.ConfigParser()
__parser.read( str(www_root / 'etc' / 'config.ini') )
db_name = __parser.get('DB', 'name').strip('"')
db_host = __parser.get('DB', 'host').strip('"')
db_user = __parser.get ('DB', 'user').strip('"')
db_password = __parser.get('DB', 'password').strip('"')
