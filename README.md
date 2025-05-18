## Импорт данных

Импортируйте БД Northwind (используйте [файл инициализации](fill_in_notrthwind.sql))

## Структура проекта

- `analytics/` — аналитика, агрегаты, оконные функции
- `functions/` — пользовательские функции (PL/pgSQL)
- `procedures/` — хранимые процедуры (добавление клиентов, заказов и т.д.)
- `olap/` — многомерный анализ (CUBE, ROLLUP)
- `views/` — представления
- `crud/` — create, read, update, delete

## Используемые технологии

- PostgreSQL
- SQL: SELECT, JOIN, CTE, GROUP BY, агрегаты
- PL/pgSQL: функции и процедуры
- OLAP: аналитические конструкции