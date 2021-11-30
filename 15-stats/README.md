### Работа с индексами, join'ами, статистикой

Цель:  
знать и уметь применять основные виды индексов PostgreSQL  
строить и анализировать план выполнения запроса  
уметь оптимизировать запросы для с использованием индексов  
знать и уметь применять различные виды join'ов  
строить и анализировать план выполенения запроса  
оптимизировать запрос  
уметь собирать и анализировать статистику для таблицы  

<b>Имя проекта - postgres2021-2147483647</b>

1 вариант:  
>Создать индексы на БД, которые ускорят доступ к данным.  
```sql
postgres=# create database stats;
CREATE DATABASE
postgres=# \c stats 
You are now connected to database "stats" as user "postgres".
stats=# create table tablei as select row_number() over() as id, * from pg_timezone_names;
SELECT 1189
```
В данном задании тренируются навыки:  
определения узких мест  
написания запросов для создания индекса  
оптимизации  
Необходимо:  
>Создать индекс к какой-либо из таблиц вашей БД  
```sql
demo=# create index on flights (arrival_airport);
CREATE INDEX
```
>Прислать текстом результат команды explain, в которой используется данный индекс  
```sql
demo=# explain select * from flights where arrival_airport = 'DME';
                                          QUERY PLAN
----------------------------------------------------------------------------------------------
 Bitmap Heap Scan on flights  (cost=40.97..472.79 rows=3185 width=63)
   Recheck Cond: (arrival_airport = 'DME'::bpchar)
   ->  Bitmap Index Scan on flights_arrival_airport_idx  (cost=0.00..40.18 rows=3185 width=0)
         Index Cond: (arrival_airport = 'DME'::bpchar)
(4 rows)

demo=# drop index flights_arrival_airport_idx;
DROP INDEX
```
>Реализовать индекс для полнотекстового поиска  
```sql
demo=# alter table tickets add column passenger_name_fts tsvector;
ALTER TABLE

demo=# update tickets set passenger_name_fts = to_tsvector(passenger_name);
UPDATE 366733

demo=# explain select * from tickets where passenger_name_fts @@ to_tsquery('ivanov');
                                           QUERY PLAN
-------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on tickets  (cost=78.23..14132.25 rows=7481 width=140)
   Recheck Cond: (passenger_name_fts @@ to_tsquery('ivanov'::text))
   ->  Bitmap Index Scan on tickets_passenger_name_fts_idx  (cost=0.00..76.36 rows=7481 width=0)
         Index Cond: (passenger_name_fts @@ to_tsquery('ivanov'::text))
(4 rows)

demo=# alter table tickets drop column passenger_name_fts;
ALTER TABLE
```
>Реализовать индекс на часть таблицы или индекс на поле с функцией
```sql
demo=# create index on bookings (date(book_date at time zone 'UTC'));
CREATE INDEX

demo=# explain select sum(total_amount) from bookings where date(book_date at time zone 'UTC') = '2017-07-29';
                                        QUERY PLAN
------------------------------------------------------------------------------------------
 Aggregate  (cost=1694.21..1694.22 rows=1 width=32)
   ->  Bitmap Heap Scan on bookings  (cost=18.61..1690.92 rows=1314 width=6)
         Recheck Cond: (date(timezone('UTC'::text, book_date)) = '2017-07-29'::date)
         ->  Bitmap Index Scan on bookings_date_idx  (cost=0.00..18.28 rows=1314 width=0)
               Index Cond: (date(timezone('UTC'::text, book_date)) = '2017-07-29'::date)
(5 rows)

demo=# drop index bookings_date_idx;
DROP INDEX
```
>Создать индекс на несколько полей  
```sql
demo=# create index on ticket_flights (flight_id, fare_conditions);
CREATE INDEX

demo=# explain select count(*) from ticket_flights where flight_id = 30625 and fare_conditions = 'Business';
                                                          QUERY PLAN
------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=4.58..4.59 rows=1 width=8)
   ->  Index Only Scan using ticket_flights_flight_id_fare_conditions_idx on ticket_flights  (cost=0.42..4.57 rows=7 width=0)
         Index Cond: ((flight_id = 30625) AND (fare_conditions = 'Business'::text))
(3 rows)

demo=# drop index ticket_flights_flight_id_fare_conditions_idx;
DROP INDEX
```
>Написать комментарии к каждому из индексов  
>Описать что и как делали и с какими проблемами столкнулись  

