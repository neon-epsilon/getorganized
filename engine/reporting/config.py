# set up relevant variables
import os.path
import configparser

# set up webroot
www_root = os.path.dirname( os.path.dirname( os.path.dirname(os.path.abspath(__file__)) ) )

# set up database login data
__parser = configparser.ConfigParser()
__parser.read(www_root + '/etc/config.ini')
db_name = __parser.get('DB', 'name').strip('"')
db_host = __parser.get('DB', 'host').strip('"')
db_user = __parser.get ('DB', 'user').strip('"')
db_password = __parser.get('DB', 'password').strip('"')
