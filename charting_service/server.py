from concurrent.futures import ProcessPoolExecutor
from contextlib import asynccontextmanager
from enum import Enum
from fastapi import FastAPI
from typing import Union

import charts

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
            chart_generation_executor.submit(charts.generate_calories_charts, timestamp)
        case ChartType.hoursofwork:
            chart_generation_executor.submit(charts.generate_hoursofwork_charts, timestamp)
        case ChartType.spendings:
            chart_generation_executor.submit(charts.generate_spendings_charts, timestamp)
