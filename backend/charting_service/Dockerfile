# This needs to be built from the root of the repository to correctly access
# the config.ini, i.e.
# $ docker build -f backend/charting_service/Dockerfile .

FROM python:3.8-slim
# Note: A newer python version seems to require also updating the pip package
# versions in requirements.txt.

WORKDIR /usr/app

# requirements for numpy
RUN apt update && apt install -y gcc g++

RUN pip install --no-cache-dir --upgrade pip
# Install requirements first to avoid re-building whenever the rest of the code
# changes.
COPY backend/charting_service/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY backend/charting_service .
COPY config/config.ini config/config.py .
