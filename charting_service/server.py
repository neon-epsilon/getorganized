from concurrent.futures import ProcessPoolExecutor
from contextlib import asynccontextmanager
from enum import Enum
from fastapi import FastAPI
from rocketry import Rocketry
from rocketry.conds import daily
from typing import Union
import asyncio
import charts
import config

class ChartType(str, Enum):
    calories = "calories"
    hoursofwork = "hoursofwork"
    spendings = "spendings"

# Use a process pool to generate charts in the background.
chart_generation_executor = ProcessPoolExecutor()

# We use rocketry to re-generate the charts at midnight.
chart_generation_scheduler = Rocketry(execution="async", timezone=config.timezone)

@chart_generation_scheduler.task(daily.at("00:00"))
def generate_all_charts():
    chart_generation_executor.submit(charts.generate_calories_charts, None)
    chart_generation_executor.submit(charts.generate_hoursofwork_charts, None)
    chart_generation_executor.submit(charts.generate_spendings_charts, None)

# Define what to do at server startup and shutdown
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Server startup
    generate_all_charts()
    asyncio.create_task(chart_generation_scheduler.serve())
    yield
    # Server shutdown
    chart_generation_scheduler.session.shutdown()
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
