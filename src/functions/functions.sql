--Напиши функцию, которая принимает order_id и возвращает общую сумму заказа с учетом скидки.
--Вывести: total_amount

CREATE OR REPLACE FUNCTION nw.get_total_amount(p_order_id INT)
RETURNS NUMERIC 
AS $$
DECLARE
    total_amount NUMERIC;
BEGIN
    SELECT ROUND(SUM(od.quantity*od.unit_price*(1 - od.discount))::NUMERIC, 2)
    INTO total_amount
    FROM nw.order_details AS od 
    WHERE od.order_id = p_order_id;

    RETURN total_amount;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM nw.get_total_amount(10655);


--Напиши функцию, которая принимает customer_id и возвращает таблицу
--с order_id, order_date, total_amount.

CREATE OR REPLACE FUNCTION nw.get_total_amount_of_customer(p_customer_id TEXT)
RETURNS TABLE
    (
    order_id SMALLINT,
    order_date DATE,
    total_amount NUMERIC
    )
AS $$
BEGIN
RETURN QUERY
SELECT
    o.order_id,
    o.order_date,
    ROUND((SUM(od.quantity*od.unit_price*(1 - od.discount)))::NUMERIC, 2) AS total_amount      
FROM nw.customers AS c
    INNER JOIN nw.orders AS o ON c.customer_id = o.customer_id
    INNER JOIN nw.order_details AS od ON o.order_id = od.order_id
WHERE c.customer_id = p_customer_id
GROUP BY c.customer_id, o.order_id, o.order_date;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM nw.get_total_amount_of_customer('ANATR');


--Напиши функцию, которая принимает product_id и возвращает текстовое описание:
--"Дешевый" — если цена < 10
--"Средний" — если от 10 до 50
--"Дорогой" — если больше 50
--Вывести: product_id, category_name, unit_price, price_category

CREATE OR REPLACE FUNCTION nw.get_price_category(p_product_name TEXT)
RETURNS TABLE
(
    product_name TEXT,
    category_name TEXT,
    unit_price NUMERIC,
    price_catrgory TEXT
)
AS $$
BEGIN 
RETURN QUERY
SELECT
    p.product_name::TEXT,
    c.category_name::TEXT,
    p.unit_price::NUMERIC,
    (CASE 
        WHEN p.unit_price < 10 
        THEN 'Дешевый'
        WHEN p.unit_price > 50
        THEN 'Дорогой'
        ELSE 'Средний'
    END)::TEXT as price_catrgory    
FROM nw.categories AS c
    INNER JOIN nw.products AS p ON c.category_id = p.category_id
WHERE p.product_name=p_product_name;
END; 
$$ LANGUAGE plpgsql;



SELECT * FROM nw.get_price_category('Pavlova');



--Напиши функцию, которая принимает customer_id и возвращает:
--"Активный" — если у клиента есть хотя бы один заказ
--"Неактивный" — если заказов нет    

CREATE OR REPLACE FUNCTION nw.get_customer_status(p_customer_id TEXT)
RETURNS TEXT 
AS $$
DECLARE
    v_status TEXT;

BEGIN

    SELECT
CASE 
    WHEN EXISTS(SELECT 1
                FROM nw.orders AS o
                WHERE p_customer_id = o.customer_id)
    THEN 'Активный'
    ELSE 'Неактивный'
END
    INTO v_status; 

RETURN v_status;

END;
$$ LANGUAGE plpgsql;

SELECT * FROM nw.get_customer_status('VINET')



--Реализуйте функцию, которая принимает product_id и
--возвращает количество оставшихся на складе товаров.

CREATE OR REPLACE FUNCTION nw.get_units_in_stock(p_roduct_id INT)
RETURNS INT 
AS $$
DECLARE 
    v_units_in_stock INT;
BEGIN
    SELECT
        p.units_in_stock INTO v_units_in_stock
    FROM nw.products as p
    WHERE p.product_id = p_roduct_id;

    RETURN v_units_in_stock;

    RAISE NOTICE 'Функция выполнена успешно';
END;
$$ LANGUAGE plpgsql;

SELECT * FROM nw.get_units_in_stock(11)



--Создайте функцию, которая принимает дату и 
--возвращает количество заказов, сделанных в этот день.   

CREATE OR REPLACE FUNCTION nw.get_orders_for_date(p_order_date DATE)
RETURNS INT
AS $$
DECLARE 
    v_count_orders INT;
BEGIN 
    SELECT
        COUNT(o.order_id) INTO v_count_orders
    FROM nw.orders AS o 
    WHERE o.order_date = p_order_date;
RETURN v_count_orders;
END;
$$ LANGUAGE plpgsql;


SELECT 
    pg_typeof(o.order_date)
FROM nw.orders o 
LIMIT 1;

SELECT * FROM nw.get_orders_for_date('1996-07-08')



--Выведите список заказов с указанием, какая часть от общего
--количества заказов приходится на каждого клиента.

CREATE OR REPLACE FUNCTION nw.get_table_percent_customers_orders()
RETURNS TABLE 
(
    company_name TEXT,
    percent_of_total NUMERIC
)
AS $$
DECLARE 
    v_total_count NUMERIC;
BEGIN
    SELECT
        COUNT(o.order_id) INTO v_total_count
    FROM nw.orders as o;

    RETURN QUERY
    SELECT
    c.company_name::TEXT,
    ROUND((COUNT(o.order_id)/v_total_count*100)::NUMERIC, 2)
FROM nw.customers AS c 
    INNER JOIN nw.orders AS o ON c.customer_id = o.customer_id
GROUP BY c.customer_id;
END; 
$$ LANGUAGE plpgsql;

SELECT * FROM nw.get_table_percent_customers_orders();



--Определите заказы, где сумма заказа выше среднего по всем заказам (OVER() + AVG()).

CREATE OR REPLACE FUNCTION nw.get_order_over_avg_total()
RETURNS TABLE 
(
    order_id INT,
    sum_order NUMERIC
)
AS $$
DECLARE 
    v_avg_total NUMERIC;
BEGIN
    -- Рассчитываем среднюю сумму заказа
    WITH order_totals AS (
        SELECT
            o.order_id,
            SUM(od.quantity * od.unit_price * (1 - od.discount)) AS total
        FROM nw.orders AS o
        INNER JOIN nw.order_details AS od ON o.order_id = od.order_id
        GROUP BY o.order_id
    )
    SELECT ROUND(AVG(total)::NUMERIC, 2)
    INTO v_avg_total
    FROM order_totals;

    -- Возвращаем заказы, сумма которых больше средней
    RETURN QUERY
    SELECT
        o.order_id::INT,
        ROUND(SUM(od.quantity * od.unit_price * (1 - od.discount))::NUMERIC, 2) AS sum_order
    FROM nw.orders AS o
    INNER JOIN nw.order_details AS od ON o.order_id = od.order_id
    GROUP BY o.order_id
    HAVING ROUND(SUM(od.quantity * od.unit_price * (1 - od.discount))::NUMERIC, 2) > v_avg_total
    ORDER BY sum_order DESC;
END;    
$$ LANGUAGE plpgsql;

SELECT * FROM nw.get_order_over_avg_total();