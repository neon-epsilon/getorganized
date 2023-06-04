from typing import Union
from charts import calories
from charts import hoursofwork
from charts import spendings

def generate_calories_charts(timestamp: Union[str, None]):
    calories.generate_charts(timestamp)

def generate_hoursofwork_charts(timestamp: Union[str, None]):
    hoursofwork.generate_charts(timestamp)

def generate_spendings_charts(timestamp: Union[str, None]):
    spendings.generate_charts(timestamp)
