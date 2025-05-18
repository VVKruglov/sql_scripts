CREATE TABLE nw.customers_crud (
    customer_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE nw.orders_crud (
    order_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES nw.customers_crud(customer_id) ON DELETE CASCADE,
    order_date TIMESTAMP DEFAULT now(),
    total_amount NUMERIC(10, 2) CHECK (total_amount >= 0)
);



--CREATE — Вставка данных

--Добавь 5 клиентов в таблицу customers.

CREATE OR REPLACE PROCEDURE nw.create_customer_crud(p_name TEXT, p_email TEXT)
AS $$
BEGIN 
INSERT INTO nw.customers_crud ("name", email)
VALUES (p_name, p_email);

RAISE NOTICE 'Клиент добавлен';
END;
$$ LANGUAGE plpgsql;

CALL nw.create_customer_crud('House', 'house@mail.ru');

SELECT *
FROM nw.customers_crud cc;


--Вставь 3 заказа для одного клиента.

CREATE OR REPLACE PROCEDURE nw.create_order_crud(p_customer_id INT, p_total_amount INT)
AS $$
BEGIN
INSERT INTO nw.orders_crud (customer_id, total_amount)
VALUES (p_customer_id, p_total_amount);
RAISE NOTICE 'Заказ добавлен';
END;
$$ LANGUAGE plpgsql;

CALL nw.create_order_crud(1, 5);

SELECT *
FROM nw.orders_crud oc;



--READ — Чтение данных

--Выбери всех клиентов.

CREATE OR REPLACE FUNCTION nw.get_all_customers()
RETURNS TABLE 
(
customer_id INT,
"name" TEXT,
email TEXT,
created_at TIMESTAMP
)
AS $$
BEGIN 
RETURN QUERY
SELECT 
    cc.customer_id::INT,
    cc."name"::TEXT,
    cc.email::TEXT,
    cc.created_at::TIMESTAMP
FROM nw.customers_crud AS cc;
END;
$$ LANGUAGE plpgsql;

SELECT* FROM nw.get_all_customers();

SELECT * FROM nw.get_all_orders


--Найди сумму всех заказов клиента с ID = 2.

CREATE OR REPLACE FUNCTION nw.get_total_amount_for_customer(p_customer_id INT)
RETURNS TABLE 
(
name TEXT,
total_amount NUMERIC
)
AS $$
BEGIN
RETURN QUERY 
SELECT 
    cc."name"::TEXT,
    SUM(oc.total_amount)::NUMERIC
FROM nw.customers_crud AS cc
    INNER JOIN nw.orders_crud AS oc ON cc.customer_id = oc.customer_id
WHERE cc.customer_id = p_customer_id
GROUP BY cc."name";
END;
$$ LANGUAGE plpgsql;

SELECT * FROM nw.get_total_amount_for_customer(1);



--UPDATE — Обновление данных

--Обнови email клиента с ID = 3.
CREATE OR REPLACE PROCEDURE nw.set_new_email(p_new_email TEXT, p_customer_id INT)
AS $$
BEGIN
    UPDATE nw.customers_crud 
    SET email = p_new_email
    WHERE customer_id = p_customer_id;
RAISE NOTICE 'Email был изменен';
END;
$$ LANGUAGE plpgsql;

CALL nw.set_new_email('rebrand@mail.ru', 3);
SELECT* FROM nw.get_all_customers();


--Удаление клиента по ID

CREATE OR REPLACE PROCEDURE nw.delete_customer(p_customer_id INT)
AS $$
BEGIN
    -- Проверка существования клиента
    IF EXISTS (SELECT 1 FROM nw.customers_crud WHERE customer_id = p_customer_id) THEN
        DELETE FROM nw.customers_crud 
        WHERE customer_id = p_customer_id;
        RAISE NOTICE 'Клиент с ID % и его заказы удалены', p_customer_id;
    ELSE
        RAISE EXCEPTION 'Клиент с ID % не найден', p_customer_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

CALL nw.delete_customer(2);
