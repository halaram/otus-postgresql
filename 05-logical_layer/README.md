Домашнее задание
### Работа с базами данных, пользователями и правами

Цель:  
создание новой базы данных, схемы и таблицы  
создание роли для чтения данных из созданной схемы созданной базы данных  
создание роли для чтения и записи из созданной схемы созданной базы данных  

<b>Имя проекта - postgres2021-2147483647</b>

1 создайте новый кластер PostgresSQL 13 (на выбор - GCE, CloudSQL)
```console
gcloud compute instances create otus05...
[root@otus05 ~]# yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
[root@otus05 ~]# yum install -y postgresql14-server
[root@otus05 ~]# /usr/pgsql-14/bin/postgresql-14-setup initdb
[root@otus05 ~]# systemctl enable --now postgresql-14
```
2 зайдите в созданный кластер под пользователем postgres
```console
-bash-4.2$ psql 
psql (14.0)
Type "help" for help.

postgres=# \conninfo 
You are connected to database "postgres" as user "postgres" via socket in "/var/run/postgresql" at port "5432".
```
3 создайте новую базу данных testdb
```console
postgres=# create database testdb;
CREATE DATABASE
```
4 зайдите в созданную базу данных под пользователем postgres
```console
postgres=# \c testdb 
You are now connected to database "testdb" as user "postgres".
```
5 создайте новую схему testnm
```console
testdb=# create schema testnm;
CREATE SCHEMA
```
6 создайте новую таблицу t1 с одной колонкой c1 типа integer
```console
testdb=# create table testnm.t1 (c1 int);
CREATE TABLE
```
7 вставьте строку со значением c1=1
```console
testdb=# insert into testnm.t1 values (1);
INSERT 0 1
```
8 создайте новую роль readonly
```console
testdb=# create role readonly;
CREATE ROLE
```
9 дайте новой роли право на подключение к базе данных testdb
```console

```
10 дайте новой роли право на использование схемы testnm
```console
```
11 дайте новой роли право на select для всех таблиц схемы testnm
```console
```
12 создайте пользователя testread с паролем test123
```console
```
13 дайте роль readonly пользователю testread
```console
```
14 зайдите под пользователем testread в базу данных testdb
```console
```
15 сделайте select * from t1;
```console
```
16 получилось? (могло если вы делали сами не по шпаргалке и не упустили один существенный момент про который позже)  

17 напишите что именно произошло в тексте домашнего задания  

18 у вас есть идеи почему? ведь права то дали?  

19 посмотрите на список таблиц
```console
```
20 подсказка в шпаргалке под пунктом 20  
21 а почему так получилось с таблицей (если делали сами и без шпаргалки то может у вас все нормально)  
22 вернитесь в базу данных testdb под пользователем postgres
```console
```
23 удалите таблицу t1
```console
```
24 создайте ее заново но уже с явным указанием имени схемы testnm
```console
```
25 вставьте строку со значением c1=1
```console
```
26 зайдите под пользователем testread в базу данных testdb
```console
```
27 сделайте select * from testnm.t1;
```console
```
28 получилось?  
29 есть идеи почему? если нет - смотрите шпаргалку  
30 как сделать так чтобы такое больше не повторялось? если нет идей - смотрите шпаргалку  
31 сделайте select * from testnm.t1;
```console
```
32 получилось?  
33 есть идеи почему? если нет - смотрите шпаргалку  
31 сделайте select * from testnm.t1;
```console
```
32 получилось?  
33 ура!  
34 теперь попробуйте выполнить команду create table t2(c1 integer); insert into t2 values (2);
```console
```
35 а как так? нам же никто прав на создание таблиц и insert в них под ролью readonly?  
36 есть идеи как убрать эти права? если нет - смотрите шпаргалку  
37 если вы справились сами то расскажите что сделали и почему, если смотрели шпаргалку - объясните что сделали и почему выполнив указанные в ней команды  
38 теперь попробуйте выполнить команду create table t3(c1 integer); insert into t2 values (2);
```console
```
39 расскажите что получилось и почему  
