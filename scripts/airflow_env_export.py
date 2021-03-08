import os
from cryptography.fernet import Fernet

os.environ["AIRFLOW_HOME"] = "/root/airflow"

fernet = Fernet.generate_key().decode()
os.environ["AIRFLOW__CORE__FERNET_KEY"] = fernet

webserver_secret = Fernet.generate_key().decode()
os.environ["AIRFLOW__WEBSERVER__SECRET_KEY"] = webserver_secret
