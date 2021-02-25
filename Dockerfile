FROM ubuntu:20.04

RUN apt-get update && apt-get -y upgrade && apt-get install -y  nano \
    apt-utils \
    python3 \
    python3-pip \
    net-tools \
    libpq-dev \
&& apt-get clean

EXPOSE 8080
COPY airflow.cfg /root/airflow/airflow.cfg
WORKDIR /opt
COPY airflow_env_export.py /airflow_env_export.py
COPY requirements.txt /requirements.txt
RUN python3 -m pip install -r /requirements.txt
RUN export AIRFLOW_HOME='/opt/airflow'
RUN python3 /airflow_env_export.py
RUN python3 -m pip install --upgrade pip
RUN python3 -m pip install apache-airflow[postgres]

COPY airflow.cfg /airflow/airflow.cfg

COPY bootstrap.sh /bootstrap.sh
COPY webserver.sh /webserver.sh
