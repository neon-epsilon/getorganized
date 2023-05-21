# This needs to be built from the root of the repository to correctly access
# the config.ini, i.e.
# $ docker build -f backend/charting_service/Dockerfile .

# Use buster, not bullseye, because the latter has a bug when running
# `apt-get update` on a Docker host that runs Raspbian Buster. See
# https://osmocom.org/issues/5453
# Probably solvable by upgrading Raspbian Buster to Bullseye on the host
# machine.
FROM python:3.9-slim-buster
# Note: building on Raspbian is very slow because many wheels need to be built
# from source. Make sure to have enough memory and swap. (Tested on RaspberryPi
# 3 with 1GB memory and 1GB swap.)
# This could be sped up by using https://www.piwheels.org/. May require
# upgrading the base image to Bullseye, after all, since this seems to be a
# requirement for the Python 3.9 wheels.

WORKDIR /usr/app

# requirements for numpy and Pillow
# make, zlib and libjpeg only needed for Raspbian/ARM
RUN apt-get update && apt-get install -y gcc g++ make zlib1g-dev libjpeg-dev

# Install requirements first to avoid re-building whenever the rest of the code
# changes.
COPY backend/charting_service/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY backend/charting_service .

ENTRYPOINT ["uvicorn", "--host", "0.0.0.0", "server:app"]
