CREATE DATABASE IF NOT EXISTS `vetclinic_db` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `vetclinic_db`;

-- 1 Таблица клиентов 
CREATE TABLE `clients` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `firstname` VARCHAR(100) NOT NULL,
    `lastname` VARCHAR(100) NOT NULL,
    `phone` VARCHAR(20) NOT NULL,
    UNIQUE `idx_phone` (`phone`)
);

-- 2 Таблица питомцев
CREATE TABLE `pets` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `client_id` INT UNSIGNED NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `species` VARCHAR(100) NOT NULL,
    `birth_year` YEAR,
    INDEX `idx_client` (`client_id`)
);

-- 3 Таблица врачей
CREATE TABLE `doctors` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `firstname` VARCHAR(100) NOT NULL,
    `lastname` VARCHAR(100) NOT NULL,
    `specialization` VARCHAR(100) NOT NULL
);

-- 4 Таблица услуг
CREATE TABLE `services` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(255) NOT NULL,
    `cost` DECIMAL(10, 2) UNSIGNED NOT NULL
);

-- 5 Таблица приемов
CREATE TABLE `appointments` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `pet_id` INT UNSIGNED NOT NULL,
    `doctor_id` INT UNSIGNED NOT NULL,
    `service_id` INT UNSIGNED NOT NULL,
    `appointment_date` DATETIME NOT NULL,
    `status` VARCHAR(50) DEFAULT 'Запланирован',
    INDEX `idx_pet` (`pet_id`),
    INDEX `idx_doctor` (`doctor_id`)
);

-- 6 Таблица логирования
CREATE TABLE `status_logs` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `appointment_id` INT UNSIGNED NOT NULL,
    `old_status` VARCHAR(50) DEFAULT NULL,
    `new_status` VARCHAR(50) DEFAULT NULL,
    `changed_at` DATETIME NOT NULL
);
