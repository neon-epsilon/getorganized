from typing import Union
import pathlib
import pymysql

from charts import calories
from charts import spendings
from charts.generation import generate_charts
from charts.amountsource import CaloriesAmountSource, HoursOfWorkAmountSource, SpendingsAmountSource
import config

def generate_calories_charts(output_timestamp: Union[str, None]):
    con = pymysql.connect(host=config.db_host,user=config.db_user,passwd=config.db_password,db=config.db_name)
    calories_amount_source = CaloriesAmountSource(con)

    output_dir = pathlib.Path.cwd() / 'generated/calories'
    calories.generate_charts(output_dir, calories_amount_source, output_timestamp)

    con.close()

def generate_hoursofwork_charts(output_timestamp: Union[str, None]):
    con = pymysql.connect(host=config.db_host,user=config.db_user,passwd=config.db_password,db=config.db_name)
    hoursofwork_amount_source = HoursOfWorkAmountSource(con)

    output_dir = pathlib.Path.cwd() / 'generated/hoursofwork'
    generate_charts(output_dir, hoursofwork_amount_source, output_timestamp, only_monday_to_friday=True)

    con.close()

def generate_spendings_charts(output_timestamp: Union[str, None]):
    con = pymysql.connect(host=config.db_host,user=config.db_user,passwd=config.db_password,db=config.db_name)
    spendings_amount_source = SpendingsAmountSource(con)

    output_dir = pathlib.Path.cwd() / 'generated/spendings'
    spendings.generate_charts(output_dir, spendings_amount_source, output_timestamp)

    con.close()
