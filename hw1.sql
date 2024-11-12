-- 1. Создание таблицы courses
CREATE TABLE courses (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    is_exam BOOLEAN,
    min_grade INT,
    max_grade INT
);

-- 2. Создание таблицы groups
CREATE TABLE groups (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(100),
    short_name VARCHAR(25),
    students_ids INT[]
);

-- 3. Создание таблицы students
CREATE TABLE students (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    group_id INT REFERENCES groups(id),
    courses_ids INT[]
);

-- 4. Создание таблицы ml_course
CREATE TABLE ml_course (
    student_id INT REFERENCES students(id),
    grade INT,
    grade_str VARCHAR(1)
);

-- Заполнение таблицы courses
INSERT INTO courses (name, is_exam, min_grade, max_grade)
VALUES
    ('Теория байесовских сетей', TRUE, 40, 100),
    ('Алгоритмы обработки изображений', TRUE, 50, 100),
    ('Английский язык', FALSE, 30, 100),
    ('Машинное обучение', TRUE, 50, 100),
    ('Технологии систем управления базами данных', TRUE, 55, 100);

-- Заполнение таблицы groups
INSERT INTO groups (full_name, short_name, students_ids)
VALUES
    ('1 группа, 1 курс магистратуры Искусственный  интеллект и наука о данных', '24.М81-мм', ARRAY[1, 2, 3, 4, 5]),
    ('2 группа, 1 курс магистратуры Искусственный  интеллект и наука о данных', '24.М82-мм', ARRAY[6, 7, 8, 9, 10]);

-- Заполнение таблицы students
INSERT INTO students (first_name, last_name, group_id, courses_ids)
VALUES
    ('Анна', 'Лебедева', 1, ARRAY[1, 2, 3, 4, 5]),
    ('Игорь', 'Сергеев', 1, ARRAY[1, 2, 3, 4, 5]),
    ('Екатерина', 'Миронова', 2, ARRAY[1, 2, 3, 4, 5]),
    ('Александр', 'Власов', 2, ARRAY[1, 2, 3, 4, 5]),
    ('Мария', 'Ковальчук', 2, ARRAY[1, 2, 3, 4, 5]),
    ('Дмитрий', 'Иванов', 1, ARRAY[1, 2, 3, 4, 5]),
    ('Виктория', 'Козлова', 1, ARRAY[1, 2, 3, 4, 5]),
    ('Сергей', 'Романов', 2, ARRAY[1, 2, 3, 4, 5]),
    ('Ольга', 'Федорова', 1, ARRAY[1, 2, 3, 4, 5]),
    ('Александр', 'Сидоров', 2, ARRAY[1, 2, 3, 4, 5]);

-- Заполнение таблицы ml_course
INSERT INTO ml_course (student_id, grade)
VALUES
    (1, 95),
    (2, 88),
    (3, 75),
    (4, 80),
    (5, 65),
    (6, 70),
    (7, 90),
    (8, 60),
    (9, 78),
    (10, 85);

-- Заполнения столбца grade_str, с учетом min_grade и max_grade
UPDATE ml_course
SET grade_str = CASE
    WHEN grade >= (SELECT max_grade FROM courses WHERE name = 'Машинное обучение') * 0.95 THEN 'A'
    WHEN grade >= (SELECT max_grade FROM courses WHERE name = 'Машинное обучение') * 0.8 THEN 'B'
    WHEN grade >= (SELECT max_grade FROM courses WHERE name = 'Машинное обучение') * 0.6 THEN 'C'
    WHEN grade >= (SELECT max_grade FROM courses WHERE name = 'Машинное обучение') * 0.4 THEN 'D'
    WHEN grade >= (SELECT min_grade FROM courses WHERE name = 'Машинное обучение') THEN 'E'
    ELSE 'F'
END;

-- Примеры фильтрации
-- 1. Отображает отличников на курсе "Машинное обучение"
SELECT student_id, grade, grade_str FROM ml_course WHERE grade_str = 'A';

-- 2. Отображает всех студентов из 2 группы, 1 курса магистратуры ИИиНОД
SELECT first_name, last_name FROM students
JOIN groups ON students.group_id = groups.id
WHERE groups.short_name = '24.М81-мм';

-- 3. Отображает всех Александров в списке студентов
SELECT id AS student_id, first_name, last_name FROM students WHERE first_name LIKE 'Александр%';

-- Примеры агрегации
-- 1. Отображает среднюю оценку на курсе "Машинное обучение"
SELECT AVG(grade) AS avg_grade FROM ml_course;

-- 2. Отображает максимальную оценку на курсе "Машинное обучение"
SELECT student_id, grade AS max_grade FROM ml_course WHERE grade = (SELECT MAX(grade) FROM ml_course);

-- 3. Минимальную оценку на курсе "Машинное обучение"
SELECT student_id, grade AS min_grade FROM ml_course WHERE grade = (SELECT MIN(grade) FROM ml_course);
