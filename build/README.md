# Building GetOrganized #

## Prerequisites

You need a working MySQL Database.

If you want to spin up a development database in Docker, run
```bash
$ ./build/run_dev_database.sh
```

## Database setup

Copy `config/config.ini.sample` to `config/config.ini` and edit the latter. Enter the name of the database and the credentials of your MySQL user. Different data can be entered for the shoppinglist tables if you want to share the shoppinglist with another instance of GetOrganized (to coordinate your shopping e.g. with your flatmates or significant other.)

Grant all privileges on the database to the user specified in `config/config.ini`.

In a first time setup of GetOrganized, set up the database using (**Warning: if your database already exists, this will drop it**):
```bash
$ ./build/init_database.sh
```
This will create the necessary tables and populate them where necessary.

## Build and run

To create the necessary Docker containers, run
```bash
$ ./build/build_containers.sh
```
Now start GetOrganized via:
```bash
$ docker compose up -d
```

## Automatic rebuilding of charts

If you want it to update the generated charts every night, set up a cron job. For this, run
```bash
$ sudo crontab -e
```
and add the following line to the crontab (replacing `$GetOrganizedDir` and `$SomeUser` accordingly):
```
0 0 * * * sudo -u $SomeUser $GetOrganizedDir/build/generate_all_outputs.sh
```
