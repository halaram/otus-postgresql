### Работа с большим объемом реальных данных

Цель:
знать различные механизмы загрузки данных  
уметь пользоваться различными механизмами загрузки данных  
Необходимо провести сравнение скорости работы запросов на различных СУБД

<b>Имя проекта - postgres2021-2147483647</b>

Создана ВМ otus12 с SSD диском 50GB.

>Выбрать одну из СУБД  

Для сравнения была установлена БД Oracle Database 21c Express Edition.  
Созданы пользователь taxi с необходимыми правами и таблица TAXI_TRIPS для загрузки данных.  

>Загрузить в неё данные (10 Гб)  

- С помощью gcsfuse примонтирован bucket с данными сета chicago_taxi_trips и загружены данные инструментом sqlldr:  
```console
[oracle@otus12 taxi_2021_11_18]$ for i in {00..39}; do sqlldr taxi/12345678@//127.0.0.1:1521/xepdb1 data=/mnt/taxi_2021_11_18/taxi_0000000000$i.csv control=/home/oracle/sqlldr_taxi.ctl log=/home/oracle/sqlldr_taxi_0000000000$i.log bad=/home/oracle/taxi_0000000000$i_bad.csv; done
```
- Основные настройки распределения памяти sga и pga:
```sql
SQL> show parameter sga;

NAME				     TYPE	 VALUE
------------------------------------ ----------- ------------------------------
allow_group_access_to_sga	     boolean	 FALSE
lock_sga			     boolean	 FALSE
pre_page_sga			     boolean	 TRUE
sga_max_size			     big integer 1136M
sga_min_size			     big integer 0
sga_target			     big integer 1136M
SQL> show parameter pga;

NAME				     TYPE	 VALUE
------------------------------------ ----------- ------------------------------
pga_aggregate_limit		     big integer 2G
pga_aggregate_target		     big integer 378M
```
- Размер таблицы taxi_trips > 10GB, количество строк около 26 миллионов:
```sql
SQL> set timing on;

SQL> select BYTES/1024/1024/1024 from user_segments where SEGMENT_NAME = 'TAXI_TRIPS';

BYTES/1024/1024/1024
--------------------
         10.0625

Elapsed: 00:00:00.11

SQL> select count(*) from taxi_trips;

  COUNT(*)
----------
  26023348

Elapsed: 00:06:25.27
```
- Выполним sql-запросы с операциями группировки и сортировки для оценки времени:
```sql
SQL> select payment_type, round(sum(tips)/sum(trip_total)*100, 0) + 0 as tips_percent, count(*) as c from taxi_trips group by payment_type order by 3;

PAYMENT_TYPE	     TIPS_PERCENT	   C
-------------------- ------------ ----------
Prepaid 			0	  76
Way2ride		       15	  78
Pcard				3	5302
Dispute 			0      14685
Mobile			       15      32883
Prcard				1      41463
Unknown 			2      68591
No Charge			3     131855
Credit Card		       17   10714146
Cash				0   15014269

10 rows selected.

Elapsed: 00:06:27.42

SQL> select company, count(*) as c, sum(trip_seconds) as s_sec, sum(trip_miles) as s_mil from taxi_trips group by company order by 2;

COMPANY 						    C	   S_SEC      S_MIL
-------------------------------------------------- ---------- ---------- ----------
2809 - 95474 C&D Cab Co Inc.				    1	     540	1.5
3669 - Jordan Taxi Inc					    3	       0	  0
0118 - Godfray S.Awir					    5	    2760       10.8
American United Cab Association 			    5	       0	  0
...
Northwest Management LLC			       732268  542881500  2160686.4
Choice Taxi Association 			      1379440 1125522960  4952431.1
Blue Ribbon Taxi Association Inc.		      1772906 1326451140   265605.1
Dispatch Taxi Affiliation			      2260433 1693494540  7334346.2
						      6772883 5551877584 33967146.4
Taxi Affiliation Services			      7878710 6031986480 17136242.4

155 rows selected.

Elapsed: 00:06:25.12
```
>Сравнить скорость выполнения запросов на PosgreSQL и выбранной СУБД
- Установлен PostgreSQL 14, созданы БД, роль и таблица для загрузки данных:
```sql
postgres=# create user taxi password '12345678';
CREATE ROLE
taxi=# grant pg_read_server_files to taxi;
GRANT ROLE
postgres=# create database taxi owner taxi;
CREATE DATABASE
```

