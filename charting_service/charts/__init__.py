from charts import calories
from charts import hoursofwork
from charts import spendings

def generate_calories_charts(timestamp):
    calories.generate_charts(timestamp)

def generate_hoursofwork_charts(timestamp):
    hoursofwork.generate_charts(timestamp)

def generate_spendings_charts(timestamp):
    spendings.generate_charts(timestamp)
