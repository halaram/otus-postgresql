### Секционирование таблицы

Цель: научиться секционировать таблицы.  

<b>Имя проекта - postgres2021-2147483647</b>

>Секционировать большую таблицу из демо базы flights

Импортируем демонстрационную базу данных Postgres Pro
```console
-bash-4.2$ psql < demo-big-20170815.sql
```
Проверим пераметр enable_partition_pruning:  
```sql
demo=# show enable_partition_pruning;
 enable_partition_pruning 
--------------------------
 on
(1 row)
```
Список таблиц БД demo:  
```sql
postgres=# \c demo 
You are now connected to database "demo" as user "postgres".
demo=# \dt+
                                                List of relations
  Schema  |      Name       | Type  |  Owner   | Persistence | Access method |  Size  |        Description        
----------+-----------------+-------+----------+-------------+---------------+--------+---------------------------
 bookings | aircrafts_data  | table | postgres | permanent   | heap          | 16 kB  | Aircrafts (internal data)
 bookings | airports_data   | table | postgres | permanent   | heap          | 56 kB  | Airports (internal data)
 bookings | boarding_passes | table | postgres | permanent   | heap          | 455 MB | Boarding passes
 bookings | bookings        | table | postgres | permanent   | heap          | 105 MB | Bookings
 bookings | flights         | table | postgres | permanent   | heap          | 21 MB  | Flights
 bookings | seats           | table | postgres | permanent   | heap          | 96 kB  | Seats
 bookings | ticket_flights  | table | postgres | permanent   | heap          | 547 MB | Flight segment
 bookings | tickets         | table | postgres | permanent   | heap          | 386 MB | Tickets
(8 rows)
```
Для секционирование была выбрана таблица bookings:  
```sql
demo=# \d bookings
                        Table "bookings.bookings"
    Column    |           Type           | Collation | Nullable | Default 
--------------+--------------------------+-----------+----------+---------
 book_ref     | character(6)             |           | not null | 
 book_date    | timestamp with time zone |           | not null | 
 total_amount | numeric(10,2)            |           | not null | 
Indexes:
    "bookings_pkey" PRIMARY KEY, btree (book_ref)
Referenced by:
    TABLE "tickets" CONSTRAINT "tickets_book_ref_fkey" FOREIGN KEY (book_ref) REFERENCES bookings(book_ref)
```
Создадим таблицу bookings_base, секционированную по диапазону поля book_date, с такой же структурой как bookings:  
```sql
demo=# create table bookings_base (book_ref character(6), book_date timestamp with time zone, total_amount numeric(10,2)) partition by range (book_date);
CREATE TABLE
```
В секциях будут хранится данные по суткам. Секции создаются с помощью скрипта PL/pgSQL:  
```console
-bash-4.2$ cat generate_bookings_partitions.sql 
DO $$
DECLARE
    dt date;
BEGIN
    FOR dt IN
    SELECT distinct date(book_date) FROM bookings ORDER BY 1
    LOOP
    RAISE NOTICE '%', dt;
    EXECUTE format('CREATE TABLE IF NOT EXISTS bookings_%s PARTITION OF bookings_base FOR VALUES FROM (%L) TO (%L)', to_char(dt, 'YYYYMMDD'), dt, dt + INTERVAL '1 day');
    END LOOP;
END;
$$ LANGUAGE plpgsql;
```

