# Building GetOrganized #

This application assumes you have a working PHP server with MySQL running on a linux machine.

Clone the repository and check out the deploy branch. Make sure the www root of your server is the root of this repository. In the configuration of your server, disallow access to the folders ```config``` and ```build```. (```config``` will contain access details for your database which should not be visible from the outside for obvious security reasons.)

Then, the Python virtualenv must be initialized. To do so, enter the following code from the root of the repository:

```shell
$ python3 -m venv backend/virtualenv
$ source backend/virtualenv/bin/activate
$ pip install -r backend/virtualenv/requirements.txt
```

This installs, in particular, numpy and pandas for the virtualenv. You might need to install missing dependencies for numpy and pandas. Run
```shell
$ python
>>> import pandas
```
to see if pandas (and its dependency, numpy) can be imported. If not, you likely have to install libatlas-base-dev (on Debian):
```shell
$ sudo apt-get install libatlas-base-dev
```

After these steps, we are ready to set up the database and get everything up and running. Copy ```config/config.ini.sample``` to ```config/config.ini``` and edit the latter. Enter the name of the database and the credentials of your MySQL user. Different data can be entered for the shoppinglist tables if you want to share the shoppinglist with another instance of GetOrganized (to coordinate your shopping e.g. with your flatmates or significant other.)

Do not forget to create the database you entered and to grant all privileges on it to the user specified in ```config/config.ini```.

To set up GetOrganized, activate the virtualenv and start the setup script:
```shell
$ source backend/virtualenv/bin/activate
$ ./build/setup.py
```

For GetOrganized to automatically generate charts upon entering new data, we must change the owner of the folder ```generated``` to the user of your server. On Debian, this is usually ```www-data```:
```shell
$ sudo chown -R www-data:www-data generated
```

GetOrganized should now be ready to go.

If you want it to update the generated charts every night, set up a cron job. For this, run
```shell
$ sudo crontab -e
```
and add the following line to the crontab (replacing ```yourwwwroot``` with the root of this repository):
```
0 0 * * * sudo -u www-data /yourwwwroot/backend/virtualenv/bin/python /yourwwwroot/build/generate_static_content.py
```
This will make the user www-data run the python instance from the virtualenv to update the charts every day at midnight. 
