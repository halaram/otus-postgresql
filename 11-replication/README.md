### Репликация

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

repl=# create table test1 (k1 serial primary key);
CREATE TABLE
repl=# insert into test1 select i from generate_series(0, 99) as s(i);
INSERT 0 100
repl=# create table test2 (k2 serial primary key);
CREATE TABLE
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

repl=# create table test2 (k2 serial primary key);
CREATE TABLE
repl=# insert into test2 select i from generate_series(0, 99) as s(i);
INSERT 0 100
repl=# create table test1 (k1 serial primary key);
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

repl=# create table test1 (k1 serial primary key);
CREATE TABLE
repl=# create table test2 (k2 serial primary key);
CREATE TABLE

repl=# create subscription subs_test1_3 connection 'host=otus11-1 user=postgres password=postgres dbname=repl' publication publ_test1 with (copy_data = true);
NOTICE:  created replication slot "subs_test1_3" on publisher
CREATE SUBSCRIPTION
repl=# create subscription subs_test2_3 connection 'host=otus11-2 user=postgres password=postgres dbname=repl' publication publ_test2 with (copy_data = true);
NOTICE:  created replication slot "subs_test2_3" on publisher
CREATE SUBSCRIPTION

repl=# \dRs+
                                                                 List of subscriptions
     Name     |  Owner   | Enabled | Publication  | Binary | Streaming | Synchronous commit |                         Conninfo                          
--------------+----------+---------+--------------+--------+-----------+--------------------+-----------------------------------------------------------
 subs_test1_3 | postgres | t       | {publ_test1} | f      | f         | off                | host=otus11-1 user=postgres password=postgres dbname=repl
 subs_test2_3 | postgres | t       | {publ_test2} | f      | f         | off                | host=otus11-2 user=postgres password=postgres dbname=repl
```
<b>На таблицы test1 ВМ1 и test2 ВМ2 две подписки. Можно посмотреть статус репликации:</b>
- ВМ1
```sql
postgres=# select application_name,client_addr, application_name, state, sync_state from pg_stat_replication;
 application_name | client_addr | application_name |   state   | sync_state 
------------------+-------------+------------------+-----------+------------
 subs_test1       | 10.128.0.10 | subs_test1       | streaming | async
 subs_test1_3     | 10.128.0.11 | subs_test1_3     | streaming | async
```
- ВМ2
```sql
postgres=# select application_name,client_addr, application_name, state, sync_state from pg_stat_replication;
 application_name | client_addr | application_name |   state   | sync_state 
------------------+-------------+------------------+-----------+------------
 subs_test2       | 10.128.0.9  | subs_test2       | streaming | async
 subs_test2_3     | 10.128.0.11 | subs_test2_3     | streaming | async
```
>реализовать горячее реплицирование для высокой доступности на 4ВМ. Источником должна выступать ВМ №3. Написать с какими проблемами столкнулись.
- на ВМ3 настроим параметры для синхронной репликации.
```sql
repl=# show hot_standby;
 hot_standby 
-------------
 on

postgres=# alter system set synchronous_standby_names = '*';
ALTER SYSTEM
postgres=# select pg_reload_conf();
 pg_reload_conf 
----------------
 t
```
- на ВМ4 создадим реплику при помощи pg_basebackup, ключ -R создаёт standby.signal и прописывает настройки в файл postgresql.auto.conf
```console
-bash-4.2$ /usr/pgsql-14/bin/pg_basebackup -h otus11-3 -U postgres -D /var/lib/pgsql/14/data/ -Xs -R -P
Password: 
35849/35849 kB (100%), 1/1 tablespace

-bash-4.2$ /usr/pgsql-14/bin/pg_ctl -D /var/lib/pgsql/14/data start
waiting for server to start....2021-11-13 18:04:45.981 UTC [1887] LOG:  redirecting log output to logging collector process
2021-11-13 18:04:45.981 UTC [1887] HINT:  Future log output will appear in directory "log".
 done
server started
```
```sql
postgres=# \c repl 
You are now connected to database "repl" as user "postgres".
repl=# \dt
         List of relations
 Schema | Name  | Type  |  Owner   
--------+-------+-------+----------
 public | test1 | table | postgres
 public | test2 | table | postgres
(2 rows)
```
- на ВМ3 проверим статус репликации:
```sql
repl=# select * from pg_stat_replication\gx
-[ RECORD 1 ]----+------------------------------
pid              | 2126
usesysid         | 10
usename          | postgres
application_name | walreceiver
client_addr      | 10.128.0.12
client_hostname  | 
client_port      | 42796
backend_start    | 2021-11-13 18:04:46.076374+00
backend_xmin     | 
state            | streaming
sent_lsn         | 0/3000148
write_lsn        | 0/3000148
flush_lsn        | 0/3000148
replay_lsn       | 0/3000148
write_lag        | 
flush_lag        | 
replay_lag       | 
sync_priority    | 1
sync_state       | sync
reply_time       | 2021-11-13 18:07:22.710983+00
```
<b>проверим работу репликации ВМ1 -> ВМ3 -> ВМ4 и ВМ2 -> ВМ3 -> ВМ4</b>

- добавим данные на ВМ1
```sql
repl=# insert into test1 values (100);
INSERT 0 1
```
- ВМ4
```sql
repl=# select * from test1 where k1 = 100;
 k1  
-----
 100
(1 row)
```
- удалим данные на ВМ2
```sql
repl=# delete from test2 where k2 = 99;
DELETE 1
```
- ВМ4
```sql
repl=# select * from test2 where k2 = 99;
 k1 
----
(0 rows)
```
