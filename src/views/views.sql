
--Получи список всех заказов с именами клиентов.

CREATE OR REPLACE VIEW nw.get_all_orders
AS
SELECT
    cc."name",
    oc.order_date,
    oc.total_amount 
FROM nw.customers_crud AS cc
    INNER JOIN nw.orders_crud AS oc ON cc.customer_id = oc.customer_id; 

SELECT * 
FROM nw.get_all_orders
ORDER BY total_amount;

SELECT * FROM nw.get_all_orders;



--Найди клиентов, у которых нет заказов.

CREATE OR REPLACE VIEW nw.get_customers_without_order
AS
SELECT
    cc."name" 
FROM nw.customers_crud AS cc
    LEFT JOIN nw.orders_crud AS oc ON cc.customer_id = oc.customer_id
WHERE oc.customer_id IS NULL;

SELECT * FROM nw.get_customers_without_order;