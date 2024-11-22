-- 1. Создание и заполнение промежуточных таблиц student_courses, group_courses
CREATE TABLE student_courses (
    id SERIAL PRIMARY KEY,
    student_id INT REFERENCES students(id),
    course_id INT REFERENCES courses(id),
    UNIQUE(student_id, course_id)
);

CREATE TABLE group_courses (
    id SERIAL PRIMARY KEY,
    group_id INT REFERENCES groups(id),
    course_id INT REFERENCES courses(id),
    UNIQUE(group_id, course_id)
);

INSERT INTO student_courses (student_id, course_id)
SELECT id AS student_id, unnest(courses_ids) AS course_id
FROM students;

INSERT INTO group_courses (group_id, course_id)
SELECT groups.id AS group_id, UNNEST(ARRAY[1, 2, 3, 4, 5]) AS course_id  -- Укажите курсы, которые относятся к каждой группе
FROM groups

-- Удаление ненужных полей courses_ids из таблицы students и students_ids из таблицы groups
ALTER TABLE students DROP COLUMN courses_ids;

ALTER TABLE groups DROP COLUMN students_ids;

-- 2. Добавление уникального ограничение на поле name
ALTER TABLE courses ADD CONSTRAINT unique_course_name UNIQUE (name);

-- Создание индекса на поле group_id в таблице students
CREATE INDEX idx_students_group_id ON students(group_id);

/*
 Индексы повышают производительность запросов на чтение (SELECT), сокращая время поиска данных, особенно в больших таблицах.
 Хотя с другой стороны, индексы снижают производительность операций записи (INSERT, UPDATE, DELETE), так как их тоже нужно обновлять при изменении данных.
 */

-- Создадим дополнительные таблицы с курсами, заполним их
CREATE TABLE tbs_networks (
    student_id INT REFERENCES students(id),
    grade INT,
    grade_str VARCHAR(1)
);

CREATE TABLE image_processing_algorithms (
    student_id INT REFERENCES students(id),
    grade INT,
    grade_str VARCHAR(1)
);

CREATE TABLE english (
    student_id INT REFERENCES students(id),
    grade INT,
    grade_str VARCHAR(1)
);

CREATE TABLE dbms_technologies (
    student_id INT REFERENCES students(id),
    grade INT,
    grade_str VARCHAR(1)
);

INSERT INTO tbs_networks (student_id, grade)
VALUES
    (1, 85),
    (2, 88),
    (3, 75),
    (4, 80),
    (5, 61),
    (6, 70),
    (7, 95),
    (8, 60),
    (9, 78),
    (10, 85);

INSERT INTO image_processing_algorithms (student_id, grade)
VALUES
    (1, 70),
    (2, 75),
    (3, 53),
    (4, 85),
    (5, 90),
    (6, 80),
    (7, 88),
    (8, 72),
    (9, 76),
    (10, 89);

INSERT INTO english (student_id, grade)
VALUES
    (1, 75),
    (2, 82),
    (3, 65),
    (4, 88),
    (5, 92),
    (6, 50),
    (7, 80),
    (8, 78),
    (9, 68),
    (10, 84);

INSERT INTO dbms_technologies (student_id, grade)
VALUES
    (1, 78),
    (2, 85),
    (3, 70),
    (4, 92),
    (5, 88),
    (6, 75),
    (7, 80),
    (8, 50),
    (9, 69),
    (10, 89);

UPDATE tbs_networks
SET grade_str = CASE
    WHEN grade >= (SELECT max_grade FROM courses WHERE name = 'Теория байесовских сетей') * 0.95 THEN 'A'
    WHEN grade >= (SELECT max_grade FROM courses WHERE name = 'Теория байесовских сетей') * 0.8 THEN 'B'
    WHEN grade >= (SELECT max_grade FROM courses WHERE name = 'Теория байесовских сетей') * 0.6 THEN 'C'
    WHEN grade >= (SELECT max_grade FROM courses WHERE name = 'Теория байесовских сетей') * 0.4 THEN 'D'
    WHEN grade >= (SELECT min_grade FROM courses WHERE name = 'Теория байесовских сетей') THEN 'E'
    ELSE 'F'
END
WHERE grade IS NOT NULL;

UPDATE image_processing_algorithms
SET grade_str = CASE
    WHEN grade >= (SELECT max_grade FROM courses WHERE name = 'Алгоритмы обработки изображений') * 0.95 THEN 'A'
    WHEN grade >= (SELECT max_grade FROM courses WHERE name = 'Алгоритмы обработки изображений') * 0.8 THEN 'B'
    WHEN grade >= (SELECT max_grade FROM courses WHERE name = 'Алгоритмы обработки изображений') * 0.6 THEN 'C'
    WHEN grade >= (SELECT max_grade FROM courses WHERE name = 'Алгоритмы обработки изображений') * 0.4 THEN 'D'
    WHEN grade >= (SELECT min_grade FROM courses WHERE name = 'Алгоритмы обработки изображений') THEN 'E'
    ELSE 'F'
