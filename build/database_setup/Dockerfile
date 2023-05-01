# This needs to be built from the root of the repository to correctly access
# the config.ini, i.e.
# $ docker build -f build/database_setup/Dockerfile .

# Use buster, not bullseye, because the latter has a bug when running
# `apt-get update` on a Docker host that runs Raspbian Buster. See
# https://osmocom.org/issues/5453
# Probably solvable by upgrading Raspbian Buster to Bullseye.
FROM python:3.8-slim-buster

WORKDIR /usr/src/app

COPY build/database_setup/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY build/database_setup .
COPY config/config.ini config/config.py .

ENTRYPOINT ["python", "setup.py"]
