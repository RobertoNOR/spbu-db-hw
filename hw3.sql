CREATE TABLE IF NOT EXISTS employees (
    employee_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    position VARCHAR(50) NOT NULL,
    department VARCHAR(50) NOT NULL,
    salary NUMERIC(10, 2) NOT NULL,
    manager_id INT REFERENCES employees(employee_id)
);

INSERT INTO employees (name, position, department, salary, manager_id)
VALUES
    ('Alice Johnson', 'Manager', 'Sales', 85000, NULL),
    ('Bob Smith', 'Sales Associate', 'Sales', 50000, 1),
    ('Carol Lee', 'Sales Associate', 'Sales', 48000, 1),
    ('David Brown', 'Sales Intern', 'Sales', 30000, 2),
    ('Eve Davis', 'Developer', 'IT', 75000, NULL),
    ('Frank Miller', 'Intern', 'IT', 35000, 5);

SELECT * FROM employees LIMIT 5;

CREATE TABLE IF NOT EXISTS sales(
    sale_id SERIAL PRIMARY KEY,
    employee_id INT REFERENCES employees(employee_id),
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    sale_date DATE NOT NULL
);

INSERT INTO sales (employee_id, product_id, quantity, sale_date)
VALUES
    (2, 1, 20, '2024-11-15'),
    (2, 2, 15, '2024-11-16'),
    (3, 1, 10, '2024-11-17'),
    (3, 3, 5, '2024-11-20'),
    (4, 2, 8, '2024-11-11'),
    (2, 1, 12, '2024-11-01');


CREATE TABLE IF NOT EXISTS products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    price NUMERIC(10, 2) NOT NULL
);


INSERT INTO products (name, price)
VALUES
    ('Product A', 150.00),
    ('Product B', 200.00),
    ('Product C', 100.00);

-- 1. Создаем временную таблицу high_sales_products, которая будет содержит продукты, проданные в количестве более 10 единиц за последние 7 дней. Выводим данные таблицы.
CREATE TEMP TABLE high_sales_products AS
SELECT
    p.product_id AS product_id,
    p.name AS product_name,
    SUM(s.quantity) AS total_quantity_sold,
    MAX(s.sale_date) AS last_sale_date
FROM products p
JOIN sales s ON p.product_id = s.product_id
WHERE s.sale_date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY p.product_id, p.name
HAVING SUM(s.quantity) > 10
LIMIT 10;

-- 2. Создаем CTE employee_sales_stats, которая посчитывает общее количество продаж и среднее количество продаж для каждого сотрудника за последние 30 дней.
WITH employee_sales_stats AS (
    SELECT
        e.employee_id,
        e.name AS employee_name,
        COUNT(s.sale_id) AS total_sales,
        AVG(s.quantity) AS avg_sales_per_transaction
    FROM employees e
    LEFT JOIN sales s ON e.employee_id = s.employee_id
    WHERE s.sale_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY e.employee_id, e.name
),
company_avg_sales AS (
    SELECT AVG(total_sales) AS company_avg_sales
    FROM employee_sales_stats
)
-- Запрос, который выводит сотрудников с количеством продаж выше среднего по компании.
SELECT ess.employee_id, ess.employee_name, ess.total_sales, ess.avg_sales_per_transaction
FROM employee_sales_stats ess, company_avg_sales cas
WHERE ess.total_sales > cas.company_avg_sales
LIMIT 10;

-- 3. Иерархическая структура, показывающую всех сотрудников, которые подчиняются конкретному менеджеру(id = 1).
WITH RECURSIVE employee_hierarchy AS (
    SELECT e.employee_id, e.name AS employee_name, e.position, e.department, e.salary, e.manager_id, 1 AS level
    FROM employees e
    WHERE e.manager_id = 1

    UNION ALL

    SELECT
        e.employee_id,
        e.name AS employee_name,
        e.position,
        e.department,
        e.salary,
        e.manager_id,
        eh.level + 1 AS level
    FROM employees e
    JOIN employee_hierarchy eh ON e.manager_id = eh.employee_id
)
SELECT employee_id, employee_name, position, department, salary, manager_id, level
FROM employee_hierarchy
ORDER BY level, employee_name
LIMIT 10;

-- 4. Запрос с CTE, который выводит топ-3 продукта по количеству продаж за текущий месяц и за прошлый месяц.
WITH sales_by_month AS (
    SELECT
        p.product_id,
        p.name AS product_name,
        DATE_TRUNC('month', s.sale_date) AS sale_month,
        SUM(s.quantity) AS total_quantity
    FROM products p
    JOIN sales s ON p.product_id = s.product_id
    WHERE s.sale_date >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
    GROUP BY p.product_id, p.name, DATE_TRUNC('month', s.sale_date)
),
ranked_products AS (
    SELECT
        sbm.product_id,
        sbm.product_name,
        sbm.sale_month,
        sbm.total_quantity,
        RANK() OVER (PARTITION BY sbm.sale_month ORDER BY sbm.total_quantity DESC) AS rank
    FROM sales_by_month sbm
)
SELECT
    rp.product_id,
    rp.product_name,
    TO_CHAR(rp.sale_month, 'YYYY-MM') AS month,
    rp.total_quantity
FROM ranked_products rp
WHERE rp.rank <= 3
ORDER BY rp.sale_month, rp.rank
LIMIT 10;

-- 5. Создаем индекс для таблицы sales по полю employee_id и sale_date. Проверим как наличие индекса влияет на производительность запроса до и после.
-- Запрос выдает последние 10 продаж сотрудников, отсортированные по дате продажи
EXPLAIN ANALYZE
SELECT employee_id, product_id, quantity, sale_date
FROM sales
WHERE sale_date >= '2024-11-01'
ORDER BY sale_date DESC
LIMIT 10;

CREATE INDEX idx_sales_employee_date ON sales (employee_id, sale_date);

EXPLAIN ANALYZE
SELECT employee_id, product_id, quantity, sale_date
FROM sales
WHERE sale_date >= '2024-11-01'
ORDER BY sale_date DESC
LIMIT 10;
-- Имеется прирост производительности запроса, хоть и невысокий(для больших таблиц, прирост был бы значительнее).

-- 6. Анализ запроса для подсчёта общего количества проданных единиц каждого продукта(с помощью трассировки).
EXPLAIN ANALYZE
SELECT p.product_id, p.name AS product_name, SUM(s.quantity) AS total_sold
FROM products p
JOIN sales s ON p.product_id = s.product_id
GROUP BY p.product_id, p.name
ORDER BY total_sold DESC;
/*
 Запрос выполняется быстро, за 0.076 ms, поскольку объём данных небольшой.
 Он последовательно сканирует таблицы sales и products, затем объединяет их через Hash Join.
 Далее данные группируются по продуктам для подсчёта суммы продаж и сортируются по количеству проданных единиц.
 В дальнейшем, при росте данных, можно создать индекс для sales(product_id), чтобы увеличить производительность
 */



