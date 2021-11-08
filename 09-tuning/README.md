### Нагрузочное тестирование и тюнинг PostgreSQL

Цель:
сделать нагрузочное тестирование PostgreSQL
настроить параметры PostgreSQL для достижения максимальной производительности

<b>Имя проекта - postgres2021-2147483647</b>

> сделать инстанс Google Cloud Engine типа e2-medium с ОС Ubuntu 20.04  
> поставить на него PostgreSQL 13 из пакетов собираемых postgres.org  
```console
[root@otus08 ~]# yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
[root@otus08 ~]# yum install -y postgresql14-server
[root@otus08 ~]# /usr/pgsql-14/bin/postgresql-14-setup initdb
[root@otus08 ~]# systemctl enable --now postgresql-14
```
> настроить кластер PostgreSQL 13 на максимальную производительность не обращая внимание на возможные проблемы с надежностью в случае аварийной перезагрузки виртуальной машины  

> нагрузить кластер через утилиту https://github.com/Percona-Lab/sysbench-tpcc (требует установки https://github.com/akopytov/sysbench)  
```console
[root@otus08 ~]# curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.rpm.sh | sudo bash
[root@otus08 ~]# yum -y install sysbench
```
Заполним отдельно созданную БД без data_checksums sysbench тестовыми данными под пользователем tune:
```console
-bash-4.2$ sysbench --db-driver=pgsql --pgsql-db=sysbench --pgsql-user=tune --pgsql-password=tune --report-interval=30 --tables=10 --table_size=1000000 oltp_read_write prepare
```
В БД sysbench 10 таблиц по 211MB:
```sql
postgres=# \c sysbench 
You are now connected to database "sysbench" as user "postgres".
sysbench=# \dt+
                                   List of relations
 Schema |   Name   | Type  | Owner | Persistence | Access method |  Size  | Description 
--------+----------+-------+-------+-------------+---------------+--------+-------------
 public | sbtest1  | table | tune  | permanent   | heap          | 211 MB | 
 public | sbtest10 | table | tune  | permanent   | heap          | 211 MB | 
 public | sbtest2  | table | tune  | permanent   | heap          | 211 MB | 
 public | sbtest3  | table | tune  | permanent   | heap          | 211 MB | 
 public | sbtest4  | table | tune  | permanent   | heap          | 211 MB | 
 public | sbtest5  | table | tune  | permanent   | heap          | 211 MB | 
 public | sbtest6  | table | tune  | permanent   | heap          | 211 MB | 
 public | sbtest7  | table | tune  | permanent   | heap          | 211 MB | 
 public | sbtest8  | table | tune  | permanent   | heap          | 211 MB | 
 public | sbtest9  | table | tune  | permanent   | heap          | 211 MB | 
(10 rows)
```
Проведём тест OLTP read/write в 8 потоков в течение 10 мин:
```console
-bash-4.2$ sysbench --db-driver=pgsql --pgsql-db=sysbench --pgsql-user=tune --pgsql-password=tune --report-interval=30 --tables=10 --table_size=1000000 --threads=8 --time=600 oltp_read_write run
sysbench 1.0.20 (using bundled LuaJIT 2.1.0-beta2)

Running the test with following options:
Number of threads: 8
Report intermediate results every 30 second(s)
Initializing random number generator from current time


Initializing worker threads...

Threads started!

[ 30s ] thds: 8 tps: 207.02 qps: 4145.64 (r/w/o: 2902.18/829.08/414.37) lat (ms,95%): 223.34 err/s: 0.03 reconn/s: 0.00
[ 60s ] thds: 8 tps: 9.57 qps: 191.77 (r/w/o: 134.23/38.40/19.13) lat (ms,95%): 7215.39 err/s: 0.00 reconn/s: 0.00
[ 90s ] thds: 8 tps: 76.50 qps: 1528.73 (r/w/o: 1070.13/305.60/153.00) lat (ms,95%): 646.19 err/s: 0.00 reconn/s: 0.00
[ 120s ] thds: 8 tps: 70.93 qps: 1419.72 (r/w/o: 993.93/283.93/141.87) lat (ms,95%): 846.57 err/s: 0.00 reconn/s: 0.00
[ 150s ] thds: 8 tps: 69.06 qps: 1381.46 (r/w/o: 966.88/276.42/138.16) lat (ms,95%): 657.93 err/s: 0.00 reconn/s: 0.00
[ 180s ] thds: 8 tps: 72.87 qps: 1457.33 (r/w/o: 1020.13/291.47/145.73) lat (ms,95%): 694.45 err/s: 0.00 reconn/s: 0.00
[ 210s ] thds: 8 tps: 62.93 qps: 1257.79 (r/w/o: 880.46/251.46/125.87) lat (ms,95%): 657.93 err/s: 0.00 reconn/s: 0.00
[ 240s ] thds: 8 tps: 44.30 qps: 886.51 (r/w/o: 620.71/177.20/88.60) lat (ms,95%): 549.52 err/s: 0.00 reconn/s: 0.00
[ 270s ] thds: 8 tps: 56.27 qps: 1125.63 (r/w/o: 787.90/225.13/112.60) lat (ms,95%): 590.56 err/s: 0.03 reconn/s: 0.00
[ 300s ] thds: 8 tps: 63.80 qps: 1276.37 (r/w/o: 893.43/255.30/127.63) lat (ms,95%): 634.66 err/s: 0.00 reconn/s: 0.00
[ 330s ] thds: 8 tps: 66.27 qps: 1325.53 (r/w/o: 927.90/265.10/132.53) lat (ms,95%): 669.89 err/s: 0.00 reconn/s: 0.00
[ 360s ] thds: 8 tps: 65.67 qps: 1313.42 (r/w/o: 919.33/262.73/131.37) lat (ms,95%): 669.89 err/s: 0.00 reconn/s: 0.00
[ 390s ] thds: 8 tps: 69.03 qps: 1380.68 (r/w/o: 966.47/276.14/138.07) lat (ms,95%): 657.93 err/s: 0.00 reconn/s: 0.00
[ 420s ] thds: 8 tps: 64.37 qps: 1286.03 (r/w/o: 900.36/256.93/128.73) lat (ms,95%): 909.80 err/s: 0.00 reconn/s: 0.00
[ 450s ] thds: 8 tps: 66.67 qps: 1334.11 (r/w/o: 933.71/267.07/133.33) lat (ms,95%): 861.95 err/s: 0.00 reconn/s: 0.00
[ 480s ] thds: 8 tps: 67.37 qps: 1348.47 (r/w/o: 944.00/269.67/134.80) lat (ms,95%): 669.89 err/s: 0.03 reconn/s: 0.00
[ 510s ] thds: 8 tps: 68.63 qps: 1372.19 (r/w/o: 960.66/274.27/137.27) lat (ms,95%): 669.89 err/s: 0.00 reconn/s: 0.00
[ 540s ] thds: 8 tps: 53.13 qps: 1063.74 (r/w/o: 744.54/212.87/106.33) lat (ms,95%): 707.07 err/s: 0.03 reconn/s: 0.00
[ 570s ] thds: 8 tps: 64.90 qps: 1298.60 (r/w/o: 909.07/259.67/129.87) lat (ms,95%): 861.95 err/s: 0.03 reconn/s: 0.00
[ 600s ] thds: 8 tps: 65.27 qps: 1305.94 (r/w/o: 914.20/261.10/130.63) lat (ms,95%): 861.95 err/s: 0.03 reconn/s: 0.00
SQL statistics:
    queries performed:
        read:                            581714
        write:                           166188
        other:                           83106
        total:                           831008
    transactions:                        41545  (69.19 per sec.)
    queries:                             831008 (1383.97 per sec.)
    ignored errors:                      6      (0.01 per sec.)
    reconnects:                          0      (0.00 per sec.)

General statistics:
    total time:                          600.4503s
    total number of events:              41545

Latency (ms):
         min:                                    4.07
         avg:                                  115.62
         max:                                10238.76
         95th percentile:                      657.93
         sum:                              4803237.63

Threads fairness:
    events (avg/stddev):           5193.1250/11.38
    execution time (avg/stddev):   600.4047/0.01
```
<b> Среднее значение на ненастроенном Postgres 69 tps</b>

