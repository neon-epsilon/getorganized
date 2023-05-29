from fastapi import FastAPI
from typing import Union
from enum import Enum
import asyncio

import generate_calories_output as calories
import generate_hoursofwork_output as hoursofwork
import generate_spendings_output as spendings

class ChartType(str, Enum):
    calories = "calories"
    hoursofwork = "hoursofwork"
    spendings = "spendings"

app = FastAPI()

@app.post("/{chart_type}/")
def generate_chart_endpoint(chart_type: ChartType, timestamp: Union[str, None] = None):
    if timestamp is None:
        timestamp = ""

    match chart_type:
        case ChartType.calories:
            calories.generate_chart(timestamp)
        case ChartType.hoursofwork:
            hoursofwork.generate_chart(timestamp)
        case ChartType.spendings:
            spendings.generate_chart(timestamp)
