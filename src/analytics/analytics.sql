--Найди топ-5 самых продаваемых товаров (по количеству проданных единиц).

SELECT
    p.product_name,
    SUM(od.quantity) AS total_quantity
FROM nw.products AS p
    INNER JOIN nw.order_details AS od ON p.product_id = od.product_id
GROUP BY p.product_name 
ORDER BY total_quantity DESC 
LIMIT 5;



--Определи самый прибыльный заказ.

SELECT
    od.order_id,
    ROUND(SUM(od.unit_price * od.quantity * (1 - od.discount))::NUMERIC, 2) AS total_amount
FROM nw.order_details AS od
GROUP BY od.order_id 
ORDER BY total_amount DESC
LIMIT 1; 



--Выведи список клиентов, у которых было более 5 заказов.

SELECT
    c.company_name,
    COUNT(o.order_id) AS count_of_order
FROM nw.customers AS c
    INNER JOIN nw.orders AS o ON c.customer_id = o.customer_id
GROUP BY c.company_name
HAVING COUNT(o.order_id) > 5
ORDER BY count_of_order DESC;



--Определи сотрудников с наибольшим количеством заказов.

SELECT
    e.first_name || ' ' || e.last_name AS full_name,
    COUNT(o.order_id) AS count_of_order
FROM nw.employees AS e 
    INNER JOIN nw.orders AS o ON e.employee_id = o.employee_id 
GROUP BY e.employee_id 
ORDER BY count_of_order DESC
LIMIT 5;



--Выведи среднюю сумму заказа для каждого клиента.

WITH table_total_amount
AS
(
SELECT
    od.order_id,
    ROUND(SUM(od.unit_price * od.quantity * (1 - od.discount))::NUMERIC, 2) AS total_amount
FROM nw.order_details AS od
GROUP BY od.order_id 
)
SELECT
    c.company_name,
    ROUND(AVG(total_amount)::NUMERIC, 2) AS avg_amount
FROM nw.customers AS c 
    INNER JOIN nw.orders AS o ON c.customer_id = o.customer_id 
    INNER JOIN table_total_amount AS tta ON tta.order_id = o.order_id 
GROUP BY c.company_name
ORDER BY avg_amount DESC;



--Найти процент заказов у клиентов,у которых более 5 заказов, от общего числа заказов

WITH get_count_order
AS 
(
SELECT
    c.company_name,
    COUNT(o.order_id) AS count_order
FROM nw.customers AS c 
    INNER JOIN nw.orders AS o ON c.customer_id = o.customer_id
GROUP BY c.company_name 
HAVING COUNT(o.order_id) > 5),
get_total_count_order
AS 
(
SELECT
    COUNT(o.order_id) AS total_count_order
FROM nw.orders AS o 
)
SELECT
    gco.company_name,
    gco.count_order,
    ROUND(((gco.count_order*100.0)/gtco.total_count_order)::NUMERIC, 2) AS percent_order
FROM get_count_order AS gco
    CROSS JOIN get_total_count_order AS gtco
ORDER BY percent_order DESC;



--Определи, какой процент всех заказов обработал самый загруженный сотрудник

WITH get_count_order
AS
(
SELECT
    e.employee_id,
    COUNT(o.order_id) AS count_order
FROM nw.employees AS e
    INNER JOIN nw.orders AS o ON e.employee_id = o.employee_id
GROUP BY e.employee_id
),
get_total_count_order
AS 
(
SELECT 
    SUM(count_order) AS total_count_order
FROM get_count_order AS gco
)
SELECT
    gco.employee_id,
    ROUND((gco.count_order*100/gtco.total_count_order)::NUMERIC, 2) AS percent_of_total_order
FROM get_total_count_order AS gtco
    CROSS JOIN get_count_order AS gco
ORDER BY percent_of_total_order DESC
LIMIT 1;

    

--Определи клиентов, у которых средняя сумма заказа выше общей
--средней суммы заказа по всем клиентам

WITH get_amount
AS
(
SELECT
    c.company_name,
    SUM(od.unit_price*od.quantity) AS amount
FROM nw.customers AS c
    INNER JOIN nw.orders AS o ON c.customer_id = o.customer_id
    INNER JOIN nw.order_details AS od ON o.order_id = od.order_id
GROUP BY c.company_name 
ORDER BY amount DESC
),
get_total_avg_amount
AS 
(
SELECT
    ROUND(AVG(a.amount)::NUMERIC, 2) AS total_avg_amount
FROM get_amount AS a
)
SELECT
   ga.company_name,
   ROUND(AVG(ga.amount)::NUMERIC, 2) AS avg_amount
FROM get_total_avg_amount AS gtaa
    CROSS JOIN get_amount AS ga
GROUP BY ga.company_name, gtaa.total_avg_amount
HAVING ROUND(AVG(ga.amount)::NUMERIC, 2) > gtaa.total_avg_amount
ORDER BY avg_amount DESC;



