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
testdb=# create table t1 (c1 int);
CREATE TABLE
```
7 вставьте строку со значением c1=1
```console
testdb=# insert into t1 values (1);
INSERT 0 1
```
8 создайте новую роль readonly
```console
testdb=# create role readonly;
CREATE ROLE
```
9 дайте новой роли право на подключение к базе данных testdb
```console
testdb=# grant connect on database testdb to readonly;
GRANT
```
10 дайте новой роли право на использование схемы testnm
```console
testdb=# grant usage on schema testnm to readonly;
GRANT
```
11 дайте новой роли право на select для всех таблиц схемы testnm
```console
testdb=# grant select on all tables in schema testnm to readonly;
GRANT
```
12 создайте пользователя testread с паролем test123
```console
testdb=# create user testread with password 'test123';
CREATE ROLE
```
13 дайте роль readonly пользователю testread
```console
testdb=# grant readonly to testread;
GRANT ROLE
```
14 зайдите под пользователем testread в базу данных testdb
```console
testdb=# \c 'user=testread dbname=testdb'
You are now connected to database "testdb" as user "testread".
```
15 сделайте select * from t1;
```console
testdb=> select * from t1;
ERROR:  permission denied for table t1
```
16 получилось? (могло если вы делали сами не по шпаргалке и не упустили один существенный момент про который позже)  
<b>Нет.</b>  
17 напишите что именно произошло в тексте домашнего задания  
<b>У пользователя testread нет прав на чтение таблицы t1.</b>  
18 у вас есть идеи почему? ведь права то дали?  
<b>Права были выданы на select всех таблиц в схеме testnm. Таблица t1 находится в схеме public, владелец postgres.</b>  
19 посмотрите на список таблиц
```console
testdb=> \dt
        List of relations
 Schema | Name | Type  |  Owner   
--------+------+-------+----------
 public | t1   | table | postgres
(1 row)
```
20 подсказка в шпаргалке под пунктом 20  
21 а почему так получилось с таблицей (если делали сами и без шпаргалки то может у вас все нормально)  
<b>В переменой search_path по умолчанию значение '"$user", public'. Схемы postgres не существует, таблица создалась в public.</b>  
22 вернитесь в базу данных testdb под пользователем postgres
```console
testdb=> \c 'user=postgres dbname=testdb'
You are now connected to database "testdb" as user "postgres".
```
23 удалите таблицу t1
```console
testdb=# drop table t1;
DROP TABLE
```
24 создайте ее заново но уже с явным указанием имени схемы testnm
```console
testdb=# create table testnm.t1 (c1 int);
CREATE TABLE
```
25 вставьте строку со значением c1=1
```console
testdb=# insert into testnm.t1 values (1);
INSERT 0 1
```
26 зайдите под пользователем testread в базу данных testdb
```console
testdb=# \c 'user=testread dbname=testdb'
You are now connected to database "testdb" as user "testread".
```
27 сделайте select * from testnm.t1;
```console
testdb=> select * from testnm.t1;
ERROR:  permission denied for table t1
```
28 получилось?  
<b>Нет.</b>  
29 есть идеи почему? если нет - смотрите шпаргалку  
<b>Права на select из всех таблиц схемы testnm были выданы до создание таблицы testnm.t1</b>  
30 как сделать так чтобы такое больше не повторялось? если нет идей - смотрите шпаргалку  
```console
testdb=> \c 'user=postgres dbname=testdb'
You are now connected to database "testdb" as user "postgres".
testdb=# alter default privileges in schema testnm grant select on tables to readonly;
ALTER DEFAULT PRIVILEGES
```
31 сделайте select * from testnm.t1;
```console
testdb=> select * from testnm.t1;
ERROR:  permission denied for table t1
```
32 получилось?  
<b>Нет.</b>  
33 есть идеи почему? если нет - смотрите шпаргалку  
<b>Привилегии по умолчанию (select) будут выданы на вновь создаваемые таблицы. На существующую таблицу t1 это не повлияло. Необходимо довыдать права на таблицу t1:</b>  
```console
testdb=> \c 'user=postgres dbname=testdb'
You are now connected to database "testdb" as user "postgres".
testdb=# grant select on all tables in schema testnm to readonly;
GRANT
```
31 сделайте select * from testnm.t1;
```console
testdb=# \c 'user=testread dbname=testdb'
You are now connected to database "testdb" as user "testread".
testdb=> select * from testnm.t1;
 c1 
----
  1
(1 row)

```
32 получилось?  
<b>Да.</b>
33 ура!  
34 теперь попробуйте выполнить команду create table t2(c1 integer); insert into t2 values (2);
```console
testdb=> create table t2(c1 integer); insert into t2 values (2);
CREATE TABLE
INSERT 0 1
```
35 а как так? нам же никто прав на создание таблиц и insert в них под ролью readonly?  
<b>Таблица t2 создалась в схеме public, для которой по умолчанию выданы права для специальной "роли" PUBLIC.</b>  
36 есть идеи как убрать эти права? если нет - смотрите шпаргалку  
```console
testdb=> \c 'user=postgres dbname=testdb'
You are now connected to database "testdb" as user "postgres".
testdb=# revoke all on schema public from PUBLIC;
REVOKE
```
37 если вы справились сами то расскажите что сделали и почему, если смотрели шпаргалку - объясните что сделали и почему выполнив указанные в ней команды  
<b>Лишил всех выданных прав на схему public "роль" PUBLIC.</b>  
38 теперь попробуйте выполнить команду create table t3(c1 integer); insert into t2 values (2);
```console
testdb=> create table t3(c1 integer); insert into t2 values (2);
ERROR:  no schema has been selected to create in
LINE 1: create table t3(c1 integer);
                     ^
ERROR:  relation "t2" does not exist
LINE 1: insert into t2 values (2);

testdb=> create table public.t3(c1 integer); insert into public.t2 values (2);
ERROR:  permission denied for schema public
LINE 1: create table public.t3(c1 integer);
                     ^
ERROR:  permission denied for schema public
LINE 1: insert into public.t2 values (2);
```
39 расскажите что получилось и почему  
<b>Все роли системы входят в "роль" PUBLIC, у которой теперь нет никаких прав на схему public в БД testdb.</b>  
