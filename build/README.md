# Building GetOrganized #

## Prerequisites

You need a working MySQL Database.

If you want to spin up a development database in Docker, run
```bash
$ ./build/run_dev_database.sh
```
Clone the repository and check out the deploy branch. Make sure the www root of your server is the root of this repository. In the configuration of your server, disallow access to the folders `config` and `build`. (`config` will contain access details for your database which should not be visible from the outside for obvious security reasons.)

## Database setup

Copy `config/config.ini.sample` to `config/config.ini` and edit the latter. Enter the name of the database and the credentials of your MySQL user. Different data can be entered for the shoppinglist tables if you want to share the shoppinglist with another instance of GetOrganized (to coordinate your shopping e.g. with your flatmates or significant other.)

Grant all privileges on the database to the user specified in `config/config.ini`.

In a first time setup of GetOrganized, set up the database using (**Warning: if your database already exists, this will drop it**):
```bash
$ ./build/init_database.sh
```
This will create the necessary tables and populate them where necessary.

## Set up the charting service

To create the necessary Docker containers, run
```bash
$ ./build/build_containers.sh
```
Now the charting service can be started via:
```bash
$ docker compose up -d
```

## Automatic rebuilding of charts

If you want it to update the generated charts every night, set up a cron job. For this, run
```bash
$ sudo crontab -e
```
and add the following line to the crontab (replacing `yourwwwroot` with the root of this repository):
```
0 0 * * * sudo -u www-data /yourwwwroot/backend/generate_all_outputs.sh
```
This will make the user www-data run the python instance from the virtualenv to update the charts every day at midnight. 
