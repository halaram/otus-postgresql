Домашнее задание
### Работа с уровнями изоляции транзакции в PostgreSQL

Цель:  
научиться работать с Google Cloud Platform на уровне Google Compute Engine (IaaS)  
научиться управлять уровнем изолции транзации в PostgreSQL и понимать особенность работы уровней read commited и repeatable read  
создать новый проект в Google Cloud Platform, например postgres2021-, где yyyymmdd год, месяц и день вашего рождения (имя проекта должно быть уникально на уровне GCP)  
дать возможность доступа к этому проекту пользователю ifti@yandex.ru с ролью Project Editor  
далее создать инстанс виртуальной машины Compute Engine с дефолтными параметрами  
добавить свой ssh ключ в GCE metadata  
зайти удаленным ssh (первая сессия), не забывайте про ssh-add  
поставить PostgreSQL  
зайти вторым ssh (вторая сессия)  
запустить везде psql из под пользователя postgres
<pre><code>
1 - \set PROMPT1 %/-s1%R%x%#
2 - \set PROMPT1 %/-s2%R%x%#
</code></pre>
выключить auto commit
<pre><code>
task02-s1=#\set AUTOCOMMIT off
task02-s2=#\set AUTOCOMMIT off
</code></pre>
сделать в первой сессии новую таблицу и наполнить ее данными create table persons(id serial, first_name text, second_name text); insert into persons(first_name, second_name) values('ivan', 'ivanov'); insert into persons(first_name, second_name) values('petr', 'petrov'); commit;
<pre><code>
task02-s1=#create table persons(id serial, first_name text, second_name text);
CREATE TABLE
task02-s1=*#insert into persons(first_name, second_name) values('ivan', 'ivanov'), ('petr', 'petrov');
INSERT 0 2
task02-s1=*#commit;
COMMIT
</code></pre>
посмотреть текущий уровень изоляции: show transaction isolation level
<pre><code>
task02-s1=#show transaction isolation level;
 transaction_isolation
-----------------------
 read committed
(1 row)

task02-s2=#show transaction isolation level;
 transaction_isolation
-----------------------
 read committed
(1 row)
</code></pre>
начать новую транзакцию в обоих сессиях с дефолтным (не меняя) уровнем изоляции
<pre><code>
task02-s1=#begin;
BEGIN
task02-s2=#begin;
BEGIN
</code></pre>
в первой сессии добавить новую запись insert into persons(first_name, second_name) values('sergey', 'sergeev');
<pre><code>
task02-s1=*#insert into persons(first_name, second_name) values('sergey', 'sergeev');
INSERT 0 1
</code></pre>
сделать select * from persons во второй сессии
<pre><code>
task02-s2=*#select * from persons;
 id | first_name | second_name 
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
(2 rows)
</code></pre>
видите ли вы новую запись и если да то почему?  
Нет..  

завершить первую транзакцию - commit;
<pre><code>
task02-s1=*#commit;
COMMIT
</code></pre>
сделать select * from persons во второй сессии
<pre><code>
task02-s2=*#select * from persons;
 id | first_name | second_name 
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
  3 | sergey     | sergeev
(3 rows)
</code></pre>
видите ли вы новую запись и если да то почему?  
Да..  

завершите транзакцию во второй сессии
<pre><code>
task02-s2=*#commit;
COMMIT
</code></pre>
начать новые но уже repeatable read транзации - set transaction isolation level repeatable read;
<pre><code>
task02-s1=#set transaction isolation level repeatable read;
SET
task02-s2=#set transaction isolation level repeatable read;
SET
</code></pre>
в первой сессии добавить новую запись insert into persons(first_name, second_name) values('sveta', 'svetova');
<pre><code>
task02-s1=*#insert into persons(first_name, second_name) values('sveta', 'svetova');
INSERT 0 1
</code></pre>
сделать select * from persons во второй сессии
<pre><code>
task02-s2=*#select * from persons;
 id | first_name | second_name 
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
  3 | sergey     | sergeev
(3 rows)
</code></pre>
видите ли вы новую запись и если да то почему?  
Нет..  

завершить первую транзакцию - commit;
<pre><code>
task02-s1=*#commit;
COMMIT
</code></pre>
сделать select * from persons во второй сессии
<pre><code>
task02-s2=*#select * from persons;
 id | first_name | second_name 
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
  3 | sergey     | sergeev
(3 rows)
</code></pre>
видите ли вы новую запись и если да то почему?  
Нет..  

завершить вторую транзакцию
<pre><code>
task02-s2=*#commit;
COMMIT
</code></pre>
сделать select * from persons во второй сессии
<pre><code>
task02-s2=#select * from persons;
 id | first_name | second_name 
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
  3 | sergey     | sergeev
  4 | sveta      | svetova
(4 rows)
</code></pre>
видите ли вы новую запись и если да то почему?  
Да..  

остановите виртуальную машину но не удаляйте ее  
