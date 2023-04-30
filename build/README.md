# Building GetOrganized #

This application assumes you have a working PHP server with MySQL running on a linux machine.

_Note:_ For historical reasons, the setup process is still quite cumbersome and has many manual steps. This can be in the future improved by containerizing the entire application after splitting it up into independent services.

Clone the repository and check out the deploy branch. Make sure the www root of your server is the root of this repository. In the configuration of your server, disallow access to the folders `config` and `build`. (`config` will contain access details for your database which should not be visible from the outside for obvious security reasons.)

Now we are going to set up the database and get everything up and running. Copy `config/config.ini.sample` to `config/config.ini` and edit the latter. Enter the name of the database and the credentials of your MySQL user. Different data can be entered for the shoppinglist tables if you want to share the shoppinglist with another instance of GetOrganized (to coordinate your shopping e.g. with your flatmates or significant other.)
Grant all privileges on the database to the user specified in `config/config.ini`.

To create the necessary Docker containers, run
```bash
$ ./build/build_containers.sh
```
In a first time setup of GetOrganized, set up the database using:
```bash
$ docker run -it --rm database_setup
```
This will create the necessary tables and populate them where necessary.

For GetOrganized to automatically generate charts upon entering new data, we must change the owner of the folder `generated` to the user of your server. On Debian, this is usually `www-data`:
```bash
$ sudo chown -R www-data:www-data generated
```
Additionally, the user of the server must be able to run docker containers.

GetOrganized should now be ready to go.

If you want it to update the generated charts every night, set up a cron job. For this, run
```bash
$ sudo crontab -e
```
and add the following line to the crontab (replacing `yourwwwroot` with the root of this repository):
```
0 0 * * * sudo -u www-data /yourwwwroot/backend/generate_all_outputs.sh
```
This will make the user www-data run the python instance from the virtualenv to update the charts every day at midnight. 
