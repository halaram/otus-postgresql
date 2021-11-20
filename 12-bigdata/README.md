### Работа с большим объемом реальных данных

Цель:
знать различные механизмы загрузки данных
уметь пользоваться различными механизмами загрузки данных
Необходимо провести сравнение скорости работы 
запросов на различных СУБД

<b>Имя проекта - postgres2021-2147483647</b>

Создана ВМ otus12 с SSD диском 50GB.

>Выбрать одну из СУБД  

Для сравнения была установлена БД Oracle Database 21c Express Edition.  
Созданы пользователь taxi с необходимыми правами и таблица taxi_trips для загрузки данных.  

>Загрузить в неё данные (10 Гб)  

С помощью gcsfuse примонтирован bucket с данными сета chicago_taxi_trips и загружены данные инструментом sqlldr:  
```console
[oracle@otus12 taxi_2021_11_18]$ for i in {00..49}; do echo $i; sqlldr taxi/12345678@//127.0.0.1:1521/xepdb1 data=/mnt/taxi_2021_11_18/taxi_0000000000$i.csv control=/home/oracle/sqlldr_taxi.ctl log=/home/oracle/sqlldr_taxi_0000000000$i.log bad=/home/oracle/taxi_0000000000$i_bad.csv; done
```
Размер таблицы taxi_trips > 11GB, количество строк около 30 миллионов:
```sql
SQL> set timing on;

SQL> select BYTES/1024/1024/1024 from user_segments where SEGMENT_NAME = 'TAXI_TRIPS';

BYTES/1024/1024/1024
--------------------
          11.875

Elapsed: 00:00:00.00

SQL> select count(*) from taxi_trips;

  COUNT(*)
----------
  30558733

Elapsed: 00:07:46.05
```
Выполним sql-запрос с операциями группировки и сортировки для оценки скорости:
```sql
SQL> select payment_type, round(sum(tips)/sum(trip_total)*100, 0) + 0 as tips_percent, count(*) as c from taxi_trips group by payment_type order by 3;

PAYMENT_TYPE		       TIPS_PERCENT	     C
------------------------------ ------------ ----------
Way2ride				 15	    78
Prepaid 				  0	   104
Pcard					  3	  5765
Dispute 				  0	 17733
Mobile					 16	105705
Prcard					  1	105723
Unknown 				  1	123040
No Charge				  3	152079
Credit Card				 17   12602360
Cash					  0   17446146

10 rows selected.

Elapsed: 00:07:54.50
```
>Сравнить скорость выполнения запросов на PosgreSQL и выбранной СУБД
>Описать что и как делали и с какими проблемами столкнулись
