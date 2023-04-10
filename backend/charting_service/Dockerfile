FROM python:3.7-slim
# Note: A newer python version seems to require also updating the pip package
# versions in requirements.txt - cannot get the current versions to work even
# with python:3.8

WORKDIR /usr/src/app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
