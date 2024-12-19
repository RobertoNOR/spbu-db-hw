-- Таблица для аудита изменений данных клиентов
CREATE TABLE clients_audit (
    audit_id SERIAL PRIMARY KEY,
    client_id INT,
    action VARCHAR(10),
    old_full_name VARCHAR(100),
    new_full_name VARCHAR(100),
    old_phone_number VARCHAR(15),
    new_phone_number VARCHAR(15),
    change_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Функция для записи изменений клиентов (UPDATE, DELETE) в таблицу аудита
CREATE OR REPLACE FUNCTION audit_clients_changes()
RETURNS TRIGGER AS $$
BEGIN
    -- Обработка обновлений
    IF (TG_OP = 'UPDATE') THEN
        IF (OLD.full_name IS DISTINCT FROM NEW.full_name OR OLD.phone_number IS DISTINCT FROM NEW.phone_number) THEN
            INSERT INTO clients_audit (client_id, action, old_full_name, new_full_name, old_phone_number, new_phone_number)
            VALUES (OLD.client_id, 'UPDATE', OLD.full_name, NEW.full_name, OLD.phone_number, NEW.phone_number);
        END IF;
    -- Обработка удалений
    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO clients_audit (client_id, action, old_full_name, old_phone_number)
        VALUES (OLD.client_id, 'DELETE', OLD.full_name, OLD.phone_number);
    END IF;
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Ошибка при аудите клиента: %', SQLERRM;
        RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Триггер для вызова функции аудита при обновлении или удалении клиентов
CREATE TRIGGER clients_audit_trigger
AFTER UPDATE OR DELETE ON clients
FOR EACH ROW
EXECUTE FUNCTION audit_clients_changes();

DO $$
DECLARE
    NEW_CLIENT_ID INT; -- Переменная для хранения ID нового клиента
BEGIN
    -- Начало транзакции
    BEGIN;

    -- Проверяем уникальность номера телефона
    IF EXISTS (SELECT 1 FROM clients WHERE phone_number = '89011234567') THEN
        RAISE EXCEPTION 'Клиент с таким номером телефона уже существует';
    END IF;

    -- Добавляем клиента
    INSERT INTO clients (full_name, phone_number, email, address)
    VALUES ('Анна Иванова', '89011234567', 'ivanova_anna@mail.ru', 'ул. Ленина, д. 1')
    RETURNING client_id INTO NEW_CLIENT_ID;

    -- Добавляем питомца клиента
    INSERT INTO pets (pet_name, species, breed, age, owner_id)
    VALUES ('Барсик', 'Кот', 'Сиамская', 2, NEW_CLIENT_ID);

    -- Завершаем транзакцию
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        -- Откатываем изменения при ошибке
        ROLLBACK;
        RAISE NOTICE 'Ошибка при добавлении клиента и питомца: %', SQLERRM;
END;
$$;

-- Ограничение на количество записей в день в таблице регистрации
CREATE OR REPLACE FUNCTION limit_daily_registrations()
RETURNS TRIGGER AS $$
BEGIN
    -- Проверяем, достигнут ли лимит записей на указанную дату
    IF (SELECT COUNT(*) FROM registration WHERE reg_date = NEW.reg_date) >= 10 THEN
        RAISE EXCEPTION 'На % записей больше не принимается (лимит: 10)', NEW.reg_date;
    END IF;
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Ошибка при проверке лимита записей: %', SQLERRM;
        RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Триггер для вызова функции перед вставкой записи
CREATE TRIGGER daily_registration_limit
BEFORE INSERT ON registration
FOR EACH ROW
EXECUTE FUNCTION limit_daily_registrations();

-- Обновление данных клиента и его питомцев в рамках одной транзакции
DO $$
DECLARE
    CLIENT_ID INT; -- Переменная для хранения ID клиента
BEGIN
    -- Начало транзакции
    BEGIN;

    -- Обновляем данные клиента
    UPDATE clients
    SET full_name = 'Иван Петров',
        phone_number = '89112223344'
    WHERE client_id = 1
    RETURNING client_id INTO CLIENT_ID;

    -- Обновляем данные питомцев клиента
    UPDATE pets
    SET breed = 'Сибирская'
    WHERE owner_id = CLIENT_ID;

    -- Завершаем транзакцию
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        -- Откатываем изменения при ошибке
        ROLLBACK;
        RAISE NOTICE 'Ошибка при обновлении клиента и питомцев: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Таблица для статистики по видам животных
CREATE TABLE pet_statistics (
    species VARCHAR(50) PRIMARY KEY, -- Вид животного
    count_species INT DEFAULT 0 -- Количество животных данного вида
);

-- Функция для обновления статистики после добавления питомца
CREATE OR REPLACE FUNCTION update_pet_statistics()
RETURNS TRIGGER AS $$
BEGIN
    -- Если вид уже существует в статистике, увеличиваем количество
    IF EXISTS (SELECT 1 FROM pet_statistics WHERE species = NEW.species) THEN
        UPDATE pet_statistics
        SET count_species = count_species + 1
        WHERE species = NEW.species;
    ELSE
        -- Иначе добавляем новый вид
        INSERT INTO pet_statistics (species, count_species)
        VALUES (NEW.species, 1);
    END IF;
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Ошибка при обновлении статистики по питомцам: %', SQLERRM;
        RETURN NULL;
END
$$ LANGUAGE plpgsql;

-- Триггер для вызова функции при добавлении питомца
CREATE TRIGGER pet_statistics_trigger
AFTER INSERT ON pets
FOR EACH ROW
EXECUTE FUNCTION update_pet_statistics();