--ID поставщика, среднее время обработки заказа (разница между датой отправки и датой заказа),
--а также разницу по сравнению с предыдущим поставщиком.

WITH supplier_avg_shipping AS (
    SELECT 
        s.supplier_id,
        s.company_name,
        ROUND(AVG(o.shipped_date - o.order_date)::NUMERIC, 2) AS avg_shipping_time
    FROM nw.orders AS o
    INNER JOIN nw.order_details AS od ON o.order_id = od.order_id
    INNER JOIN nw.products AS p ON od.product_id = p.product_id
    INNER JOIN nw.suppliers AS s ON p.supplier_id = s.supplier_id
    WHERE o.shipped_date IS NOT NULL
    GROUP BY s.supplier_id, s.company_name
)
SELECT 
    supplier_id,
    company_name,
    avg_shipping_time,
    LAG(avg_shipping_time) OVER (ORDER BY avg_shipping_time DESC) AS prev_supplier_time,
    avg_shipping_time - LAG(avg_shipping_time) OVER (ORDER BY avg_shipping_time DESC) AS difference
FROM supplier_avg_shipping
ORDER BY avg_shipping_time DESC;



--Определи самый прибыльный месяц
--Требуется вывести: год, месяц, общую сумму продаж за месяц
--и накопительную сумму дохода (running total).

SELECT 
    EXTRACT(YEAR FROM o.order_date) AS order_year,
    EXTRACT(MONTH FROM o.order_date) AS order_month,
    ROUND(SUM(od.unit_price * od.quantity * (1 - od.discount))::NUMERIC, 2) AS monthly_revenue,
    ROUND(SUM(SUM(od.unit_price * od.quantity * (1 - od.discount))) 
        OVER (ORDER BY EXTRACT(YEAR FROM o.order_date), EXTRACT(MONTH FROM o.order_date))::NUMERIC, 2) AS running_total
FROM nw.orders AS o
INNER JOIN nw.order_details AS od ON o.order_id = od.order_id
GROUP BY order_year, order_month
ORDER BY order_year, order_month; 



--Найди сотрудников, которые выполнили больше заказов, чем средний 
--показатель по компании
--Требуется вывести: имя сотрудника, количество заказов, среднее 
--количество заказов по всем сотрудникам,
--и его превышение относительно среднего.

WITH get_count_order_of_employee
AS
(
SELECT
    e.first_name || ' ' || e.last_name AS full_name,
    COUNT(o.order_id) AS count_order_of_employee
FROM nw.employees AS e
    INNER JOIN nw.orders AS o ON e.employee_id = o.employee_id
GROUP BY full_name
)
SELECT 
    g.full_name,
    g.count_order_of_employee,
    ROUND(AVG(g.count_order_of_employee) OVER()::NUMERIC, 2) AS total_avg,
    g.count_order_of_employee - ROUND(AVG(g.count_order_of_employee) OVER()::NUMERIC, 2) AS difference
FROM get_count_order_of_employee AS g 
ORDER BY difference DESC;



--Найди заказ с наибольшей суммой в каждом месяце
--Требуется вывести: год, месяц, ID заказа, сумму заказа, и ранг в рамках месяца.

WITH get_monthly_revenue
AS
(
SELECT
    o.order_id,
    EXTRACT(YEAR FROM o.order_date) AS year_order,
    EXTRACT(MONTH FROM o.order_date) AS month_order,
    ROUND(SUM(od.unit_price * od.quantity * (1 - od.discount))::NUMERIC, 2) AS monthly_revenue 
FROM nw.orders AS o
    INNER JOIN nw.order_details AS od ON o.order_id = od.order_id
GROUP BY o.order_id, year_order, month_order
),
get_rating
AS 
(
SELECT 
    gmr.order_id,
    gmr.year_order,
    gmr.month_order,
    gmr.monthly_revenue,
    DENSE_RANK() OVER(PARTITION BY gmr.year_order, gmr.month_order ORDER BY gmr.monthly_revenue DESC) AS rating
FROM get_monthly_revenue AS gmr
)
SELECT 
    gr.order_id,
    gr.year_order,
    gr.month_order,
    gr.monthly_revenue,
    gr.rating
FROM get_rating AS gr
WHERE gr.rating = 1
ORDER BY gr.monthly_revenue DESC;



--Найди все заказы, сделанные в последнюю неделю перед самой поздней датой заказа в таблице.
--Вывести: order_id, order_date.

WITH get_period
AS
(
SELECT
    o.order_id,
    o.order_date AS date,
    (SELECT MAX(o.order_date) 
     FROM nw.orders AS o) AS last_date,
    (SELECT MAX(o.order_date) - 7
     FROM nw.orders AS o) AS result_date 
FROM nw.orders AS o
)
SELECT
    gp.order_id,
    gp.date
FROM get_period AS gp
WHERE gp.date BETWEEN gp.result_date AND gp.last_date

