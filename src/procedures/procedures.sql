--Процедура для обновления цен на товары
--Напиши процедуру, которая увеличивает цену всех товаров в заданной
--категории (category_id) на определенный процент (percent_increase).

CREATE OR REPLACE PROCEDURE nw.set_new_price_for_category(p_category_id INT, p_percent_increase NUMERIC)
AS $$
BEGIN
UPDATE nw.products 
SET unit_price = unit_price + (unit_price * p_percent_increase/100.0)
WHERE category_id = p_category_id;
END;
$$ LANGUAGE plpgsql;

CALL nw.set_new_price_for_category(2, 5);



--Процедура с циклом: обновление скидок
--Напиши процедуру, которая для всех заказов конкретного
--клиента (customer_id) уменьшает скидку (discount) на 5%, но не ниже 0%.

CREATE OR REPLACE PROCEDURE nw.set_increase_discount(p_customer_id TEXT, p_percent INT)
AS $$
DECLARE
    r_order RECORD;
BEGIN
    FOR r_order IN 
        SELECT
            od.product_id,
            od.order_id, 
            od.discount 
        FROM nw.customers AS c 
            INNER JOIN nw.orders AS o ON c.customer_id = o.customer_id
            INNER JOIN nw.order_details AS od ON o.order_id = od.order_id 
        WHERE c.customer_id = p_customer_id
    LOOP
        UPDATE nw.order_details
        SET discount = GREATEST(discount + p_percent/100.0, 0)
        WHERE order_id = r_order.order_id AND product_id = r_order.product_id;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

CALL nw.set_increase_discount('CHOPS', 5);



---Создать процедуру, которая уменьшает остаток товара (units_in_stock) после выполнения заказа.
--Входной параметр: p_order_id INT
--Для каждого товара в order_details уменьшить units_in_stock в products на количество (quantity) из заказа.
--Если после вычитания количество меньше 0, установить units_in_stock = 0.
--Вывести сообщение о завершении.

CREATE OR REPLACE PROCEDURE nw.update_stock_after_order(p_order_id INT)
AS $$    
BEGIN
UPDATE nw.products
SET .units_in_stock = GREATEST(od.units_in_stock - od.quantity, 0)
FROM nw.products AS p
    INNER JOIN nw.order_details AS od ON p.product_id = od.product_id
WHERE od.order_id = p_order_id;
RAISE NOTICE 'Остаток на складе уменьшен';
END;
$$ LANGUAGE plpgsql; 


CALL nw.update_stock_after_order(10248)



--Создайте процедуру, которая увеличивает скидку на 5% для всех заказов клиента,
--у которого сумма всех покупок больше 5000.

CREATE OR REPLACE PROCEDURE nw.increase_percent_for_customer()
AS
$$
DECLARE
    r_customer RECORD;
BEGIN
    FOR r_customer IN
        SELECT
            c.customer_id,
            ROUND(SUM(od.unit_price * od.quantity * (1 - od.discount))::NUMERIC, 2) AS total_amount
        FROM nw.customers AS c 
            INNER JOIN nw.orders AS o ON c.customer_id = o.customer_id 
            INNER JOIN nw.order_details AS od ON o.order_id = od.order_id 
        GROUP BY c.customer_id
        HAVING ROUND(SUM(od.unit_price * od.quantity * (1 - od.discount))::NUMERIC, 2) > 5000
    LOOP
        UPDATE nw.order_details
        SET discount = discount + 0.05
        WHERE order_id IN (
            SELECT order_id FROM nw.orders WHERE customer_id = r_customer.customer_id
        );
    END LOOP;
    RAISE NOTICE 'Процедура выполнена успешно!';
END;
$$ LANGUAGE plpgsql;

CALL nw.increase_percent_for_customer();



--Напишите процедуру, которая уменьшает цену всех товаров,
--у которых продажи за последний год были ниже 10 единиц, на 10%.

CREATE OR REPLACE PROCEDURE nw.decrease_price()
AS $$
DECLARE 
    r_order RECORD;
    last_year INT;
BEGIN
    SELECT MAX(EXTRACT(YEAR FROM order_date)) INTO last_year
    FROM nw.orders;

    -- Цикл по товарам с низкими продажами
    FOR r_order IN (
        SELECT 
            p.product_id,
            p.product_name
        FROM nw.products AS p
        INNER JOIN nw.order_details AS od ON p.product_id = od.product_id
        INNER JOIN nw.orders AS o ON od.order_id = o.order_id 
        WHERE EXTRACT(YEAR FROM o.order_date) = last_year
        GROUP BY p.product_id, p.product_name
        HAVING COUNT(od.product_id) < 10
    ) 
    LOOP
        -- Уменьшаем цену на 10%
        UPDATE nw.products
        SET unit_price = unit_price * 0.9
        WHERE product_id = r_order.product_id;

        -- Выводим уведомление
        RAISE NOTICE 'Цена товара % снижена на 10%%', r_order.product_name;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

CALL nw.decrease_price();



--Увеличь сумму всех заказов на 10%.

CREATE OR REPLACE PROCEDURE nw.increase_total_amount(p_percent INT, p_customer_id INT)
AS $$
BEGIN
    UPDATE nw.orders_crud 
    SET total_amount = total_amount + total_amount * (p_percent/100.0)
    WHERE customer_id = p_customer_id;
RAISE NOTICE 'Total_amount was increased';
END;
$$ LANGUAGE plpgsql;

CALL nw.increase_total_amount(30, 1);
