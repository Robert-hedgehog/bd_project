# ВЕТЕРИНАРНАЯ КЛИНИКА
База данных для автоматизации рабочих процессов ветеринарной клиники. Система позволяет вести учет клиентов и их питомцев, управлять расписанием приемов врачей, вести справочник услуг и отслеживать историю посещений.

+ Ведение картотеки владельцев и их животных.
+ Учет медицинского персонала и справочника платных услуг.
+ Регистрация приемов с контролем их статусов (Запланирован, Выполнен, Отменен).
+ Автоматическое ведение журнала (лога) при изменении статусов записей.
+ Формирование аналитических отчетов и вычисление статистики по врачам.

## Архитектура
<img width="884" height="468" alt="изображение" src="https://github.com/user-attachments/assets/17aa4208-d897-4a49-8a05-77d3ff1d9838" />


### Описание основных сущностей:

1. clients (Клиенты) — хранит контактные данные владельцев. Уникальное поле: phone.
2. pets (Питомцы) — содержит информацию о животных (name, species, birth_year) и ссылается на владельца через client_id.
3. doctors (Врачи) — справочник персонала клиники с указанием ФИО и специализации.
4. services (Услуги) — прайс-лист клиники. Хранит название услуги и ее стоимость (cost).
5. appointments (Приемы) — центральная таблица, связывающая питомца, врача и услугу. Содержит дату приема (appointment_date) и текущий статус (status).
6. status_logs (Журнал статусов) — таблица для автоматического аудита изменений. Хранит историю того, как менялись статусы приемов.

## [Тестовые данные](https://github.com/Robert-hedgehog/bd_project/blob/master/filled_tables.sql) 

## [Операции](https://github.com/Robert-hedgehog/bd_project/blob/master/operation.sql)

## Логика и обработка данных
### Представдение 

v_patient_history — сводная история посещений.
Объединяет данные из таблиц appointments, pets, clients, doctors и services. Позволяет администраторам клиники видеть полную картину приема.

``` SQL
SELECT * FROM `v_patient_history` LIMIT 10;
```

<img width="1123" height="269" alt="изображение" src="https://github.com/user-attachments/assets/cc2e3036-a00f-4a06-9223-4bc3a4aa9699" />


### Триггеры

trg_status_change
Триггер срабатывает на событие AFTER UPDATE в таблице appointments. Если старый статус записи не совпадает с новым (например, прием перешел из статуса «Запланирован» в «Отменен»), триггер автоматически создает запись в таблице status_logs с указанием точного времени изменения.

```SQL
-- Обновление статуса приема

UPDATE appointments 
SET status = 'Отменен' 
WHERE id = 18 
LIMIT 1;

-- Вывод таблицы
SELECT * FROM status_logs;
```

<img width="561" height="123" alt="изображение" src="https://github.com/user-attachments/assets/5648d10f-329c-4458-9917-5ca30d224a55" />

## Запросы

-- Удаление одной отмененной записи

```SQL
DELETE FROM appointments 
WHERE status = 'Отменен'
LIMIT 1;
```

------------------------------------------------------------------------------------

-- Обновление статуса приема

```SQL
UPDATE appointments 
SET status = 'Выполнен' 
WHERE id = 18 
LIMIT 1;
```

------------------------------------------------------------------------------------

-- Добавление нового клиента

```SQL
INSERT INTO clients (firstname, lastname, phone) VALUES 
('Петя', 'Камушкин', '89992112203');
```

------------------------------------------------------------------------------------

-- Общее количество приемов, разбивку по статусам (выполненные, отмененные, запланированные) и общую сумму заработанных средств за выполненные приемы.

```SQL
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
```

<img width="611" height="194" alt="изображение" src="https://github.com/user-attachments/assets/4fc52bc7-34a4-4a3c-b663-ea520d773be8" />


## Функции

getPetAge(birth_year) — динамически высчитывает текущий возраст питомца, отнимая год рождения от текущего года.

```SQL
SELECT name, species, getPetAge(birth_year) AS current_age 
FROM pets;
```

<img width="293" height="418" alt="изображение" src="https://github.com/user-attachments/assets/8e31d32b-2424-45ac-9c4f-03402845b05f" />

------------------------------------------------------------------------------------

short_name(lastname, firstname) — форматирует полное имя сотрудника или клиента в формат с инициалом.

```SQL
SELECT lastname, firstname, short_name(lastname, firstname) AS formatted_name 
FROM clients 
LIMIT 5;
```

<img width="300" height="148" alt="изображение" src="https://github.com/user-attachments/assets/db8c7170-3944-4363-8541-f5ff2e58f310" />

## Процедуры

get_client_history — выводит всю историю приемов для конкретного владельца по его ФИО.

```SQL
CALL get_client_history('Кирилл Баранов');
```

<img width="671" height="126" alt="изображение" src="https://github.com/user-attachments/assets/1f881603-adb0-40b3-a82d-85c8cd93342c" />

------------------------------------------------------------------------------------

get_pets_by_species — ищет всех пациентов определенного вида и выводит их возраст и контакты владельцев.

```SQL
CALL get_pets_by_species('Кошка');
```

<img width="408" height="126" alt="изображение" src="https://github.com/user-attachments/assets/5010ae28-cc38-4210-a28c-d8105987114c" />

------------------------------------------------------------------------------------

get_recent_appointments — генерирует отчет о проведенных или запланированных приемах конкретного врача за последние N дней.

```SQL
CALL get_recent_appointments('Фильченков', 90);
```

<img width="675" height="76" alt="изображение" src="https://github.com/user-attachments/assets/94ab80dc-e039-496b-955e-69c84442bdc4" />

# Заключение

В рамках проекта была успешно спроектирована и реализована реляционная база данных для ветеринарной клиники.

Структура содержит 6 таблиц, обеспечивающих полное покрытие бизнес-процессов регистратуры. Для упрощения аналитики и поддержания согласованности данных внедрены 1 представление, 2 функции, 3 хранимые процедуры и 1 триггер. Все SQL-запросы успешно протестированы на массиве тестовых данных, что подтверждается приведенными результатами выполнения.