Применим параметры из отдельно подготовленного файла postgresql.tune.conf через include в postgresql.conf, с последующим рестаром БД:
```console
-bash-4.2$ cat postgresql.tune.conf 
shared_buffers = 1500MB
maintenance_work_mem = 200MB
work_mem = 256MB
max_connections = 11
synchronous_commit = off
fsync = off
full_page_writes = off
effective_cache_size = 2270MB
checkpoint_timeout = 24h
max_wal_size = 10GB
max_worker_processes = 2
max_parallel_workers = 2
max_parallel_maintenance_workers = 1
max_parallel_workers_per_gather = 1
```

Проведём повторный тест:
```console
-bash-4.2$ sysbench --db-driver=pgsql --pgsql-db=sysbench --pgsql-user=tune --pgsql-password=tune --report-interval=30 --tables=10 --table_size=1000000 --threads=8 --time=600 oltp_read_write run
sysbench 1.0.20 (using bundled LuaJIT 2.1.0-beta2)

Running the test with following options:
Number of threads: 8
Report intermediate results every 30 second(s)
Initializing random number generator from current time


Initializing worker threads...

Threads started!

[ 30s ] thds: 8 tps: 517.71 qps: 10358.14 (r/w/o: 7251.26/2071.19/1035.69) lat (ms,95%): 17.95 err/s: 0.00 reconn/s: 0.00
[ 60s ] thds: 8 tps: 547.32 qps: 10944.82 (r/w/o: 7661.13/2189.05/1094.64) lat (ms,95%): 16.12 err/s: 0.00 reconn/s: 0.00
[ 90s ] thds: 8 tps: 543.80 qps: 10877.19 (r/w/o: 7614.45/2175.10/1087.64) lat (ms,95%): 16.12 err/s: 0.00 reconn/s: 0.00
[ 120s ] thds: 8 tps: 557.29 qps: 11146.12 (r/w/o: 7802.39/2229.14/1114.58) lat (ms,95%): 15.83 err/s: 0.00 reconn/s: 0.00
[ 150s ] thds: 8 tps: 288.77 qps: 5774.81 (r/w/o: 4042.21/1155.07/577.53) lat (ms,95%): 132.49 err/s: 0.00 reconn/s: 0.00
[ 180s ] thds: 8 tps: 284.47 qps: 5689.62 (r/w/o: 3982.74/1137.94/568.94) lat (ms,95%): 130.13 err/s: 0.00 reconn/s: 0.00
[ 210s ] thds: 8 tps: 284.33 qps: 5687.08 (r/w/o: 3980.96/1137.46/568.67) lat (ms,95%): 130.13 err/s: 0.00 reconn/s: 0.00
[ 240s ] thds: 8 tps: 283.33 qps: 5665.57 (r/w/o: 3965.77/1133.13/566.67) lat (ms,95%): 130.13 err/s: 0.00 reconn/s: 0.00
[ 270s ] thds: 8 tps: 273.73 qps: 5475.35 (r/w/o: 3832.81/1095.07/547.47) lat (ms,95%): 132.49 err/s: 0.00 reconn/s: 0.00
[ 300s ] thds: 8 tps: 281.80 qps: 5635.31 (r/w/o: 3944.64/1127.07/563.60) lat (ms,95%): 130.13 err/s: 0.00 reconn/s: 0.00
[ 330s ] thds: 8 tps: 282.17 qps: 5643.96 (r/w/o: 3950.80/1128.83/564.33) lat (ms,95%): 130.13 err/s: 0.00 reconn/s: 0.00
[ 360s ] thds: 8 tps: 281.40 qps: 5628.47 (r/w/o: 3940.04/1125.60/562.83) lat (ms,95%): 130.13 err/s: 0.03 reconn/s: 0.00
[ 390s ] thds: 8 tps: 281.13 qps: 5623.16 (r/w/o: 3936.17/1124.70/562.30) lat (ms,95%): 130.13 err/s: 0.00 reconn/s: 0.00
[ 420s ] thds: 8 tps: 279.57 qps: 5591.00 (r/w/o: 3913.73/1118.10/559.17) lat (ms,95%): 130.13 err/s: 0.00 reconn/s: 0.00
[ 450s ] thds: 8 tps: 281.93 qps: 5638.07 (r/w/o: 3946.60/1127.60/563.87) lat (ms,95%): 130.13 err/s: 0.00 reconn/s: 0.00
[ 480s ] thds: 8 tps: 281.67 qps: 5634.39 (r/w/o: 3944.16/1126.90/563.33) lat (ms,95%): 130.13 err/s: 0.00 reconn/s: 0.00
[ 510s ] thds: 8 tps: 280.87 qps: 5616.01 (r/w/o: 3931.04/1123.24/561.73) lat (ms,95%): 130.13 err/s: 0.00 reconn/s: 0.00
[ 540s ] thds: 8 tps: 282.73 qps: 5655.30 (r/w/o: 3958.83/1131.00/565.47) lat (ms,95%): 130.13 err/s: 0.00 reconn/s: 0.00
[ 570s ] thds: 8 tps: 282.56 qps: 5650.83 (r/w/o: 3955.33/1130.38/565.12) lat (ms,95%): 130.13 err/s: 0.00 reconn/s: 0.00
[ 600s ] thds: 8 tps: 280.84 qps: 5617.40 (r/w/o: 3932.44/1123.29/561.68) lat (ms,95%): 130.13 err/s: 0.00 reconn/s: 0.00
SQL statistics:
    queries performed:
        read:                            2804662
        write:                           801328
        other:                           400668
        total:                           4006658
    transactions:                        200332 (333.67 per sec.)
    queries:                             4006658 (6673.33 per sec.)
    ignored errors:                      1      (0.00 per sec.)
    reconnects:                          0      (0.00 per sec.)

General statistics:
    total time:                          600.3963s
    total number of events:              200332

Latency (ms):
         min:                                    2.92
         avg:                                   23.96
         max:                                 1734.97
         95th percentile:                       17.63
         sum:                              4798986.98

Threads fairness:
    events (avg/stddev):           25041.5000/375.69
    execution time (avg/stddev):   599.8734/0.27

```
> написать какого значения tps удалось достичь, показать какие параметры в какие значения устанавливали и почему  

<b> После установки параметров среднее значение 333 tps.
Основная цель установки параметров - снижение влияния производительности дисковой подсистемы на результаты теста.
1. Увеличены значения shared_buffers до примерно 40% ОЗУ, work_mem для операций сортировки, соответственно max_connections уменьшен до минимума (threads + superuser_reserved_connections).
2. Процессы контрольных точек сведены к минимуму установкой параметров checkpoint_timeout = 24h, max_wal_size = 10GB.
3. Отключены synchronous_commit, fsync для ускорения операций ввода-вывода. full_page_writes выключен для предотвращения дополнительной записи страниц на диск при первом изменении.
</b>