END
WHERE grade IS NOT NULL;

UPDATE english
SET grade_str = CASE
    WHEN grade >= (SELECT max_grade FROM courses WHERE name = 'Английский язык') * 0.95 THEN 'A'
    WHEN grade >= (SELECT max_grade FROM courses WHERE name = 'Английский язык') * 0.8 THEN 'B'
    WHEN grade >= (SELECT max_grade FROM courses WHERE name = 'Английский язык') * 0.6 THEN 'C'
    WHEN grade >= (SELECT max_grade FROM courses WHERE name = 'Английский язык') * 0.4 THEN 'D'
    WHEN grade >= (SELECT min_grade FROM courses WHERE name = 'Английский язык') THEN 'E'
    ELSE 'F'
END
WHERE grade IS NOT NULL;

UPDATE dbms_technologies
SET grade_str = CASE
    WHEN grade >= (SELECT max_grade FROM courses WHERE name = 'Технологии систем управления базами данных') * 0.95 THEN 'A'
    WHEN grade >= (SELECT max_grade FROM courses WHERE name = 'Технологии систем управления базами данных') * 0.8 THEN 'B'
    WHEN grade >= (SELECT max_grade FROM courses WHERE name = 'Технологии систем управления базами данных') * 0.6 THEN 'C'
    WHEN grade >= (SELECT max_grade FROM courses WHERE name = 'Технологии систем управления базами данных') * 0.4 THEN 'D'
    WHEN grade >= (SELECT min_grade FROM courses WHERE name = 'Технологии систем управления базами данных') THEN 'E'
    ELSE 'F'
END
WHERE grade IS NOT NULL;

-- 3. Запрос выводит список студентов с их курсами, среднюю оценку по всем курсам. Выделим лучших студентов из каждой группы
WITH all_grades AS (
    SELECT student_id, grade FROM ml_course
    UNION ALL
    SELECT student_id, grade FROM tbs_networks
    UNION ALL
    SELECT student_id, grade FROM image_processing_algorithms
    UNION ALL
    SELECT student_id, grade FROM english
    UNION ALL
    SELECT student_id, grade FROM dbms_technologies
),
student_avg AS (
    SELECT
        s.id AS student_id,
        s.first_name,
        s.last_name,
        s.group_id,
        ROUND(AVG(ag.grade), 2) AS avg_grade
    FROM
        students s
    JOIN
        all_grades ag ON s.id = ag.student_id
    GROUP BY
        s.id, s.first_name, s.last_name, s.group_id
),
top_students AS (
    SELECT
        sa.student_id
    FROM
        student_avg sa
    WHERE
        sa.avg_grade > ALL (
            SELECT avg_grade
            FROM student_avg sa_inner
            WHERE sa_inner.group_id = sa.group_id
              AND sa_inner.student_id != sa.student_id
        )
)
SELECT
    s.id AS student_id,
    s.first_name,
    s.last_name,
    STRING_AGG(c.name, ', ') AS courses,
    sa.avg_grade,
    CASE
        WHEN s.id IN (SELECT student_id FROM top_students) THEN 'Да'
        ELSE 'Нет'
    END AS best_in_group
FROM
    students s
JOIN
    student_courses sc ON s.id = sc.student_id
JOIN
    courses c ON sc.course_id = c.id
JOIN
    student_avg sa ON s.id = sa.student_id
GROUP BY
    s.id, s.first_name, s.last_name, sa.avg_grade
ORDER BY
    s.group_id, s.last_name, s.first_name
LIMIT 10;

-- 4. Выводим список курсов и кол-во записаных студентов
SELECT
    c.name AS course_name,
    COUNT(DISTINCT sc.student_id) AS student_count
FROM
    courses c
LEFT JOIN
    student_courses sc ON c.id = sc.course_id
GROUP BY
    c.name
ORDER BY
    student_count DESC, c.name
LIMIT 5;

-- Запрос выводит среднюю оценку для каждого курса
WITH course_grades AS (
    SELECT 'Теория байесовских сетей' AS course_name, grade
    FROM tbs_networks
    WHERE grade IS NOT NULL
    UNION ALL
    SELECT 'Алгоритмы обработки изображений' AS course_name, grade
    FROM image_processing_algorithms
    WHERE grade IS NOT NULL
    UNION ALL
    SELECT 'Английский язык' AS course_name, grade
    FROM english
    WHERE grade IS NOT NULL
    UNION ALL
    SELECT 'Технологии систем управления базами данных' AS course_name, grade
    FROM dbms_technologies
    WHERE grade IS NOT NULL
    UNION ALL
    SELECT 'Машинное обучение' AS course_name, grade
    FROM ml_course
    WHERE grade IS NOT NULL
)
SELECT
    course_name,
    ROUND(AVG(grade), 2) AS avg_grade
FROM
    course_grades
GROUP BY
    course_name
ORDER BY
    avg_grade DESC, course_name
LIMIT 5;

