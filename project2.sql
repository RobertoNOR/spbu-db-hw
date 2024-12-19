-- Временные таблицы
-- Временная таблица для записи временных статистик животных
CREATE TEMP TABLE temp_pet_statistics (
    species VARCHAR(50),
    count_species INT
);

-- Заполнение временной таблицы
INSERT INTO temp_pet_statistics (species, count_species)
SELECT species, COUNT(*)
FROM pets
GROUP BY species;

-- Временная таблица для хранения данных записей за определенную неделю
CREATE TEMP TABLE temp_weekly_appointments AS
SELECT reg_date, pet_id, vet_id, description
FROM registration
WHERE reg_date BETWEEN '2024-12-01' AND '2024-12-07';

-- Представления
-- Представление для списка клиентов и их питомцев
CREATE VIEW client_pets_view AS
SELECT c.full_name AS owner_name, p.pet_name, p.species, p.breed, p.age
FROM clients c
JOIN pets p ON c.client_id = p.owner_id;

-- Представление для записи животных к ветеринарам
CREATE VIEW registration_view AS
SELECT r.reg_date, p.pet_name, p.species, v.full_name AS vet_name, v.specialization, r.description
FROM registration r
JOIN pets p ON r.pet_id = p.pet_id
JOIN vets v ON r.vet_id = v.vet_id;

-- Валидация данных
-- Триггер для проверки возраста питомцев
CREATE OR REPLACE FUNCTION validate_pet_age()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.age < 0 THEN
        RAISE EXCEPTION 'Возраст питомца не может быть отрицательным';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_pet_age
BEFORE INSERT OR UPDATE ON pets
FOR EACH ROW
EXECUTE FUNCTION validate_pet_age();

-- Триггер для проверки специализации ветеринаров
CREATE OR REPLACE FUNCTION validate_vet_specialization()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.specialization IS NULL OR NEW.specialization = '' THEN
        RAISE EXCEPTION 'Специализация ветеринара не может быть пустой';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_vet_specialization
BEFORE INSERT OR UPDATE ON vets
FOR EACH ROW
EXECUTE FUNCTION validate_vet_specialization();

-- Ограничения
-- Ограничение на количество ветеринаров
CREATE OR REPLACE FUNCTION limit_vets_count()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT COUNT(*) FROM vets) >= 50 THEN
        RAISE EXCEPTION 'Максимальное количество ветеринаров достигнуто (50)';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER limit_vets_trigger
BEFORE INSERT ON vets
FOR EACH ROW
EXECUTE FUNCTION limit_vets_count();

-- Ограничение на количество питомцев у одного клиента
CREATE OR REPLACE FUNCTION limit_pets_per_client()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT COUNT(*) FROM pets WHERE owner_id = NEW.owner_id) >= 5 THEN
        RAISE EXCEPTION 'Один клиент может иметь не более 5 питомцев';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER limit_pets_trigger
BEFORE INSERT ON pets
FOR EACH ROW
EXECUTE FUNCTION limit_pets_per_client();


-- Аудит изменений данных
-- Таблица для хранения истории изменений
CREATE TABLE registration_audit (
    audit_id SERIAL PRIMARY KEY,
    action VARCHAR(10),
    reg_id INT,
    old_reg_date DATE,
    new_reg_date DATE,
    change_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Функция для аудита изменений
CREATE OR REPLACE FUNCTION log_registration_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO registration_audit (action, reg_id, old_reg_date, new_reg_date)
        VALUES ('UPDATE', OLD.reg_id, OLD.reg_date, NEW.reg_date);
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO registration_audit (action, reg_id, old_reg_date)
        VALUES ('DELETE', OLD.reg_id, OLD.reg_date);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Триггер для аудита изменений
CREATE TRIGGER registration_audit_trigger
AFTER UPDATE OR DELETE ON registration
FOR EACH ROW
EXECUTE FUNCTION log_registration_changes();
