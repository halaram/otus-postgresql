SET search_path = pract_functions, public;

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

CREATE TRIGGER support_good_sum_mart
    AFTER INSERT OR UPDATE OR DELETE ON sales
    FOR EACH ROW EXECUTE FUNCTION support_good_sum_mart();
