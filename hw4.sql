-- 1. Создаем триггеры со всеми возможными ключ.словами
-- BEFORE INSERT: Проверка количества проданных единиц
CREATE OR REPLACE FUNCTION check_quantity_before_insert()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.quantity <= 0 THEN
        RAISE EXCEPTION 'Количество проданных единиц должно быть положительным';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_quantity_before_insert
BEFORE INSERT ON sales
FOR EACH ROW
EXECUTE FUNCTION check_quantity_before_insert();

-- BEFORE INSERT: Логирование больших значений количества
CREATE OR REPLACE FUNCTION log_large_quantity_before_insert()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.quantity > 100 THEN
        RAISE NOTICE 'Внимание: Продажа большого количества: % единиц', NEW.quantity;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_log_large_quantity_before_insert
BEFORE INSERT ON sales
FOR EACH ROW
EXECUTE FUNCTION log_large_quantity_before_insert();

-- AFTER INSERT: Логирование успешного добавления строки
CREATE OR REPLACE FUNCTION log_after_insert()
RETURNS TRIGGER AS $$
BEGIN
    RAISE NOTICE 'Успешно добавлена строка с sale_id = %', NEW.sale_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_log_after_insert
AFTER INSERT ON sales
FOR EACH ROW
EXECUTE FUNCTION log_after_insert();

-- AFTER DELETE: Логирование удаления строки
CREATE OR REPLACE FUNCTION log_after_delete()
RETURNS TRIGGER AS $$
BEGIN
    RAISE NOTICE 'Удалена строка с sale_id = %', OLD.sale_id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_log_after_delete
AFTER DELETE ON sales
FOR EACH ROW
EXECUTE FUNCTION log_after_delete();

-- Создаем представление для sales
CREATE VIEW sales_view AS
SELECT * FROM sales;

-- INSTEAD OF DELETE: Предотвращаем удаление данных из представления
CREATE OR REPLACE FUNCTION prevent_delete_on_view()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Удаление строк из представления запрещено';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_instead_of_delete
INSTEAD OF DELETE ON sales_view
FOR EACH ROW
EXECUTE FUNCTION prevent_delete_on_view();


-- 2. Транзакции
-- Успешная
BEGIN;

-- Добавление новой продажи
INSERT INTO sales (employee_id, product_id, quantity, sale_date)
VALUES (2, 1, 50, CURRENT_DATE);

-- Обновление зарплаты сотрудника
UPDATE employees
SET salary = salary + 500
WHERE employee_id = 2;

COMMIT;

-- Неуспешная
BEGIN;

-- Попытка вставки некорректного количества (сработает BEFORE триггер)
INSERT INTO sales (employee_id, product_id, quantity, sale_date)
VALUES (2, 1, -10, CURRENT_DATE);

-- Обновление зарплаты сотрудника
UPDATE employees
SET salary = salary + 500
WHERE employee_id = 2;

ROLLBACK;


-- 3. Использование RAISE для логирования
CREATE OR REPLACE FUNCTION log_and_check_sales()
RETURNS TRIGGER AS $$
BEGIN
    -- Логируем большие количества продаж
    IF NEW.quantity > 100 THEN
        RAISE NOTICE 'Большая продажа: % единиц сотрудником %', NEW.quantity, NEW.employee_id;
    END IF;

    -- Предупреждаем о подозрительно высоких значениях
    IF NEW.quantity > 500 THEN
        RAISE WARNING 'Подозрительное количество: % единиц!', NEW.quantity;
    END IF;

    -- Отклоняем некорректные данные
    IF NEW.quantity <= 0 THEN
        RAISE EXCEPTION 'Некорректное количество: % единиц. Продажа отклонена.', NEW.quantity;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_log_and_check_sales
BEFORE INSERT ON sales
FOR EACH ROW
EXECUTE FUNCTION log_and_check_sales();