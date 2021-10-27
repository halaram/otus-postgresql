Домашнее задание
### Работа с журналами

Цель:  
уметь работать с журналами и контрольными точками  
уметь настраивать параметры журналов  

<b>Имя проекта - postgres2021-2147483647</b>

Настройте выполнение контрольной точки раз в 30 секунд.  
```console
postgres=# alter system set checkpoint_timeout = '30s';
ALTER SYSTEM
postgres=# select pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)
```
10 минут c помощью утилиты pgbench подавайте нагрузку.  
```console
postgres=# SELECT pg_current_wal_lsn();
 pg_current_wal_lsn 
--------------------
 0/1748EE8
(1 row)

-bash-4.2$ /usr/pgsql-14/bin/pgbench -i postgres

-bash-4.2$ /usr/pgsql-14/bin/pgbench -c8 -P 10 -T 600 -U postgres postgres
pgbench (14.0)
starting vacuum...end.
progress: 10.0 s, 789.2 tps, lat 10.089 ms stddev 5.852
...
progress: 590.0 s, 280.2 tps, lat 28.548 ms stddev 16.749
progress: 600.0 s, 285.7 tps, lat 27.983 ms stddev 14.293
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 1
duration: 600 s
number of transactions actually processed: 184909
latency average = 25.948 ms
latency stddev = 14.915 ms
initial connection time = 32.716 ms
tps = 308.186191 (without initial connection time)
```
Измерьте, какой объем журнальных файлов был сгенерирован за это время. Оцените, какой объем приходится в среднем на одну контрольную точку.  
```console
postgres=# SELECT pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), '0/1748EE8') / 20);
 pg_size_pretty 
----------------
 19 MB
(1 row)
```
Проверьте данные статистики: все ли контрольные точки выполнялись точно по расписанию. Почему так произошло?  
```console
postgres=# select * from pg_stat_bgwriter\gx
-[ RECORD 1 ]---------+------------------------------
checkpoints_timed     | 36
checkpoints_req       | 0
checkpoint_write_time | 592072
checkpoint_sync_time  | 591
buffers_checkpoint    | 39861
buffers_clean         | 0
maxwritten_clean      | 0
buffers_backend       | 3012
buffers_backend_fsync | 0
buffers_alloc         | 3572
stats_reset           | 2021-10-27 17:40:37.727479+00

postgres=# show max_wal_size;
 max_wal_size 
--------------
 1GB
(1 row)
```
<b>Все контрольные точки выполнялись по расписанию (checkpoints_timed 36, checkpoints_req 0), так как параметр max_wal_size = 1GB превышает сгенерированный объём WAL файлов - 19MB.</b>

Сравните tps в синхронном/асинхронном режиме утилитой pgbench. Объясните полученный результат.  
```console
postgres=# alter system set synchronous_commit = off;
ALTER SYSTEM
postgres=# select pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)

-bash-4.2$ /usr/pgsql-14/bin/pgbench -c8 -P 10 -T 600 -U postgres postgres
pgbench (14.0)
starting vacuum...end.
progress: 10.0 s, 2142.3 tps, lat 3.710 ms stddev 1.475
...
progress: 590.0 s, 1093.3 tps, lat 7.294 ms stddev 21.350
progress: 600.0 s, 1081.1 tps, lat 7.376 ms stddev 21.483
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 1
duration: 600 s
number of transactions actually processed: 771270
latency average = 6.203 ms
latency stddev = 17.727 ms
initial connection time = 28.271 ms
tps = 1285.479465 (without initial connection time)
```
<b>Производиьельность по tps увеличилась больше чем в 3 раза из-за отсутсвия ожидании гарантированной записи WAL на диск.</b>

Создайте новый кластер с включенной контрольной суммой страниц. Создайте таблицу. Вставьте несколько значений.  
```console
[root@otus07 ~]# systemctl stop postgresql-14
[root@otus07 ~]# rm -rf /var/lib/pgsql/14/data
[root@otus07 ~]# PGSETUP_INITDB_OPTIONS="--data-checksums" /usr/pgsql-14/bin/postgresql-14-setup initdb
Initializing database ... OK
[root@otus07 ~]# systemctl start postgresql-14

postgres=# create table wrong_checksum(k int, v varchar);
CREATE TABLE
postgres=# insert into wrong_checksum select i, md5(i::varchar) from generate_series(1,10) as t(i);
INSERT 0 10
postgres=# select pg_relation_filepath('wrong_checksum');
 pg_relation_filepath 
----------------------
 base/14486/16392
(1 row)
[root@otus07 ~]# systemctl stop postgresql-14
```
Выключите кластер. Измените пару байт в таблице. Включите кластер и сделайте выборку из таблицы.  
```console
postgres=# select * from wrong_checksum;
WARNING:  page verification failed, calculated checksum 48456 but expected 25975
ERROR:  invalid page in block 0 of relation base/14486/16392
```
Что и почему произошло? как проигнорировать ошибку и продолжить работу?  
```console
postgres=# set ignore_checksum_failure = on;
SET
postgres=# select * from wrong_checksum;
WARNING:  page verification failed, calculated checksum 48456 but expected 25975
 k  |                v                 
----+----------------------------------
  1 | c5ca4238a0b923820dcc509a6f75849c
  2 | c81e728d9d4c2f636f067f89cc14862c
  3 | eccbc87e4b5ce2fe28308fd9f2a7baf3
  4 | a87ff679a2f3e71d9181a67b7542122c
  5 | e4da3b7fbbce2345d7772b0674a318d5
  6 | 1679091c5a880faf6fb5e6087eb1b2dc
  7 | 8f14e45fceea167a5a36dedd4bea2543
  8 | c9f0f895fb98ab9159f51fd0297e236d
  9 | 45c48cce2e2d7fbdea1afc51c7c6ad26
 10 | d3d9446802a44259755d38e6d163e820
(10 rows)
```
<b>Произошла ошибка при проверке контрольной суммы страницы. Установка параметра ignore_checksum_failure даёт прочитать таблицу, но данные могут быть недостоверные.</b>
