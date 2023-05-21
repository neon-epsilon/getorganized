from fastapi import FastAPI
from typing import Union
from enum import Enum
import asyncio

async def run(cmd):
    # Running chart generation as subprocess is bad, also makes DoS attacks
    # very easy without limiting the number of subprocesses that can be created
    # this way.
    # TODO Refactor such that chart generation scripts are directly called
    # (potentially using a work queue so we do not have to wait so long for a
    # response from the server).
    await asyncio.create_subprocess_shell(cmd)

class ChartType(str, Enum):
    calories = "calories"
    hoursofwork = "hoursofwork"
    spendings = "spendings"

app = FastAPI()

@app.post("/{chart_type}/")
async def generate_chart_endpoint(chart_type: ChartType, timestamp: Union[str, None] = None):
    if timestamp is None:
        timestamp = ""

    await run(f"python generate_{chart_type.value}_output.py {timestamp}")
