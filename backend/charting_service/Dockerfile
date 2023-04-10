FROM python:3.8-slim
# Note: A newer python version seems to require also updating the pip package
# versions in requirements.txt.

WORKDIR /usr/src/app

# requirements for numpy
RUN apt update && apt install -y gcc g++

RUN pip install --no-cache-dir --upgrade pip
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
