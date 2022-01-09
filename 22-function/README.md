### Триггеры, поддержка заполнения витрин

Цель:
 Создать триггер для поддержки витрины в актуальном состоянии.
 
Стенд разворачивается автоматически с помощью Vagrant Ansible Provisioner.

>Скрипт и развернутое описание задачи – в ЛК (файл hw_triggers.sql) или по ссылке:  https://disk.yandex.ru/d/l70AvknAepIJXQ

>В БД создана структура, описывающая товары (таблица goods) и продажи (таблица sales).
>Есть запрос для генерации отчета – сумма продаж по каждому товару.
>БД была денормализована, создана таблица (витрина), структура которой повторяет структуру отчета.

Создание схемы и таблиц:
```console
-bash-4.2$ psql otus -f /vagrant/hw_triggers-223066-703e15.txt
```
Для таблицы good_sum_mart логично добавить первичный ключ:
```sql
ALTER TABLE good_sum_mart ADD PRIMARY KEY (good_name);
```

>Создать триггер на таблице продаж, для поддержки данных в витрине в актуальном состоянии (вычисляющий при каждой продаже сумму и записывающий её в витрину)
>Подсказка: не забыть, что кроме INSERT есть еще UPDATE и DELETE

Создадим триггерную функцию и триггер на таблицу support_good_sum_mart [trigger.sql](trigger.sql):
```console
-bash-4.2$ psql otus -f /vagrant/trigger.sql
```

Проверка работы триггера: 
- insert
```sql
otus=# set search_path = pract_functions, public;
SET
otus=# INSERT INTO sales (good_id, sales_qty) VALUES (1, 10), (1, 1), (1, 120), (2, 1);
INSERT 0 4

otus=# select * from sales;
 sales_id | good_id |          sales_time           | sales_qty 
----------+---------+-------------------------------+-----------
        1 |       1 | 2022-01-09 17:19:42.667316+00 |        10
        2 |       1 | 2022-01-09 17:19:42.667316+00 |         1
        3 |       1 | 2022-01-09 17:19:42.667316+00 |       120
        4 |       2 | 2022-01-09 17:19:42.667316+00 |         1
(4 rows)

otus=# select * from good_sum_mart;
        good_name         |   sum_sale   
--------------------------+--------------
 Спички хозайственные     |        65.50
 Автомобиль Ferrari FXX K | 185000000.01
(2 rows)
```
- update
```sql
otus=# update sales set sales_qty = 2 where sales_id = 4;
UPDATE 1

otus=# select * from good_sum_mart;
        good_name         |   sum_sale   
--------------------------+--------------
 Спички хозайственные     |        65.50
 Автомобиль Ferrari FXX K | 370000000.02
(2 rows)
```
- delete
```sql
otus=# delete from sales where sales_id = 2;
DELETE 1

otus=# select * from good_sum_mart;
        good_name         |   sum_sale   
--------------------------+--------------
 Автомобиль Ferrari FXX K | 370000000.02
 Спички хозайственные     |        65.00
(2 rows)
```

Сравнение результата с запросом "отчёта":
```sql
otus=# SELECT G.good_name, sum(G.good_price * S.sales_qty)
FROM goods G
INNER JOIN sales S ON S.good_id = G.goods_id
GROUP BY G.good_name;
        good_name         |     sum      
--------------------------+--------------
 Автомобиль Ferrari FXX K | 370000000.02
 Спички хозайственные     |        65.00
(2 rows)
```
>Чем такая схема (витрина+триггер) предпочтительнее отчета, создаваемого "по требованию" (кроме производительности)? Подсказка: В реальной жизни возможны изменения цен.

При именении цены (good_price) в таблице goods и продажах - вставке новых значений в таблицу sales или изменении, отчёт запросом будет возвращать некорректные значения. В отчёте "по требованию" все продажи, включая старые, будут посчитаны по новой цене.  

Витрина+триггер решают задачу получения отчета по продажам при изменении цены, но только для операций insert.  
Изменения количества продаж (update) и отмены (delete) всё так же могут приводить к некорректным результатам в good_sum_mart. Например может быть отменена или изменена старая продажа, но уже по новой цене.  


- Добавим новый вид товара:
```sql
otus=# INSERT INTO goods (goods_id, good_name, good_price) VALUES (3, 'Крупа гречневая', 50);
INSERT 0 1
```
- Проведём продажу (insert) 2кг:
```sql
otus=# insert into sales (good_id, sales_qty) VALUES (3, 2);
INSERT 0 1
```
- Пока всё нормально и с отчётом по "по требованию" и с витриной:
```sql
otus=# SELECT sum(G.good_price * S.sales_qty)
FROM goods G
INNER JOIN sales S ON S.good_id = G.goods_id WHERE G.good_name = 'Крупа гречневая' 
GROUP BY G.good_name;
  sum   
--------
 100.00

otus=# select sum_sale from good_sum_mart where good_name = 'Крупа гречневая';
 sum_sale 
----------
   100.00
```
- Изменим цену, отчёт по требования возвращает "неправильный" итог 200, в витрине всё верно - 100:
```sql
otus=# update goods set good_price = 100 where good_name = 'Крупа гречневая';
UPDATE 1

otus=# select sum_sale from good_sum_mart where good_name = 'Крупа гречневая';
 sum_sale 
----------
   100.00
(1 row)

otus=# SELECT sum(G.good_price * S.sales_qty)
FROM goods G
INNER JOIN sales S ON S.good_id = G.goods_id WHERE G.good_name = 'Крупа гречневая' 
GROUP BY G.good_name;
  sum   
--------
 200.00
```

- Проведем возврат (delete), витрина cломалась:
```sql
otus=# delete from sales where sales_id = 5;
DELETE 1

otus=# select sum_sale from good_sum_mart where good_name = 'Крупа гречневая';
 sum_sale 
----------
  -100.00
(1 row)
```
