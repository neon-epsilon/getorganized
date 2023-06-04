import pathlib
from typing import Union
from charts import calories
from charts import hoursofwork
from charts import spendings

def generate_calories_charts(timestamp: Union[str, None]):
    output_dir = pathlib.Path.cwd() / 'generated/calories'
    calories.generate_charts(output_dir, timestamp)

def generate_hoursofwork_charts(timestamp: Union[str, None]):
    output_dir = pathlib.Path.cwd() / 'generated/hoursofwork'
    hoursofwork.generate_charts(output_dir, timestamp)

def generate_spendings_charts(timestamp: Union[str, None]):
    output_dir = pathlib.Path.cwd() / 'generated/spendings'
    spendings.generate_charts(output_dir, timestamp)