2 вариант:  
В результате выполнения ДЗ вы научитесь пользоваться различными вариантами соединения таблиц. В данном задании тренируются навыки:  
написания запросов с различными типами соединений  
Необходимо:  
>Реализовать прямое соединение двух или более таблиц  
```sql
demo=# explain select f.flight_no, ad.model from flights f inner join aircrafts_data ad on ad.aircraft_code = f.aircraft_code;
                                  QUERY PLAN
------------------------------------------------------------------------------
 Hash Join  (cost=1.20..852.30 rows=33121 width=39)
   Hash Cond: (f.aircraft_code = ad.aircraft_code)
   ->  Seq Scan on flights f  (cost=0.00..723.21 rows=33121 width=11)
   ->  Hash  (cost=1.09..1.09 rows=9 width=48)
         ->  Seq Scan on aircrafts_data ad  (cost=0.00..1.09 rows=9 width=48)
(5 rows)
```
>Реализовать левостороннее (или правостороннее) соединение двух или более таблиц  
```sql
demo=# explain select t.ticket_no, t.passenger_name, b.book_date, b.total_amount from tickets t left join bookings b on t.book_ref = b.book_ref;
                                  QUERY PLAN
-------------------------------------------------------------------------------
 Hash Left Join  (cost=7586.73..26169.75 rows=366733 width=44)
   Hash Cond: (t.book_ref = b.book_ref)
   ->  Seq Scan on tickets t  (cost=0.00..17620.33 rows=366733 width=37)
   ->  Hash  (cost=4301.88..4301.88 rows=262788 width=21)
         ->  Seq Scan on bookings b  (cost=0.00..4301.88 rows=262788 width=21)
(5 rows)
```
>Реализовать кросс соединение двух или более таблиц  
```sql
demo=# explain select * from aircrafts a cross join seats s;
                                  QUERY PLAN
------------------------------------------------------------------------------
 Nested Loop  (cost=0.00..3216.02 rows=12051 width=67)
   ->  Seq Scan on seats s  (cost=0.00..21.39 rows=1339 width=15)
   ->  Materialize  (cost=0.00..1.14 rows=9 width=52)
         ->  Seq Scan on aircrafts_data ml  (cost=0.00..1.09 rows=9 width=52)
(4 rows)
```
>Реализовать полное соединение двух или более таблиц  
```sql
demo=# explain select a.timezone, t.name from airports_data a full join pg_timezone_names t on a.timezone = t.name where a.timezone is null;
                                      QUERY PLAN                                       
---------------------------------------------------------------------------------------
 Hash Full Join  (cost=22.50..45.00 rows=1 width=47)
   Hash Cond: (a.timezone = pg_timezone_names.name)
   Filter: (a.timezone IS NULL)
   ->  Seq Scan on airports_data a  (cost=0.00..4.04 rows=104 width=15)
   ->  Hash  (cost=10.00..10.00 rows=1000 width=32)
         ->  Function Scan on pg_timezone_names  (cost=0.00..10.00 rows=1000 width=32)
(6 rows)
```
>Реализовать запрос, в котором будут использованы разные типы соединений  
```sql
demo=# explain       
select distinct arp.city, drp.city, ac.model
from flights f
inner join airports arp on f.arrival_airport = arp.airport_code
inner join airports drp on f.departure_airport = drp.airport_code
left join aircrafts ac on f.aircraft_code = ac.aircraft_code;
                                              QUERY PLAN                                               
-------------------------------------------------------------------------------------------------------
 Unique  (cost=20258.95..20590.16 rows=33121 width=96)
   ->  Sort  (cost=20258.95..20341.75 rows=33121 width=96)
         Sort Key: ((ml.city ->> lang())), ((ml_1.city ->> lang())), ((ml_2.model ->> lang()))
         ->  Hash Left Join  (cost=14.16..17772.31 rows=33121 width=96)
               Hash Cond: (f.aircraft_code = ml_2.aircraft_code)
               ->  Hash Join  (cost=10.68..914.85 rows=33121 width=102)
                     Hash Cond: (f.departure_airport = ml_1.airport_code)
                     ->  Hash Join  (cost=5.34..819.03 rows=33121 width=57)
                           Hash Cond: (f.arrival_airport = ml.airport_code)
                           ->  Seq Scan on flights f  (cost=0.00..723.21 rows=33121 width=12)
                           ->  Hash  (cost=4.04..4.04 rows=104 width=53)
                                 ->  Seq Scan on airports_data ml  (cost=0.00..4.04 rows=104 width=53)
                     ->  Hash  (cost=4.04..4.04 rows=104 width=53)
                           ->  Seq Scan on airports_data ml_1  (cost=0.00..4.04 rows=104 width=53)
               ->  Hash  (cost=3.36..3.36 rows=9 width=48)
                     ->  Seq Scan on aircrafts_data ml_2  (cost=0.00..3.36 rows=9 width=48)
(16 rows)
```
>Сделать комментарии на каждый запрос  
>К работе приложить структуру таблиц, для которых выполнялись соединения  
https://postgrespro.ru/docs/enterprise/11/apjs02
>Придумайте 3 своих метрики на основе показанных представлений, отправьте их через ЛК, а так же поделитесь с коллегами в слаке
