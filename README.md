Привет программисты 1С, с вами Низамов Илья. Сегодня я покажу, как установить сервер взаимодействия 1с в docker. Напишем конфиг dockerfile для сборки сервера взаимодействия 1С. Напишем конфиг docker compose для запуска нескольких сервисов.

В этой части мы вынесем в отдельный контейнер только PostgreSQL, а сервер взаимодействия 1С, вместе с elasticsearch и hazelcast будут работать в одном контейнере.

Создаем папку нашего проекта sv. Внутри ее создаем папки db, srv

В папке db создать sql файл init-cs-db.sql---

\c cs_db
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
\q

В папку srv скопировать файлы deb сервера взаимодействия.
Так же разместить там отредактированный скрипт ring

Создать в папке srv 2 скрипта

init.sh---

#!/bin/bash
set -e

sudo useradd cs_user
sudo mkdir -p /var/cs/cs_instance
sudo chown cs_user:cs_user /var/cs/cs_instance
sudo /opt/1C/1CE/x86_64/ring/ring cs instance create --dir /var/cs/cs_instance --owner cs_user
sudo /opt/1C/1CE/x86_64/ring/ring cs --instance cs_instance service create --username cs_user --java-home $JAVA_HOME --stopped

sudo useradd hc_user
sudo mkdir -p /var/cs/hc_instance
sudo chown hc_user:hc_user /var/cs/hc_instance
sudo /opt/1C/1CE/x86_64/ring/ring hazelcast instance create --dir /var/cs/hc_instance --owner hc_user
sudo /opt/1C/1CE/x86_64/ring/ring hazelcast --instance hc_instance service create --username hc_user --java-home $JAVA_HOME --stopped

sudo useradd elastic_user
sudo mkdir -p /var/cs/elastic_instance
sudo chown elastic_user:elastic_user /var/cs/elastic_instance
sudo /opt/1C/1CE/x86_64/ring/ring elasticsearch instance create --dir /var/cs/elastic_instance --owner elastic_user
sudo /opt/1C/1CE/x86_64/ring/ring elasticsearch --instance elastic_instance service create --username elastic_user --java-home $JAVA_HOME --stopped

sudo /opt/1C/1CE/x86_64/ring/ring cs --instance cs_instance jdbc set-params --url jdbc:postgresql://db:5432/cs_db?currentSchema=public
sudo /opt/1C/1CE/x86_64/ring/ring cs --instance cs_instance jdbc set-params --username postgres
sudo /opt/1C/1CE/x86_64/ring/ring cs --instance cs_instance jdbc set-params --password postgres
sudo /opt/1C/1CE/x86_64/ring/ring cs --instance cs_instance jdbc-privileged set-params --url jdbc:postgresql://db:5432/cs_db?currentSchema=public
sudo /opt/1C/1CE/x86_64/ring/ring cs --instance cs_instance jdbc-privileged set-params --username postgres
sudo /opt/1C/1CE/x86_64/ring/ring cs --instance cs_instance jdbc-privileged set-params --password postgres

sudo /opt/1C/1CE/x86_64/ring/ring cs --instance cs_instance websocket set-params --hostname cs
sudo /opt/1C/1CE/x86_64/ring/ring cs --instance cs_instance websocket set-params --port 8087

start.sh---
#!/bin/bash
set -e

sudo /opt/1C/1CE/x86_64/ring/ring hazelcast --instance hc_instance service restart
sudo /opt/1C/1CE/x86_64/ring/ring elasticsearch --instance elastic_instance service restart
sudo /opt/1C/1CE/x86_64/ring/ring cs --instance cs_instance service restart

echo "ALL START"
sh


Создаем Dockerfile для образа сервера взаимодействия 1С
В папке srv создать файл Dockerfile---

FROM ubuntu:21.04

RUN apt-get update && apt-get -y install sudo curl nano openjdk-8-jdk mc && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME /usr/lib/jvm/java-1.8.0-openjdk-amd64

WORKDIR /app

COPY . .

RUN sudo dpkg -i *.deb && rm -rf *.deb

COPY ring /opt/1C/1CE/x86_64/ring/

RUN chmod 777 *.sh && ./init.sh

В корне проекта создать docker-compose.yml---

version: "3.8"

services:
cs:
build: ./srv
stdin_open: true
tty: true
command: ./start.sh
restart: unless-stopped
ports:
- "8087:8087"
depends_on:
- db
db:
image: postgres:12-alpine
restart: always
environment:
- POSTGRES_DB=cs_db
- POSTGRES_USER=postgres
- POSTGRES_PASSWORD=postgres
ports:
- "5432:5432"
volumes:
- ./storage/postgres-data:/var/lib/postgresql/data
- ./db/init-cs-db.sql:/docker-entrypoint-initdb.d/init-cs-db.sql


Сборка сервера взаимодействия 1С в docker

docker-compose build 
docker-compose up

Подключаемся к запущенному контейнеру

docker exec -it sv_cs_1 sh

Первый раз выполняем команды инициализации базы данных и проверяем, что все поднялось.

sudo curl -Sf -X POST -H "Content-Type: application/json" -d "{ \"url\" : \"jdbc:postgresql://db:5432/cs_db\", \"username\" : \"postgres\", \"password\" : \"postgres\", \"enabled\" : true }" -u admin:admin http://localhost:8087/admin/bucket_server


sudo curl http://localhost:8087/rs/health
