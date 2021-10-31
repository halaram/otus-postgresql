Домашнее задание
### Механизм блокировок

Цель:
понимать как работает механизм блокировок объектов и строк

<b>Имя проекта - postgres2021-2147483647</b>

- Настройте сервер так, чтобы в журнал сообщений сбрасывалась информация о блокировках, удерживаемых более 200 миллисекунд. Воспроизведите ситуацию, при которой в журнале появятся такие сообщения.  
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
- Воспроизведите ситуацию, при которой в журнале появятся такие сообщения.  
```sql
lock=# create table lck(i int);
CREATE TABLE
lock-session1=#insert into lck values (0),(1),(2);
INSERT 0 3
```
первая сессия:
```sql
lock=# \set PROMPT1 %/-session2%R%x%#
lock-session1=#select pg_backend_pid();
 pg_backend_pid 
----------------
           1689
(1 row)
```
вторая сессия
```sql
lock=# \set PROMPT1 %/-session2%R%x%#
lock-session2=#select pg_backend_pid();
 pg_backend_pid 
----------------
           1794
(1 row)
```
- Смоделируйте ситуацию обновления одной и той же строки тремя командами UPDATE в разных сеансах. Изучите возникшие блокировки в представлении pg_locks и убедитесь, что все они понятны. Пришлите список блокировок и объясните, что значит каждая.  
```console
```
- Воспроизведите взаимоблокировку трех транзакций. Можно ли разобраться в ситуации постфактум, изучая журнал сообщений?  
```console
```
- Могут ли две транзакции, выполняющие единственную команду UPDATE одной и той же таблицы (без where), заблокировать друг друга?  
```console
```
- Попробуйте воспроизвести такую ситуацию.  
```console
```