WITH get_last_date
AS
(
SELECT 
    MAX(o.order_date) AS last_date
FROM nw.orders AS o
)
SELECT 
    o.order_id,
    o.order_date 
FROM nw.orders AS o 
    INNER JOIN get_last_date AS gld ON o.order_date BETWEEN gld.last_date - INTERVAL '7 days' AND gld.last_date;



--Добавь колонку "размер заказа" к заказам, где:
--Маленький — если сумма заказа < 500
--Средний — если от 500 до 2000
--Большой — если больше 2000
--Вывести: order_id, order_date, total_amount, order_size.

WITH get_total_amount
AS
(
SELECT
    o.order_id,
    o.order_date,
    ROUND(SUM(od.unit_price * od.quantity * (1 - od.discount))::NUMERIC, 2) AS total_amount
FROM nw.orders AS o
    INNER JOIN nw.order_details AS od ON o.order_id = od.order_id 
GROUP BY o.order_id, o.order_date 
)
SELECT 
    gta.order_id,
    gta.order_date,
    gta.total_amount,
    CASE 
        WHEN gta.total_amount > 2000
        THEN 'Большой'
        WHEN gta.total_amount < 500
        THEN 'Маленький'
        ELSE 'Средний'
    END AS order_size   
FROM get_total_amount AS gta;



--Найди всех сотрудников, которые обработали хотя бы один заказ.
--Вывести: employee_id, full_name.

SELECT
    e.employee_id,
    e.first_name || ' ' || e.last_name AS full_name
FROM nw.employees AS e
WHERE EXISTS(SELECT 1
             FROM nw.orders AS o 
             WHERE o.employee_id = e.employee_id);
   

         
--Найди клиентов, которые сделали заказы в этом году, но не делали их в прошлом году.
--Вывести: customer_id, company_name.

WITH get_years
AS
(
SELECT
    MAX(EXTRACT(YEAR FROM o.order_date)) AS last_date,
    MAX(EXTRACT(YEAR FROM o.order_date)) - 1 AS pre_year
FROM nw.orders AS o 
)
SELECT
    c.company_name
FROM nw.customers AS c 
    INNER JOIN nw.orders AS o ON c.customer_id = o.customer_id
    INNER JOIN get_years AS gy ON EXTRACT(YEAR FROM o.order_date) = gy.last_date 
                                    AND EXTRACT(YEAR FROM o.order_date) != gy.pre_year;
                                    
 
                                
--Напишите SQL-запрос, который выводит список клиентов, у которых не было заказов за последние 6 месяцев.

SELECT
    c.company_name
FROM nw.customers AS c 
    LEFT JOIN nw.orders AS o ON c.customer_id = o.customer_id
        AND o.order_date > CURRENT_DATE - INTERVAL '6 month'
WHERE o.order_id IS NULL;



--Найдите топ-5 самых дорогих товаров в каждой категории.

EXPLAIN ANALYZE WITH get_rank
AS
(
SELECT
    p.product_name,
    c.category_name,
    ROW_NUMBER() OVER(PARTITION BY c.category_name ORDER BY p.unit_price DESC) AS rank
FROM nw.products AS p
    INNER JOIN nw.categories AS c ON p.category_id = c.category_id 
)
SELECT
    gr.category_name,
    gr.product_name   
FROM get_rank AS gr
WHERE gr."rank" <= 5;



--Для каждого товара посчитайте его среднюю цену за последние 6 месяцев.

SELECT
    p.product_name,
    AVG(p.unit_price) OVER(PARTITION BY p.product_name) AS avg_price
FROM nw.products AS p
    INNER JOIN nw.order_details AS od ON p.product_id = od.product_id
    INNER JOIN nw.orders AS o ON od.order_id = o.order_id 
WHERE o.order_date BETWEEN '1997-01-01' AND '1997-06-30'



--Выведите процентное соотношение продаж каждого продукта внутри своей категории.

WITH get_count_orders
AS
(
SELECT
    c.category_id,
    c.category_name,
    COUNT(od.order_id) AS count_orders
FROM nw.categories AS c 
    INNER JOIN nw.products AS p ON c.category_id = p.category_id
    INNER JOIN nw.order_details AS od ON p.product_id = od.product_id
GROUP BY c.category_id, c.category_name
), 
get_count_of_product
AS
(
SELECT
    c.category_id,
    p.product_name,
    COUNT(od.order_id) AS count_of_product
FROM nw.categories AS c 
    INNER JOIN nw.products AS p ON c.category_id = p.category_id
    INNER JOIN nw.order_details AS od ON p.product_id = od.product_id
GROUP BY c.category_id, p.product_name
)
SELECT
    ord.category_name,
    prod.product_name,
    prod.count_of_product,
    ROUND(((prod.count_of_product * 100.0/ord.count_orders) )::NUMERIC, 2) AS percent
FROM get_count_orders AS ord
    INNER JOIN get_count_of_product AS prod ON ord.category_id = prod.category_id
ORDER BY ord.category_name, prod.product_name
