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
[root@otus06 ~]# yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
[root@otus06 ~]# yum install -y postgresql14-server
[root@otus06 ~]# /usr/pgsql-14/bin/postgresql-14-setup initdb
[root@otus06 ~]# systemctl enable --now postgresql-14
```
применить параметры настройки PostgreSQL из прикрепленного к материалам занятия файла
```console
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
```
зайти под пользователем postgres - sudo su postgres
```console
```
выполнить pgbench -i postgres
```console
```
запустить pgbench -c8 -P 10 -T 600 -U postgres postgres
```console
```
дать отработать до конца
дальше настроить autovacuum максимально эффективно
```console
autovacuum_max_workers = 4
autovacuum_naptime = 1s
autovacuum_vacuum_threshold = 50
autovacuum_analyze_threshold = 5
autovacuum_vacuum_scale_factor = 0.05
autovacuum_analyze_scale_factor = 0.01
autovacuum_vacuum_cost_delay = 1ms
autovacuum_vacuum_cost_limit = 500
```
построить график по получившимся значениям  
так чтобы получить максимально ровное значение tps
