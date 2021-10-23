Домашнее задание
### Настройка autovacuum с учетом оптимальной производительности

Цель:
запустить нагрузочный тест pgbench  
настроить параметры autovacuum для достижения максимального уровня устойчивой производительности

<b>Имя проекта - postgres2021-2147483647</b>

создать GCE инстанс типа e2-medium и standard disk 10GB
```console
gcloud compute instances create otus06...
```
установить на него PostgreSQL 13 с дефолтными настройками
```console
[root@otus-06 ~]# yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
[root@otus-06 ~]# yum install -y postgresql14-server
[root@otus-06 ~]# /usr/pgsql-14/bin/postgresql-14-setup initdb
[root@otus-06 ~]# systemctl enable --now postgresql-14
```
применить параметры настройки PostgreSQL из прикрепленного к материалам занятия файла
<pre><code>
max_connections = 40
shared_buffers = 1GB
effective_cache_size = 3GB
maintenance_work_mem = 512MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 500
random_page_cost = 4
effective_io_concurrency = 2
work_mem = 6553kB
min_wal_size = 4GB
max_wal_size = 16GB
</code></pre
зайти под пользователем postgres - sudo su postgres
выполнить pgbench -i postgres
```console
-bash-4.2$ /usr/pgsql-14/bin/pgbench -i postgres
dropping old tables...
NOTICE:  table "pgbench_accounts" does not exist, skipping
NOTICE:  table "pgbench_branches" does not exist, skipping
NOTICE:  table "pgbench_history" does not exist, skipping
NOTICE:  table "pgbench_tellers" does not exist, skipping
creating tables...
generating data (client-side)...
100000 of 100000 tuples (100%) done (elapsed 0.09 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 0.41 s (drop tables 0.00 s, create tables 0.01 s, client-side generate 0.25 s, vacuum 0.08 s, primary keys 0.07 s).
```
запустить pgbench -c8 -P 10 -T 600 -U postgres postgres
```console
-bash-4.2$ /usr/pgsql-14/bin/pgbench -c8 -P 10 -T 600 -U postgres postgres
pgbench (14.0)
starting vacuum...end.
progress: 10.0 s, 895.9 tps, lat 8.894 ms stddev 4.943
progress: 20.0 s, 941.3 tps, lat 8.493 ms stddev 4.278
progress: 30.0 s, 939.0 tps, lat 8.513 ms stddev 4.372
progress: 40.0 s, 944.9 tps, lat 8.456 ms stddev 4.400
progress: 50.0 s, 947.2 tps, lat 8.440 ms stddev 4.498
progress: 60.0 s, 950.7 tps, lat 8.408 ms stddev 4.503
progress: 70.0 s, 939.9 tps, lat 8.500 ms stddev 4.704
progress: 80.0 s, 932.6 tps, lat 8.572 ms stddev 4.617
progress: 90.0 s, 926.2 tps, lat 8.630 ms stddev 4.576
progress: 100.0 s, 918.2 tps, lat 8.704 ms stddev 4.590
progress: 110.0 s, 927.7 tps, lat 8.615 ms stddev 4.157
progress: 120.0 s, 918.7 tps, lat 8.701 ms stddev 4.541
progress: 130.0 s, 919.2 tps, lat 8.695 ms stddev 4.654
progress: 140.0 s, 908.8 tps, lat 8.794 ms stddev 4.911
progress: 150.0 s, 943.3 tps, lat 8.475 ms stddev 4.483
progress: 160.0 s, 930.9 tps, lat 8.586 ms stddev 4.534
progress: 170.0 s, 932.2 tps, lat 8.574 ms stddev 4.587
progress: 180.0 s, 942.4 tps, lat 8.481 ms stddev 4.654
progress: 190.0 s, 955.3 tps, lat 8.366 ms stddev 4.045
progress: 200.0 s, 948.8 tps, lat 8.424 ms stddev 4.451
progress: 210.0 s, 931.2 tps, lat 8.583 ms stddev 4.632
progress: 220.0 s, 944.4 tps, lat 8.463 ms stddev 4.524
progress: 230.0 s, 949.4 tps, lat 8.418 ms stddev 4.472
progress: 240.0 s, 938.3 tps, lat 8.520 ms stddev 4.576
progress: 250.0 s, 927.3 tps, lat 8.618 ms stddev 4.678
progress: 260.0 s, 929.1 tps, lat 8.601 ms stddev 4.642
progress: 270.0 s, 933.1 tps, lat 8.567 ms stddev 4.056
progress: 280.0 s, 935.1 tps, lat 8.548 ms stddev 4.570
progress: 290.0 s, 954.8 tps, lat 8.370 ms stddev 4.565
progress: 300.0 s, 898.5 tps, lat 8.895 ms stddev 5.261
progress: 310.0 s, 900.5 tps, lat 8.875 ms stddev 5.117
progress: 320.0 s, 908.9 tps, lat 8.795 ms stddev 4.643
progress: 330.0 s, 921.6 tps, lat 8.671 ms stddev 4.774
progress: 340.0 s, 897.7 tps, lat 8.904 ms stddev 4.744
progress: 350.0 s, 921.3 tps, lat 8.677 ms stddev 4.094
progress: 360.0 s, 899.3 tps, lat 8.889 ms stddev 4.754
progress: 370.0 s, 666.2 tps, lat 11.894 ms stddev 17.592
progress: 380.0 s, 566.8 tps, lat 14.095 ms stddev 22.053
progress: 390.0 s, 592.3 tps, lat 13.494 ms stddev 20.602
progress: 400.0 s, 590.3 tps, lat 13.531 ms stddev 21.311
progress: 410.0 s, 584.2 tps, lat 13.677 ms stddev 21.385
progress: 420.0 s, 580.0 tps, lat 13.775 ms stddev 20.945
progress: 430.0 s, 583.5 tps, lat 13.716 ms stddev 20.880
progress: 440.0 s, 576.0 tps, lat 13.868 ms stddev 22.412
progress: 450.0 s, 609.6 tps, lat 13.112 ms stddev 21.495
progress: 460.0 s, 593.2 tps, lat 13.465 ms stddev 21.013
progress: 470.0 s, 611.3 tps, lat 13.069 ms stddev 20.918
progress: 480.0 s, 610.0 tps, lat 13.090 ms stddev 21.103
progress: 490.0 s, 586.5 tps, lat 13.638 ms stddev 21.807
progress: 500.0 s, 541.2 tps, lat 14.762 ms stddev 22.178
progress: 510.0 s, 564.0 tps, lat 14.179 ms stddev 21.279
progress: 520.0 s, 568.5 tps, lat 14.053 ms stddev 21.225
progress: 530.0 s, 598.6 tps, lat 13.361 ms stddev 21.901
progress: 540.0 s, 590.1 tps, lat 13.554 ms stddev 21.316
progress: 550.0 s, 583.6 tps, lat 13.699 ms stddev 21.709
progress: 560.0 s, 574.2 tps, lat 13.903 ms stddev 22.852
progress: 570.0 s, 598.5 tps, lat 13.324 ms stddev 21.599
progress: 580.0 s, 587.7 tps, lat 13.604 ms stddev 21.832
progress: 590.0 s, 600.2 tps, lat 13.323 ms stddev 20.540
progress: 600.0 s, 594.9 tps, lat 13.426 ms stddev 21.065
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 1
duration: 600 s
number of transactions actually processed: 476087
latency average = 10.073 ms
latency stddev = 12.442 ms
initial connection time = 24.731 ms
tps = 793.427908 (without initial connection time)
```
дать отработать до конца
дальше настроить autovacuum максимально эффективно
<pre><code>
autovacuum_max_workers = 4
autovacuum_naptime = 1s
autovacuum_vacuum_threshold = 50
autovacuum_analyze_threshold = 5
autovacuum_vacuum_scale_factor = 0.05
autovacuum_analyze_scale_factor = 0.01
autovacuum_vacuum_cost_delay = 1ms
autovacuum_vacuum_cost_limit = 500
</code></pre>
```console

```
построить график по получившимся значениям  
так чтобы получить максимально ровное значение tps
