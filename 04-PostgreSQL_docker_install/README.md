Домашнее задание  
### Установка и настройка PostgteSQL в контейнере Docker  

Цель:
установить PostgreSQL в Docker контейнере  
настроить контейнер для внешнего подключения  

<b>Имя проекта - postgres2021-2147483647</b>

• сделать в GCE инстанс
```console
gcloud compute instances create otus04...
```
• поставить на нем Docker Engine  
```console
[root@otus04 ~]# yum install docker -y
[root@otus04 ~]# systemctl enable --now docker
Created symlink from /etc/systemd/system/multi-user.target.wants/docker.service to /usr/lib/systemd/system/docker.service.
```
• сделать каталог /var/lib/postgres  
```console
[root@otus04 ~]# mkdir /var/lib/postgres
```
• развернуть контейнер с PostgreSQL 13 смонтировав в него /var/lib/postgres  
```console
[root@otus04 ~]# docker network create pg-net
cbcc79a47c90f80f4430bcdd011620bd5e051fe16aac3b8132730996f0ad35a3
[root@otus04 lib]# docker run --name pg-docker --network pg-net -e POSTGRES_PASSWORD=postgres -d -p 5432:5432 -v /var/lib/postgres:/var/lib/postgresql/data:z postgres:14
[root@otus04 lib]# docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                    NAMES
cce9ac8f6b04        postgres:14         "docker-entrypoint..."   7 seconds ago       Up 6 seconds        0.0.0.0:5432->5432/tcp   pg-docke
```
• развернуть контейнер с клиентом postgres  
```console
[root@otus04 lib]# docker run -it --rm --network pg-net --name pg-client postgres:14 psql -h pg-docker -U postgres
Password for user postgres: 
psql (14.0 (Debian 14.0-1.pgdg110+1))
Type "help" for help.

postgres=#
```
• подключится из контейнера с клиентом к контейнеру с сервером и сделать таблицу с парой строк  
```console
postgres=# create database task04;
CREATE DATABASE
postgres=# \c task04 
You are now connected to database "task04" as user "postgres".
postgres=# create table task04(k serial, v varchar);
CREATE TABLE
task04=# create table task04(k serial, v varchar);
CREATE TABLE
task04=# insert into task04 (v) values ('a'), ('b'), ('c');
INSERT 0 3
task04=# select * from task04;
 k | v 
---+---
 1 | a
 2 | b
 3 | c
(3 rows)
```
• подключится к контейнеру с сервером с ноутбука/компьютера извне инстансов GCP  
```console
gcloud compute --project=... firewall-rules create pg-port --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:5432 --source-ranges=0.0.0.0/0

alan $psql -h 35.202.33.70 -U postgres task04
Password for user postgres: 
psql (13.4, server 14.0 (Debian 14.0-1.pgdg110+1))
WARNING: psql major version 13, server major version 14.
         Some psql features might not work.
Type "help" for help.

task04=# \conninfo 
You are connected to database "task04" as user "postgres" on host "35.202.33.70" at port "5432".
```
• удалить контейнер с сервером  
```console
[root@otus04 postgres]# docker stop pg-docker
pg-docker
[root@otus04 postgres]# docker rm pg-docker
pg-docker
```
• создать его заново  
```console
[root@otus04 ~]# docker run --name pg-docker --network pg-net -e POSTGRES_PASSWORD=postgres -d -p 5432:5432 -v /var/lib/postgres:/var/lib/postgresql/data:z postgres:14
32e40fec17bf7931498efacc634ef97b6476b5005e7ce466cf2c73a3376cad39
```
• подключится снова из контейнера с клиентом к контейнеру с сервером  
```console
[root@otus04 ~]# docker run -it --rm --network pg-net --name pg-client postgres:14 psql -h pg-docker -U postgres
Password for user postgres: 
psql (14.0 (Debian 14.0-1.pgdg110+1))
Type "help" for help.

postgres=#
```
• проверить, что данные остались на месте  
```console
postgres=# \c task04 
You are now connected to database "task04" as user "postgres".
task04=# select * from task04;
 k | v 
---+---
 1 | a
 2 | b
 3 | c
(3 rows)
```
