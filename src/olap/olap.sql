
--Создать OLAP-куб для анализа продаж
--Используя таблицы orders, products, customers, создайте агрегированные данные по продажам с измерениями:
--Год (order_date)
--Категория товара (category)
--Регион (region)
--Вывести общее количество заказов и сумму продаж.

SELECT 
    COALESCE(c2.category_name, 'ВСЕ КАТЕГОРИИ') AS category_name,
    COALESCE(c.region, 'ВСЕ РЕГИОНЫ') AS region,
    COALESCE(EXTRACT(YEAR FROM o.order_date)::TEXT, 'ВСЕ ГОДА') AS order_year,
    COUNT(o.order_id) AS count_order,
    ROUND(SUM(od.unit_price * od.quantity * (1 - od.discount))::NUMERIC, 2) AS total_amount
FROM nw.customers AS c
    INNER JOIN nw.orders AS o ON c.customer_id = o.customer_id
    INNER JOIN nw.order_details AS od ON o.order_id = od.order_id
    INNER JOIN nw.products AS p ON od.product_id = p.product_id 
    INNER JOIN nw.categories AS c2 ON c2.category_id = p.category_id 
GROUP BY ROLLUP(c2.category_name, c.region, EXTRACT(YEAR FROM o.order_date))
HAVING NOT (GROUPING(c.region) = 1 AND GROUPING(c2.category_name) = 1 AND GROUPING(EXTRACT(YEAR FROM o.order_date)) = 0)  
ORDER BY order_year NULLS LAST, category_name, region;



--Используя ROLLUP, выведите общее количество заказов и сумму продаж по годам и категориям.

SELECT
    COALESCE(EXTRACT(YEAR FROM o.order_date)::TEXT, 'Всего по годам') AS "year",
    COALESCE(c.category_name, 'Всего по котегориям'),
    ROUND(SUM(od.quantity * od.unit_price * (1 - od.discount))::NUMERIC, 2) AS total_sum,
    COUNT(od.order_id) AS total_count
FROM nw.order_details AS od
    INNER JOIN nw.orders AS o ON od.order_id = o.order_id
    INNER JOIN nw.products AS p ON od.product_id = p.product_id
    INNER JOIN nw.categories AS c ON p.category_id = c.category_id 
GROUP BY ROLLUP(EXTRACT(YEAR FROM o.order_date), c.category_name)
ORDER BY "year", c.category_name;



--Используя CUBE, выведите аналитику по годам, категориям и регионам с учетом всех возможных агрегатов.

SELECT
    COALESCE(EXTRACT(YEAR FROM o.order_date)::TEXT, 'Всего по годам') AS "year",
    COALESCE(c.category_name, 'Всего по котегориям'),
    COALESCE(o.ship_region, 'Всего по регионам'),
    ROUND(SUM(od.quantity * od.unit_price * (1 - od.discount))::NUMERIC, 2) AS total_sum,
    COUNT(od.order_id) AS total_count
FROM nw.order_details AS od
    INNER JOIN nw.orders AS o ON od.order_id = o.order_id
    INNER JOIN nw.products AS p ON od.product_id = p.product_id
    INNER JOIN nw.categories AS c ON p.category_id = c.category_id 
GROUP BY CUBE(EXTRACT(YEAR FROM o.order_date), c.category_name, o.ship_region)
ORDER BY "year", c.category_name, o.ship_region;



--Найдите количество заказов и общую сумму продаж,
-- сгруппировав данные по customer_id, category_name и order_year с помощью CUBE().

SELECT
    COALESCE(EXTRACT(YEAR FROM o.order_date)::TEXT, 'Всего по годам') AS "year",
    COALESCE(c.category_name, 'Всего по котегориям'),
    COALESCE(ca.customer_id, 'Всего по регионам'),
    ROUND(SUM(od.quantity * od.unit_price * (1 - od.discount))::NUMERIC, 2) AS total_sum,
    COUNT(od.order_id) AS total_count
FROM nw.order_details AS od
    INNER JOIN nw.orders AS o ON od.order_id = o.order_id
    INNER JOIN nw.products AS p ON od.product_id = p.product_id
    INNER JOIN nw.categories AS c ON p.category_id = c.category_id
    INNER JOIN nw.customers AS ca ON o.customer_id = ca.customer_id
GROUP BY CUBE(EXTRACT(YEAR FROM o.order_date), c.category_name, ca.customer_id)
ORDER BY "year", c.category_name, ca.customer_id;