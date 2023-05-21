from fastapi import FastAPI
from typing import Union
from enum import Enum
import asyncio

async def run(cmd):
    await asyncio.create_subprocess_shell(cmd)

class ChartType(str, Enum):
    calories = "calories"
    hoursofwork = "hoursofwork"
    spendings = "spendings"

async def generate_chart(chart_type: ChartType, timestamp: Union[str, None] = None):
    if timestamp is None:
        timestamp = ""

    await run(f"python generate_{chart_type.value}_output.py {timestamp}")

async def generate_all_charts(timestamp: Union[str, None] = None):
    for chart_type in ChartType:
        await generate_chart(chart_type, timestamp)

app = FastAPI()

@app.post("/{chart_type}/")
async def generate_chart_endpoint(chart_type: ChartType, timestamp: Union[str, None] = None):
    await generate_chart(chart_type, timestamp)

@app.post("/")
async def generate_all_charts_endpoint(timestamp: Union[str, None] = None):
    await generate_all_charts(timestamp)
