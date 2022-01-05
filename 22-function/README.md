Домашнее задание
Триггеры, поддержка заполнения витрин

Цель:
 Создать триггер для поддержки витрины в актуальном состоянии.

Скрипт и развернутое описание задачи – в ЛК (файл hw_triggers.sql) или по ссылке:  https://disk.yandex.ru/d/l70AvknAepIJXQ

В БД создана структура, описывающая товары (таблица goods) и продажи (таблица sales).
Есть запрос для генерации отчета – сумма продаж по каждому товару.
БД была денормализована, создана таблица (витрина), структура которой повторяет структуру отчета.

```sql
ALTER TABLE good_sum_mart ADD PRIMARY KEY (good_name);
```

Создать триггер на таблице продаж, для поддержки данных в витрине в актуальном состоянии (вычисляющий при каждой продаже сумму и записывающий её в витрину)
Подсказка: не забыть, что кроме INSERT есть еще UPDATE и DELETE

```sql
CREATE OR REPLACE FUNCTION support_good_sum_mart() RETURNS TRIGGER AS $support_good_sum_mart$
    DECLARE
    v_delta_qty integer;
    v_good_id integer;
    BEGIN
    IF (TG_OP = 'DELETE') THEN
        v_delta_qty = 0 - OLD.sales_qty;
        v_good_id = OLD.good_id;
    ELSIF (TG_OP = 'UPDATE') THEN
        v_delta_qty = NEW.sales_qty - OLD.sales_qty;
        v_good_id = OLD.good_id;
    ELSIF (TG_OP = 'INSERT') THEN
        v_delta_qty = NEW.sales_qty;
        v_good_id = NEW.good_id;
    END IF;

    INSERT INTO good_sum_mart (good_name, sum_sale)
        SELECT good_name , good_price * v_delta_qty
        FROM goods WHERE goods_id = v_good_id
    ON CONFLICT ON CONSTRAINT good_sum_mart_pkey
    DO UPDATE SET sum_sale = good_sum_mart.sum_sale + EXCLUDED.sum_sale
        WHERE good_sum_mart.good_name = EXCLUDED.good_name;

    RETURN NULL;
    END;
$support_good_sum_mart$ LANGUAGE plpgsql;
```

```sql
CREATE TRIGGER support_good_sum_mart
    AFTER INSERT OR UPDATE OR DELETE ON sales
    FOR EACH ROW EXECUTE FUNCTION support_good_sum_mart();
```

Чем такая схема (витрина+триггер) предпочтительнее отчета, создаваемого "по требованию" (кроме производительности)? Подсказка: В реальной жизни возможны изменения цен.