```sql
demo=# \i generate_bookings_partitions.sql
psql:generate_bookings_partitions.sql:12: NOTICE:  2016-07-20
psql:generate_bookings_partitions.sql:12: NOTICE:  2016-07-21
psql:generate_bookings_partitions.sql:12: NOTICE:  2016-07-22
...
psql:generate_bookings_partitions.sql:12: NOTICE:  2017-08-14
psql:generate_bookings_partitions.sql:12: NOTICE:  2017-08-15
DO
```
Получилось 392 партиции:  
```sql
demo=# \d bookings_base 
                Partitioned table "bookings.bookings_base"
    Column    |           Type           | Collation | Nullable | Default 
--------------+--------------------------+-----------+----------+---------
 book_ref     | character(6)             |           |          | 
 book_date    | timestamp with time zone |           |          | 
 total_amount | numeric(10,2)            |           |          | 
Partition key: RANGE (book_date)
Number of partitions: 392 (Use \d+ to list them.)
```
Наполним данными таблицу:  
```sql
demo=# insert into bookings_base select * from bookings;
INSERT 0 2111110
```
Выполним и сравним запрос за сутки к обычной таблице bookings и секционированной bookings_base:  
```sql
demo=# explain analyze select * from bookings where book_date = '2017-07-27'::date;
                                                        QUERY PLAN                                                        
--------------------------------------------------------------------------------------------------------------------------
 Gather  (cost=1000.00..25442.86 rows=5 width=21) (actual time=95.678..273.819 rows=3 loops=1)
   Workers Planned: 2
   Workers Launched: 2
   ->  Parallel Seq Scan on bookings  (cost=0.00..24442.36 rows=2 width=21) (actual time=127.474..264.416 rows=1 loops=3)
         Filter: (book_date = '2017-07-27'::date)
         Rows Removed by Filter: 703702
 Planning Time: 0.069 ms
 Execution Time: 273.848 ms
(8 rows)

demo=# explain analyze select * from bookings_base where book_date = '2017-07-27'::date;
                                                                    QUERY PLAN                                                                    
--------------------------------------------------------------------------------------------------------------------------------------------------
 Gather  (cost=1000.00..30380.26 rows=1547 width=21) (actual time=6.344..28.404 rows=3 loops=1)
   Workers Planned: 2
   Workers Launched: 2
   ->  Parallel Append  (cost=0.00..29225.56 rows=397 width=21) (actual time=0.048..0.373 rows=1 loops=3)
         Subplans Removed: 391
         ->  Parallel Seq Scan on bookings_20170727 bookings_base_1  (cost=0.00..76.76 rows=2 width=21) (actual time=0.135..1.108 rows=3 loops=1)
               Filter: (book_date = '2017-07-27'::date)
               Rows Removed by Filter: 5541
 Planning Time: 6.866 ms
 Execution Time: 28.475 ms
(10 rows)
```
Запрос за период, с подсчётом итоговой суммы по суткам:  
```sql
demo=# explain analyze select book_date, sum(total_amount) from bookings where book_date between '2017-07-24'::date and '2017-07-27'::date group by book_date;
                                                             QUERY PLAN                                                             
------------------------------------------------------------------------------------------------------------------------------------
 HashAggregate  (cost=29456.68..29669.54 rows=17029 width=40) (actual time=300.642..304.436 rows=4220 loops=1)
   Group Key: book_date
   Batches: 1  Memory Usage: 2193kB
   ->  Gather  (cost=1000.00..29370.24 rows=17288 width=14) (actual time=0.566..275.592 rows=16632 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Parallel Seq Scan on bookings  (cost=0.00..26641.44 rows=7203 width=14) (actual time=0.145..277.655 rows=5544 loops=3)
               Filter: ((book_date >= '2017-07-24'::date) AND (book_date <= '2017-07-27'::date))
               Rows Removed by Filter: 698159
 Planning Time: 0.152 ms
 Execution Time: 304.795 ms
(11 rows)

demo=# explain analyze select book_date, sum(total_amount) from bookings_base where book_date between '2017-07-24'::date and '2017-07-27'::date group by book_date;
                                                                                QUERY PLAN                                                                                
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Finalize GroupAggregate  (cost=33417.46..33469.63 rows=200 width=40) (actual time=44.516..50.170 rows=4220 loops=1)
   Group Key: bookings_base.book_date
   ->  Gather Merge  (cost=33417.46..33464.13 rows=400 width=40) (actual time=44.500..46.147 rows=4725 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Sort  (cost=32417.43..32417.93 rows=200 width=40) (actual time=13.220..13.467 rows=1575 loops=3)
               Sort Key: bookings_base.book_date
               Sort Method: quicksort  Memory: 783kB
               Worker 0:  Sort Method: quicksort  Memory: 98kB
               Worker 1:  Sort Method: quicksort  Memory: 25kB
               ->  Partial HashAggregate  (cost=32407.29..32409.79 rows=200 width=40) (actual time=10.592..12.400 rows=1575 loops=3)
                     Group Key: bookings_base.book_date
                     Batches: 1  Memory Usage: 2017kB
                     Worker 0:  Batches: 1  Memory Usage: 313kB
                     Worker 1:  Batches: 1  Memory Usage: 40kB
                     ->  Parallel Append  (cost=0.00..32370.69 rows=7320 width=14) (actual time=0.017..6.801 rows=5544 loops=3)
                           Subplans Removed: 388
                           ->  Parallel Seq Scan on bookings_20170725 bookings_base_2  (cost=0.00..85.42 rows=3294 width=14) (actual time=0.019..4.892 rows=2800 loops=2)
                                 Filter: ((book_date >= '2017-07-24'::date) AND (book_date <= '2017-07-27'::date))
                           ->  Parallel Seq Scan on bookings_20170727 bookings_base_4  (cost=0.00..84.92 rows=2 width=14) (actual time=0.205..1.821 rows=3 loops=1)
                                 Filter: ((book_date >= '2017-07-24'::date) AND (book_date <= '2017-07-27'::date))
                                 Rows Removed by Filter: 5541
                           ->  Parallel Seq Scan on bookings_20170724 bookings_base_1  (cost=0.00..84.91 rows=3260 width=14) (actual time=0.011..4.219 rows=5543 loops=1)
                                 Filter: ((book_date >= '2017-07-24'::date) AND (book_date <= '2017-07-27'::date))
                           ->  Parallel Seq Scan on bookings_20170726 bookings_base_3  (cost=0.00..83.40 rows=3226 width=14) (actual time=0.019..2.561 rows=5485 loops=1)
                                 Filter: ((book_date >= '2017-07-24'::date) AND (book_date <= '2017-07-27'::date))
 Planning Time: 11.656 ms
 Execution Time: 50.589 ms
(28 rows)
```
<b>
Как видно по результам explain время выполнения запросов, в которых используются партиции, существенно меньше за счёт уменьшения количества операций последовательного чтения из-за устранения секций (Subplans Removed: 391 ..388)  
Так же заметна разница во времени, затрачиваемом планировщиком на составление плана. Планирование запроса к секционированной таблице занимает намного больше времени.  
</b>
