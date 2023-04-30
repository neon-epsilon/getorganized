# This needs to be built from the root of the repository to correctly access
# the config.ini, i.e.
# $ docker build -f build/database_setup/Dockerfile .

FROM python:3.8-slim
# Note: A newer python version seems to require also updating the pip package
# versions in requirements.txt.

WORKDIR /usr/src/app

RUN pip install --no-cache-dir --upgrade pip
COPY build/database_setup/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY build/database_setup .
COPY config/config.ini config/config.py .

ENTRYPOINT ["python", "setup.py"]
