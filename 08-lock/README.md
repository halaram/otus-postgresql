Домашнее задание
### Механизм блокировок

Цель:
понимать как работает механизм блокировок объектов и строк

<b>Имя проекта - postgres2021-2147483647</b>

> Настройте сервер так, чтобы в журнал сообщений сбрасывалась информация о блокировках, удерживаемых более 200 миллисекунд. Воспроизведите ситуацию, при которой в журнале появятся такие сообщения.  
```sql
postgres=# create database lock;
CREATE DATABASE
postgres=# \c lock 
You are now connected to database "lock" as user "postgres".
lock=# alter system set log_lock_waits = 'on';
ALTER SYSTEM
lock=# alter system set deadlock_timeout = '200';
ALTER SYSTEM
lock=# select pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)
```
> Воспроизведите ситуацию, при которой в журнале появятся такие сообщения.  
```sql
lock=# create table lck(i int);
CREATE TABLE
lock-session1=#insert into lck values (0),(1),(2);
INSERT 0 3
```
- первая сессия:
```sql
lock=# \set PROMPT1 %/-session2%R%x%#
lock-session1=#select pg_backend_pid();
 pg_backend_pid 
----------------
           1689
(1 row)

lock-session1=#begin;
BEGIN
lock-session1=*#update lck set i = 0 where i = 0;
UPDATE 1
```
- вторая сессия
```sql
lock=# \set PROMPT1 %/-session2%R%x%#
lock-session2=#select pg_backend_pid();
 pg_backend_pid 
----------------
           1794
(1 row)

lock-session2=#begin;
BEGIN
lock-session2=*#update lck set i = 0 where i = 0;
```
- в логe сообщения о возникшей блокировке:
```console
2021-10-31 14:41:17.482 UTC [1794] LOG:  process 1794 still waiting for ShareLock on transaction 737 after 200.132 ms
2021-10-31 14:41:17.482 UTC [1794] DETAIL:  Process holding the lock: 1689. Wait queue: 1794.
2021-10-31 14:41:17.482 UTC [1794] CONTEXT:  while updating tuple (0,1) in relation "lck"
2021-10-31 14:41:17.482 UTC [1794] STATEMENT:  update lck set i = 0 where i = 0;
```
> Смоделируйте ситуацию обновления одной и той же строки тремя командами UPDATE в разных сеансах. Изучите возникшие блокировки в представлении pg_locks и убедитесь, что все они понятны. Пришлите список блокировок и объясните, что значит каждая.  
- первая сессия
```sql
lock-session1=#begin;
BEGIN
lock-session1=*#select pg_backend_pid(), txid_current();
 pg_backend_pid | txid_current 
----------------+--------------
           1689 |          747
(1 row)

lock-session1=*#update lck set i = 0 where i = 0;
UPDATE 1
lock-session1=*#
```
- вторая сессия
```sql
lock-session2=#begin;
BEGIN
lock-session2=*#select pg_backend_pid(), txid_current();
 pg_backend_pid | txid_current 
----------------+--------------
           1794 |          748
(1 row)

lock-session2=*#update lck set i = 0 where i = 0;
```
- третья сессия
```sql
lock-session3=#begin;
BEGIN
lock-session3=*#select pg_backend_pid(), txid_current();
 pg_backend_pid | txid_current 
----------------+--------------
           2060 |          749
(1 row)

lock-session3=*#update lck set i = 0 where i = 0;
```
- сообщения о блокировках в логе:
```console
2021-10-31 15:43:32.186 UTC [1794] LOG:  process 1794 still waiting for ShareLock on transaction 747 after 200.137 ms
2021-10-31 15:43:32.186 UTC [1794] DETAIL:  Process holding the lock: 1689. Wait queue: 1794.
2021-10-31 15:43:32.186 UTC [1794] CONTEXT:  while updating tuple (0,6) in relation "lck"
2021-10-31 15:43:32.186 UTC [1794] STATEMENT:  update lck set i = 0 where i = 0;
2021-10-31 15:44:10.826 UTC [2060] LOG:  process 2060 still waiting for ExclusiveLock on tuple (0,6) of relation 16385 of database 16384 after 200.160 ms
2021-10-31 15:44:10.826 UTC [2060] DETAIL:  Process holding the lock: 1794. Wait queue: 2060.
2021-10-31 15:44:10.826 UTC [2060] STATEMENT:  update lck set i = 0 where i = 0;
```
- информация о блокировках в представлении pg_locks:
```sql
lock=# select pid, locktype, relation::regclass, virtualxid, transactionid, mode, granted from pg_locks where pid in (1689, 1794, 2060) order by pid;
 pid  |   locktype    | relation | virtualxid | transactionid |       mode       | granted 
------+---------------+----------+------------+---------------+------------------+---------
 1689 | virtualxid    |          | 4/28       |               | ExclusiveLock    | t
 1689 | transactionid |          |            |           747 | ExclusiveLock    | t
 1689 | relation      | lck      |            |               | RowExclusiveLock | t <-1

 1794 | virtualxid    |          | 5/14       |               | ExclusiveLock    | t
 1794 | transactionid |          |            |           747 | ShareLock        | f <-2
 1794 | tuple         | lck      |            |               | ExclusiveLock    | t
 1794 | transactionid |          |            |           748 | ExclusiveLock    | t
 1794 | relation      | lck      |            |               | RowExclusiveLock | t

 2060 | tuple         | lck      |            |               | ExclusiveLock    | f <-3
 2060 | virtualxid    |          | 6/7        |               | ExclusiveLock    | t
 2060 | transactionid |          |            |           749 | ExclusiveLock    | t
 2060 | relation      | lck      |            |               | RowExclusiveLock | t
(12 rows)
```
<b> Каждый из сеансов удерживает исключительные блокировки ExclusiveLock своего виртуального номера virtualxid и своего номера транзакции transactionid.  
Каждый из сеансов установил блокировку RowExclusiveLock типа relation для изменения таблицы lck.  
Второй сеанс (1794) ожидает блокировку transactionid типа ShareLock для первого сеанса и удерживает блокировку ExclusiveLock типа tuple для строки.  
Третий сеанс (2060) ожидает блокировку ExclusiveLock типа tuple, которую удерживает второй сеанс.  </b>
> Воспроизведите взаимоблокировку трех транзакций. Можно ли разобраться в ситуации постфактум, изучая журнал сообщений?  
- первая сессия
```sql
lock-session1=#begin;
BEGIN
lock-session1=*#select pg_backend_pid(), txid_current();
 pg_backend_pid | txid_current 
----------------+--------------
           1689 |          751
(1 row)

lock-session1=*#update lck set i = 0 where i = 0;
UPDATE 1
```
- вторая сессия
```sql
lock-session2=#begin;
BEGIN
lock-session2=*#select pg_backend_pid(), txid_current();
 pg_backend_pid | txid_current 
----------------+--------------
           1794 |          752
(1 row)

lock-session2=*#update lck set i = 1 where i = 1;
UPDATE 1
```
- третья сессия
```sql
lock-session3=#begin;
BEGIN
lock-session3=*#select pg_backend_pid(), txid_current();
 pg_backend_pid | txid_current 
----------------+--------------
           2060 |          753
(1 row)

lock-session3=*#update lck set i = 2 where i = 2;
UPDATE 1
```
- первая сессия
```sql
lock-session1=*#update lck set i = 1 where i = 1;
```
- вторая сессия
```sql
lock-session2=*#update lck set i = 2 where i = 2;
```
- третья сессия
```sql
lock-session3=*#update lck set i = 0 where i = 0;
ERROR:  deadlock detected
DETAIL:  Process 2060 waits for ShareLock on transaction 751; blocked by process 1689.
Process 1689 waits for ShareLock on transaction 752; blocked by process 1794.
Process 1794 waits for ShareLock on transaction 753; blocked by process 2060.
HINT:  See server log for query details.
CONTEXT:  while updating tuple (0,3) in relation "lck"
```
- лог
```console
2021-10-31 17:33:25.487 UTC [2060] LOG:  process 2060 detected deadlock while waiting for ShareLock on transaction 751 after 200.174 ms
2021-10-31 17:33:25.487 UTC [2060] DETAIL:  Process holding the lock: 1689. Wait queue: .
2021-10-31 17:33:25.487 UTC [2060] CONTEXT:  while updating tuple (0,3) in relation "lck"
2021-10-31 17:33:25.487 UTC [2060] STATEMENT:  update lck set i = 0 where i = 0;
2021-10-31 17:33:25.488 UTC [2060] ERROR:  deadlock detected
2021-10-31 17:33:25.488 UTC [2060] DETAIL:  Process 2060 waits for ShareLock on transaction 751; blocked by process 1689.
    Process 1689 waits for ShareLock on transaction 752; blocked by process 1794.
    Process 1794 waits for ShareLock on transaction 753; blocked by process 2060.
    Process 2060: update lck set i = 0 where i = 0;
    Process 1689: update lck set i = 1 where i = 1;
    Process 1794: update lck set i = 2 where i = 2;
2021-10-31 17:33:25.488 UTC [2060] HINT:  See server log for query details.
2021-10-31 17:33:25.488 UTC [2060] CONTEXT:  while updating tuple (0,3) in relation "lck"
2021-10-31 17:33:25.488 UTC [2060] STATEMENT:  update lck set i = 0 where i = 0;
2021-10-31 17:33:25.488 UTC [1794] LOG:  process 1794 acquired ShareLock on transaction 753 after 86157.315 ms
2021-10-31 17:33:25.488 UTC [1794] CONTEXT:  while updating tuple (0,2) in relation "lck"
2021-10-31 17:33:25.488 UTC [1794] STATEMENT:  update lck set i = 2 where i = 2;
```
> Могут ли две транзакции, выполняющие единственную команду UPDATE одной и той же таблицы (без where), заблокировать друг друга?  
```console
```
> Попробуйте воспроизвести такую ситуацию.  
```console
```
