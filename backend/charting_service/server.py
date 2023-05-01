from fastapi import FastAPI
from typing import Union
from enum import Enum
import asyncio

async def run(cmd):
    proc = await asyncio.create_subprocess_shell(
        cmd,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE)

    await proc.wait()

    if proc.returncode != 0:
        raise ChildProcessError(f"Child process '{cmd}' terminated with status code {proc.returncode}.")

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
async def generate_chart_automatic_timestamp(chart_type: ChartType):
    await generate_chart(chart_type, None)

@app.post("/{chart_type}/{timestamp}")
async def generate_chart_set_timestamp(chart_type: ChartType, timestamp: str):
    await generate_chart(chart_type, timestamp)

@app.post("/")
async def generate_all_charts_automatic_timestamp():
    await generate_all_charts(None)

@app.post("/{timestamp}")
async def generate_all_charts_set_timestamp(timestamp: str):
    await generate_all_charts(timestamp)
