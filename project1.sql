-- Создание таблиц клиентов, животных, ветеринаров и записей на прием.
CREATE TABLE clients (
    client_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(15) NOT NULL,
    email VARCHAR(100),
    address TEXT DEFAULT 'Не указано'
);

CREATE TABLE pets (
    pet_id SERIAL PRIMARY KEY,
    pet_name VARCHAR(50) NOT NULL,
    species VARCHAR(50) NOT NULL,
    breed VARCHAR(50),
    age INTEGER CHECK (age >= 0),
    owner_id INT NOT NULL REFERENCES clients(client_id) ON DELETE CASCADE
);

CREATE TABLE vets (
    vet_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    specialization VARCHAR(100) NOT NULL,
    experience_years INTEGER DEFAULT 0 CHECK (experience_years >= 0)
);

CREATE TABLE registration (
    reg_id SERIAL PRIMARY KEY,
    reg_date DATE NOT NULL,
    pet_id INT NOT NULL REFERENCES pets(pet_id) ON DELETE CASCADE,
    vet_id INT NOT NULL REFERENCES vets(vet_id) ON DELETE CASCADE,
    description TEXT DEFAULT 'Без описания'
);

-- Заполняем таблицы данными.
INSERT INTO clients (full_name, phone_number, email, address)
VALUES
('Анастасия Соловьева', '89051234567', 'solov_astya@mail.ru', 'ул. Тихая, д. 5, кв. 12'),
('Виктор Михайлов', '89062345678', 'michailov_v@mail.ru', 'пер. Грибоедова, д. 3'),
('Дмитрий Орлов', '89073456789', 'orlov.d@mail.ru', 'ул. Центральная, д. 45'),
('Елена Кравцова', '89084567890', 'krav_elena@mail.ru', 'б-р Романтиков, д. 7, кв. 18'),
('Игорь Звягинцев', '89095678901', 'zvyagin_igor@mail.ru', 'ул. Академика Павлова, д. 13');

INSERT INTO pets (pet_name, species, breed, age, owner_id)
VALUES
('Тихон', 'Кот', 'Русская голубая', 3, 1),
('Арчи', 'Собака', 'Джек-рассел-терьер', 2, 2),
('Шрек', 'Хомяк', 'Сирийский', 1, 3),
('Фредди', 'Играна', 'Красноухая черепаха', 5, 4),
('Шерлок', 'Собака', 'Бигль', 4, 5);

INSERT INTO vets (full_name, specialization, experience_years)
VALUES
('Ирина Патрушева', 'Хирург-ортопед', 12),
('Николай Громов', 'Дерматолог', 7),
('Светлана Малышева', 'Реабилитолог', 6),
('Олег Лапин', 'Онколог', 9),
('Маргарита Савельева', 'Невролог', 8);

INSERT INTO registration (reg_date, pet_id, vet_id, description)
VALUES
('2024-12-01', 1, 1, 'Операция по удалению кисты'),
('2024-12-02', 2, 2, 'Лечение аллергии на корм'),
('2024-12-03', 3, 3, 'Посттравматическая реабилитация'),
('2024-12-04', 4, 4, 'Диагностика опухоли'),
('2024-12-05', 5, 5, 'Массаж и иглоукалывание');

-- Выполним простые запросы.
-- Выводим всех владельцев с их питомцами.
SELECT c.full_name AS owner_name, p.pet_name, p.species, p.breed
FROM clients c
JOIN pets p ON c.client_id = p.owner_id;

-- Получить список животных старше 3 лет.
SELECT pet_name, species, age
FROM pets
WHERE age > 3;

-- Выводим имена и специализации ветеринаров с опытом более 8 лет.
SELECT full_name, specialization
FROM vets
WHERE experience_years > 8;

-- Выводим какие животные записаны к ветеринару на определенную дату.
SELECT a.reg_date, p.pet_name, p.species, v.full_name AS vet_name
FROM registration a
JOIN pets p ON a.pet_id = p.pet_id
JOIN vets v ON a.vet_id = v.vet_id
WHERE reg_date = '2024-12-03';

-- Агрегации
-- Кол-во животных каждого вида зарегистрированных в клинике
SELECT species, COUNT(*) AS count_species
FROM pets
GROUP BY species;

-- Найдем средний возраст питомцев у каждого клиента
SELECT c.full_name, AVG(p.age) AS avg_age
FROM clients c
JOIN pets p ON c.client_id = p.owner_id
GROUP BY c.full_name;

-- Ветеринар с наиб. кол-вом записей на прием
SELECT v.full_name, COUNT(a.reg_id) AS appointment_count
FROM vets v
JOIN registration a ON v.vet_id = a.vet_id
GROUP BY v.full_name
ORDER BY appointment_count DESC
LIMIT 1;

-- Получим даты с наибольшим количеством записей на прием
SELECT reg_date, COUNT(*) AS total_appointments
FROM registration
GROUP BY reg_date
ORDER BY total_appointments DESC