```sql
create table taxi_trips (
unique_key varchar(255),
taxi_id varchar(255),
trip_start_timestamp TIMESTAMP,
trip_end_timestamp TIMESTAMP,
trip_seconds integer,
trip_miles numeric,
pickup_census_tract bigint,
dropoff_census_tract bigint,
pickup_community_area integer,
dropoff_community_area integer,
fare numeric, 
tips numeric,
tolls numeric,
extras numeric,
trip_total numeric,
payment_type varchar(255),
company varchar(255), 
pickup_latitude numeric,
pickup_longitude numeric,
pickup_location varchar(255), 
dropoff_latitude numeric, 
dropoff_longitude numeric, 
dropoff_location varchar(255)
);
```
- Проведена загрузка данных:
```console
-bash-4.2$ for i in {00..39}; do psql -U taxi taxi -c "COPY taxi_trips(unique_key, taxi_id, trip_start_timestamp, trip_end_timestamp, trip_seconds, trip_miles, pickup_census_tract, dropoff_census_tract, pickup_community_area, dropoff_community_area, fare, tips, tolls, extras, trip_total, payment_type, company, pickup_latitude, pickup_longitude, pickup_location, dropoff_latitude, dropoff_longitude, dropoff_location) FROM '/mnt/taxi_2021_11_18/taxi_0000000000$i.csv' DELIMITER ',' CSV HEADER;"; done
COPY 653524
COPY 653941
COPY 667159
...
COPY 650051
COPY 670246
COPY 668752
```
- Объём таблицы taxi_trips 10GB, количество записей 26 миллионов:
```sql
postgres=# \c taxi 
You are now connected to database "taxi" as user "postgres".
taxi=# \dt+ taxi_trips
                                    List of relations
 Schema |    Name    | Type  | Owner | Persistence | Access method | Size  | Description 
--------+------------+-------+-------+-------------+---------------+-------+-------------
 public | taxi_trips | table | taxi  | permanent   | heap          | 10 GB | 

taxi=# \timing on
Timing is on.
taxi=# select count(*) from taxi_trips;
  count   
----------
 26023348
(1 row)

Time: 455565.028 ms (07:35.565)
```
- Повторим sql-запросы с операциями группировки и сортировки для оценки времени, выполненные в БД Oracle:
```sql
taxi=# select payment_type, round(sum(tips)/sum(trip_total)*100, 0) + 0 as tips_percent, count(*) as c from taxi_trips group by payment_type order by 3;
 payment_type | tips_percent |    c     
--------------+--------------+----------
 Prepaid      |            0 |       76
 Way2ride     |           15 |       78
 Pcard        |            3 |     5302
 Dispute      |            0 |    14685
 Mobile       |           15 |    32883
 Prcard       |            1 |    41463
 Unknown      |            2 |    68591
 No Charge    |            3 |   131855
 Credit Card  |           17 | 10714146
 Cash         |            0 | 15014269
(10 rows)

Time: 337405.848 ms (05:37.406)

taxi=# select company, count(*) as c, sum(trip_seconds) as s_sec, sum(trip_miles) as s_mil from taxi_trips group by company order by 2;
                   company                    |    c    |   s_sec    |    s_mil    
----------------------------------------------+---------+------------+-------------
 2809 - 95474 C&D Cab Co Inc.                 |       1 |        540 |         1.5
 3669 - Jordan Taxi Inc                       |       3 |          0 |           0
 0118 - Godfray S.Awir                        |       5 |       2760 |        10.8
 American United Cab Association              |       5 |          0 |           0
...
 Northwest Management LLC                     |  732268 |  542881500 |   2160686.4
 Choice Taxi Association                      | 1379440 | 1125522960 |   4952431.1
 Blue Ribbon Taxi Association Inc.            | 1772906 | 1326451140 |    265605.1
 Dispatch Taxi Affiliation                    | 2260433 | 1693494540 |   7334346.2
                                              | 6772883 | 5551877584 | 33967146.42
 Taxi Affiliation Services                    | 7878710 | 6031986480 |  17136242.4
(155 rows)

Time: 337082.958 ms (05:37.083)
```
>Описать что и как делали и с какими проблемами столкнулись
