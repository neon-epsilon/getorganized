from datetime import date
from typing import Union
import pathlib
import pymysql

from charts.generation import generate_charts
from charts.amountsource import CaloriesAmountSource, HoursOfWorkAmountSource, SpendingsAmountSource
import config

def generate_calories_charts(day: date, output_timestamp: Union[str, None]):
    con = pymysql.connect(host=config.db_host,user=config.db_user,passwd=config.db_password,db=config.db_name)
    calories_amount_source = CaloriesAmountSource(con)

    output_dir = pathlib.Path.cwd() / 'generated/calories'

    generate_charts(output_dir, calories_amount_source, day, output_timestamp)

    con.close()

def generate_hoursofwork_charts(day: date, output_timestamp: Union[str, None]):
    con = pymysql.connect(host=config.db_host,user=config.db_user,passwd=config.db_password,db=config.db_name)
    hoursofwork_amount_source = HoursOfWorkAmountSource(con)

    output_dir = pathlib.Path.cwd() / 'generated/hoursofwork'

    generate_charts(output_dir, hoursofwork_amount_source, day, output_timestamp, only_monday_to_friday=True)

    con.close()

def generate_spendings_charts(day: date, output_timestamp: Union[str, None]):
    con = pymysql.connect(host=config.db_host,user=config.db_user,passwd=config.db_password,db=config.db_name)
    spendings_amount_source = SpendingsAmountSource(con)

    output_dir = pathlib.Path.cwd() / 'generated/spendings'

    generate_charts(output_dir, spendings_amount_source, day, output_timestamp)

    con.close()
