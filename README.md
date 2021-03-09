# Setting up production grade Airflow with postgresql backend

## How to run airflow-on-kubernetes
- Inside the project folder, execute `sudo docker-compose up` to create and spin up all services.
- To stop the services without removing any data, execute `sudo docker-compose stop`.
- To restart the services, execute `sudo docker-compose start`.
- To remove all networks, services and containers related to the project, execute `sudo docker-compose down`.

## Notes on airflow.cfg
The default config contains three rows which need editing before it can successfully serve as a basis config for Airflow.
- The `fernet_key` under `[core]` should be commented out, and instead one should set the `AIRFLOW__CORE__FERNET_KEY` environment varible.
- The `secret_key` under `[webserver]` should be commented out, and instead one should set `AIRFLOW__WEBSERVER__SECRET_KEY` environment variable.
- The `sql_alchemy_conn` under `[core]` should be set according to the postgresql section below.

## Postgresql image & service
The postgres image is the official postgres supplied image. In the `docker-compose.yaml` we define the postgres service
using three environment variables
```
- POSTGRES_USER=airflow
- POSTGRES_PASSWORD=airflow
- POSTGRES_DB=airflow
```
we also bind the port `5432:5432` to ensure proper TCP/IP communication between the containers and the host.
NOTE: If you are running a local postgresql server, port 5432 is most likely occupied, and you have to either use another
port, or kill your local postgresql process.

For the `sql_alchemy_conn`, we use the following connection string:

```
sql_alchemy_conn = postgresql+psycopg2://airflow:airflow@postgres/airflow
```
NOTE: we do not need to supply an IP and port, since `docker-compose` creates a docker network for all services
shared between the containers, and we can hence use the postgres service name as a substitute for ip and port.

## Webserver service
The webserver needs to execute two tasks on boot: `airflow db init` and `airflow webserver`. To accomplish this, we
define in the webserver service a bash command:

```
command: bash -c "airflow db init && airflow webserver"
```
The volumes defined in the service ensure that we can supply DAGs and plugins into the webserver container from our
host.

## Scheduler service
The scheduler service is the last to execute, and contains a simple `airflow scheduler` command.

## Create user for webserver
To create an user with "Admin" role and username equals to "admin", bash into the webserver container using
`sudo docker exec -it <container_id> bash` and then inside the container run:

```
airflow users create \
      --username admin \
      --firstname FIRST_NAME \
      --lastname LAST_NAME \
      --role Admin \
      --email admin@example.org
```
type the password twice before the user is created.

## Project files explained

### config/airflow.cfg
The airflow config file which will be copied to and used by all containers. All airflow configurations should be done here.

### scripts/airflow_env_export.py
Python script which safely generates the airflow fernet_key and secret_key and exports them as environment variables.
Relies on the python library `cryptography`.

### docker-compose.yaml
Holds the definition of the related airflow services. Serves as basis for `sudo docker-compose` commands.

### Dockerfile
Contains the base image and additions needed to run airflow. Base image is a ubuntu 20.04 image, and we add libraries for
troubleshooting, postgres development, python, network troubleshooting and SSL certification. This file currently
contains redundant information, and a clean-up is needed.

### requirements.txt
Contains the following packages:
```
psycopg2     -> used for sqlalchemy and postgresql connections
cryptography -> used for generating fernet_key and secret_key supplied to airflow
```

## Troubleshooting & Docker Administration

### Find ip address of docker container
`docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' <container_name_or_id>`

### Delete dangling Docker images
`sudo docker rmi $(sudo docker images -f "dangling=true" -q)`
