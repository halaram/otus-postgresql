###Репликация

Цель:
реализовать свой миникластер на 3 ВМ.

<b>Имя проекта - postgres2021-2147483647</b>

- ВМ1 otus11-1
- ВМ2 otus11-2
- ВМ3 otus11-3
- ВМ4 otus11-4

>На 1 ВМ создаем таблицы test1 для записи, test2 для запросов на чтение.
```sql
postgres=# alter system set wal_level = 'logical';
ALTER SYSTEM
```
```console
-bash-4.2$ /usr/pgsql-14/bin/pg_ctl -D /var/lib/pgsql/14/data restart
```
```sql
postgres=# create database repl;
CREATE DATABASE
postgres=# \c repl
You are now connected to database "repl" as user "postgres".
repl=# create table test1 (k1 int, v1 varchar);
CREATE TABLE
repl=# insert into test1 select i, md5(i::varchar) from generate_series(0, 99) as s(i);
INSERT 0 100
```
>Создаем публикацию таблицы test1 и подписываемся на публикацию таблицы test2 с ВМ №2.
```sql
repl=# create publication publ_test1 for table test1;
CREATE PUBLICATION
repl=# \dRp+
                           Publication publ_test1
  Owner   | All tables | Inserts | Updates | Deletes | Truncates | Via root 
----------+------------+---------+---------+---------+-----------+----------
 postgres | f          | t       | t       | t       | t         | f
Tables:
    "public.test1"

repl=# create table test2 (k2 int, v2 varchar);
CREATE TABLE

repl=# create subscription subs_test2 connection 'host=otus11-2 user=postgres password=postgres dbname=repl' publication publ_test2 with (copy_data = true);
NOTICE:  created replication slot "subs_test2" on publisher
CREATE SUBSCRIPTION

repl=# \dRs+
                                                                List of subscriptions
    Name    |  Owner   | Enabled | Publication  | Binary | Streaming | Synchronous commit |                         Conninfo                          
------------+----------+---------+--------------+--------+-----------+--------------------+-----------------------------------------------------------
 subs_test2 | postgres | t       | {publ_test2} | f      | f         | off                | host=otus11-2 user=postgres password=postgres dbname=repl
```
>На 2 ВМ создаем таблицы test2 для записи, test1 для запросов на чтение.
```sql
postgres=# alter system set wal_level = 'logical';
ALTER SYSTEM
```
```console
-bash-4.2$ /usr/pgsql-14/bin/pg_ctl -D /var/lib/pgsql/14/data restart
```
```sql
postgres=# create database repl;
CREATE DATABASE
postgres=# \c repl
You are now connected to database "repl" as user "postgres".
repl=# create table test2 (k2 int, v2 varchar);
CREATE TABLE
```
>Создаем публикацию таблицы test2 и подписываемся на публикацию таблицы test1 с ВМ №1.
```sql
repl=# create publication publ_test2 for table test2;
CREATE PUBLICATION

repl=# \dRp+
                           Publication publ_test2
  Owner   | All tables | Inserts | Updates | Deletes | Truncates | Via root 
----------+------------+---------+---------+---------+-----------+----------
 postgres | f          | t       | t       | t       | t         | f
Tables:
    "public.test2"

repl=# create table test1 (k1 int, v1 varchar);
CREATE TABLE

repl=# create subscription subs_test1 connection 'host=otus11-1 user=postgres password=postgres dbname=repl' publication publ_test1 with (copy_data = true);
NOTICE:  created replication slot "subs_test1" on publisher
CREATE SUBSCRIPTION

repl=# \dRs+
                                                                List of subscriptions
    Name    |  Owner   | Enabled | Publication  | Binary | Streaming | Synchronous commit |                         Conninfo                          
------------+----------+---------+--------------+--------+-----------+--------------------+-----------------------------------------------------------
 subs_test1 | postgres | t       | {publ_test1} | f      | f         | off                | host=otus11-1 user=postgres password=postgres dbname=repl
```
>3 ВМ использовать как реплику для чтения и бэкапов (подписаться на таблицы из ВМ №1 и №2 ). Небольшое описание, того, что получилось.

>реализовать горячее реплицирование для высокой доступности на 4ВМ. Источником должна выступать ВМ №3. Написать с какими проблемами столкнулись.
