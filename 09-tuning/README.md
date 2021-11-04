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

> написать какого значения tps удалось достичь, показать какие параметры в какие значения устанавливали и почему  
