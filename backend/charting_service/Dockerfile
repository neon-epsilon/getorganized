# This needs to be built from the root of the repository to correctly access
# the config.ini, i.e.
# $ docker build -f backend/charting_service/Dockerfile .

# Use buster, not bullseye, because the latter has a bug when running
# `apt-get update` on a Docker host that runs Raspbian Buster. See
# https://osmocom.org/issues/5453
# Probably solvable by upgrading Raspbian Buster to Bullseye.
FROM python:3.8-slim-buster
# Note: A newer python version seems to require also updating the pip package
# versions in requirements.txt.

WORKDIR /usr/app

# requirements for numpy
RUN apt-get update && apt-get install -y gcc g++

# Install requirements first to avoid re-building whenever the rest of the code
# changes.
COPY backend/charting_service/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY backend/charting_service .
COPY config/config.ini config/config.py .

CMD ["./generate_all_outputs.sh"]
