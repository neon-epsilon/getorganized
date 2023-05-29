from concurrent.futures import ProcessPoolExecutor
from contextlib import asynccontextmanager
from enum import Enum
from fastapi import FastAPI
from typing import Union

import generate_calories_output as calories
import generate_hoursofwork_output as hoursofwork
import generate_spendings_output as spendings

class ChartType(str, Enum):
    calories = "calories"
    hoursofwork = "hoursofwork"
    spendings = "spendings"

chart_generation_executor = ProcessPoolExecutor()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Nothing specific to do on startup
    yield
    # Clean up
    chart_generation_executor.shutdown()

app = FastAPI(lifespan=lifespan)

@app.post("/{chart_type}/")
def generate_chart_endpoint(chart_type: ChartType, timestamp: Union[str, None] = None):
    match chart_type:
        case ChartType.calories:
            chart_generation_executor.submit(calories.generate_chart, timestamp)
        case ChartType.hoursofwork:
            chart_generation_executor.submit(hoursofwork.generate_chart, timestamp)
        case ChartType.spendings:
            chart_generation_executor.submit(spendings.generate_chart, timestamp)
