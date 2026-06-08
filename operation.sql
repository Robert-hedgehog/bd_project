-- ПРЕДСТАВЛЕНИЯ 
----------------------------------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_patient_history AS
SELECT 
    a.appointment_date,
    a.status,
    c.phone AS client_phone,
    CONCAT_WS(' ', c.firstname, c.lastname) AS client_name,
    p.name AS pet_name,
    p.species,
    s.name AS service_name,
    s.cost,
    d.lastname AS doctor_lastname
FROM appointments a
JOIN pets p ON p.id = a.pet_id
JOIN clients c ON c.id = p.client_id
JOIN doctors d ON d.id = a.doctor_id
JOIN services s ON s.id = a.service_id;

SELECT * FROM `v_patient_history` LIMIT 10;

-- ТРИГГЕРЫ
----------------------------------------------------------------------------------------------------

-- Запись в историю при смене статуса приема

DELIMITER //
CREATE TRIGGER trg_status_change 
AFTER UPDATE ON appointments
FOR EACH ROW
BEGIN
    IF OLD.status != NEW.status THEN
        INSERT INTO status_logs (appointment_id, old_status, new_status, changed_at)
        VALUES (NEW.id, OLD.status, NEW.status, NOW());
    END IF;
END //
DELIMITER ;

UPDATE appointments SET status = 'Отменен' WHERE id = 16;


-- ЗАПРОСЫ
----------------------------------------------------------------------------------------------------

-- Удаление одной отмененной записи

DELETE FROM appointments 
WHERE status = 'Отменен'
LIMIT 1;

-- Обновление статуса приема

UPDATE appointments 
SET status = 'Выполнен' 
WHERE id = 18 
LIMIT 1;

-- Статистика каждого ветеринара (количество приемов и общаяя сумма всех приемов)

SELECT
    CONCAT_WS(' ', d.firstname, d.lastname) AS doctor_name,
    COUNT(a.id) AS total_appointments,
    COUNT(IF(a.status = 'Выполнен', 1, NULL)) AS success,
    COUNT(IF(a.status = 'Отменен', 1, NULL)) AS canceled,
    COUNT(IF(a.status = 'Запланирован', 1, NULL)) AS scheduled,
    SUM(IF(a.status = 'Выполнен', s.cost, 0)) AS total_earned

FROM appointments a 
JOIN doctors d ON d.id = a.doctor_id
JOIN services s ON s.id = a.service_id
GROUP BY doctor_name
ORDER BY total_earned DESC;

-- ПРОЦЕДУРЫ
----------------------------------------------------------------------------------------------------

-- Вывод всей истории приемов конкретного человека

DELIMITER //
CREATE PROCEDURE get_client_history(IN p_client_name VARCHAR(255))
BEGIN
    SELECT 
        appointment_date,
        pet_name,
        species,
        service_name,
        status
    FROM v_patient_history
    WHERE client_name = p_client_name COLLATE utf8mb4_unicode_ci 
    ORDER BY appointment_date DESC;
END //
DELIMITER ;

-- Вызов процедуры

CALL get_client_history('Кирилл Баранов');

-- Поиск всех питомцев определенного вида

DELIMITER //
CREATE PROCEDURE get_pets_by_species(IN p_species VARCHAR(100))
BEGIN
    SELECT 
        p.name AS pet_name, 
        short_name(c.lastname, c.firstname) AS owner_name, 
        c.phone AS contact_phone, 
        getPetAge(p.birth_year) AS age_years
    FROM pets AS p, clients AS c
    WHERE p.client_id = c.id 
      AND p.species = p_species;
END //
DELIMITER ;

-- Вызов процедуры

CALL get_pets_by_species('Кошка');

-- Отчет о работе врача за последние N дней

DELIMITER //
CREATE PROCEDURE get_recent_appointments(IN p_doctor_lastname VARCHAR(255), IN p_days INT)
BEGIN
    DECLARE check_days INT;
    IF p_days IS NULL THEN
        SET check_days = 30;
    ELSE
        SET check_days = p_days;
    END IF;

    SELECT 
        short_name(d.lastname, d.firstname) AS doctor_name,
        a.appointment_date AS visit_date,
        p.name AS pet_name,
        s.name AS service_name,
        s.cost AS price
    FROM doctors AS d, appointments AS a, pets AS p, services AS s
    WHERE d.id = a.doctor_id 
      AND p.id = a.pet_id
      AND s.id = a.service_id
      AND d.lastname = p_doctor_lastname COLLATE utf8mb4_unicode_ci 
      AND a.appointment_date >= (CURDATE() - INTERVAL check_days DAY);
END //
DELIMITER ;

CALL get_recent_appointments('Фильченков', 90);

-- ФУНКЦИИ
----------------------------------------------------------------------------------------------------

-- Возраст питомца

DELIMITER //
CREATE FUNCTION getPetAge(b_year INT) RETURNS INT
DETERMINISTIC
BEGIN
    RETURN YEAR(CURDATE()) - b_year;
END//
DELIMITER ;

-- Проверка функции

SELECT name, species, getPetAge(birth_year) AS current_age 
FROM pets;

-- Инициалы

DELIMITER //
CREATE FUNCTION short_name(lastname VARCHAR(255), firstname VARCHAR(255))
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
    DECLARE f VARCHAR(255);
    IF LENGTH(lastname) > 0 AND LENGTH(firstname) > 0 THEN
        SET f = CONCAT(LEFT(firstname, 1), '.');
        RETURN CONCAT(lastname, ' ', f);
    ELSE
        RETURN '######';
    END IF;
END //
DELIMITER ;