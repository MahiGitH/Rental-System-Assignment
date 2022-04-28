DROP DATABASE IF EXISTS `rental_db`;
CREATE DATABASE `rental_db`;
USE `rental_db`;
 
-- Create `vehicles` table
DROP TABLE IF EXISTS `vehicles`;
CREATE TABLE `vehicles` (
   `veh_reg_no`  VARCHAR(8)    NOT NULL,
   `category`    ENUM('car', 'truck')  NOT NULL DEFAULT 'car',  
                 -- Enumeration of one of the items in the list
   `brand`       VARCHAR(30)   NOT NULL DEFAULT '',
   `desc`        VARCHAR(256)  NOT NULL DEFAULT '',
                 -- desc is a keyword (for descending) and must be back-quoted
   `photo`       BLOB          NULL,   -- binary large object of up to 64KB
                 -- to be implemented later
   `daily_rate`  DECIMAL(6,2)  NOT NULL DEFAULT 9999.99,
                 -- set default to max value
   PRIMARY KEY (`veh_reg_no`),
   INDEX (`category`)  -- Build index on this column for fast search
) ENGINE=InnoDB;
   -- MySQL provides a few ENGINEs.
   -- The InnoDB Engine supports foreign keys and transactions
DESC `vehicles`;
SHOW CREATE TABLE `vehicles`;
SHOW INDEX FROM `vehicles`;
 
-- Create `customers` table
DROP TABLE IF EXISTS `customers`;
CREATE TABLE `customers` (
   `customer_id`  INT UNSIGNED  NOT NULL AUTO_INCREMENT,
                  -- Always use INT for AUTO_INCREMENT column to avoid run-over
   `name`         VARCHAR(30)   NOT NULL DEFAULT '',
   `address`      VARCHAR(80)   NOT NULL DEFAULT '',
   `phone`        VARCHAR(15)   NOT NULL DEFAULT '',
   `discount`     DOUBLE        NOT NULL DEFAULT 0.0,
   PRIMARY KEY (`customer_id`),
   UNIQUE INDEX (`phone`),  -- Build index on this unique-value column
   INDEX (`name`)           -- Build index on this column
) ENGINE=InnoDB;
DESC `customers`;
SHOW CREATE TABLE `customers`;
SHOW INDEX FROM `customers`;
 
-- Create `rental_records` table
DROP TABLE IF EXISTS `rental_records`;
CREATE TABLE `rental_records` (
   `rental_id`    INT UNSIGNED  NOT NULL AUTO_INCREMENT,
   `veh_reg_no`   VARCHAR(8)    NOT NULL, 
   `customer_id`  INT UNSIGNED  NOT NULL,
   `start_date`   DATE          NOT NULL DEFAULT('0000-00-00'),
   `end_date`     DATE          NOT NULL DEFAULT('0000-00-00'),
   `lastUpdated`  TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      -- Keep the created and last updated timestamp for auditing and security
   PRIMARY KEY (`rental_id`),
   FOREIGN KEY (`customer_id`) REFERENCES `customers` (`customer_id`)
      ON DELETE RESTRICT ON UPDATE CASCADE,
      -- Disallow deletion of parent record if there are matching records here
      -- If parent record (customer_id) changes, update the matching records here
   FOREIGN KEY (`veh_reg_no`) REFERENCES `vehicles` (`veh_reg_no`)
      ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;
DESC `rental_records`;
SHOW CREATE TABLE `rental_records`;
SHOW INDEX FROM `rental_records`;

-- Inserting test records
INSERT INTO `vehicles` VALUES
   ('SBA1111A', 'car', 'NISSAN SUNNY 1.6L', '4 Door Saloon, Automatic', NULL, 99.99),
   ('SBB2222B', 'car', 'TOYOTA ALTIS 1.6L', '4 Door Saloon, Automatic', NULL, 99.99),
   ('SBC3333C', 'car', 'HONDA CIVIC 1.8L',  '4 Door Saloon, Automatic', NULL, 119.99),
   ('GA5555E', 'truck', 'NISSAN CABSTAR 3.0L',  'Lorry, Manual ', NULL, 89.99),
   ('GA6666F', 'truck', 'OPEL COMBO 1.6L',  'Van, Manual', NULL, 69.99);
   -- No photo yet, set to NULL
SELECT * FROM `vehicles`;
 
INSERT INTO `customers` VALUES
   (1001, 'Angel', '8 Happy Ave', '88888888', 0.1),
   (NULL, 'Mohammed Ali', '1 Kg Java', '99999999', 0.15),
   (NULL, 'Kumar', '5 Serangoon Road', '55555555', 0),
   (NULL, 'Kevin Jones', '2 Sunset boulevard', '22222222', 0.2);
SELECT * FROM `customers`;
 
INSERT INTO `rental_records` VALUES
  (NULL, 'SBA1111A', 1001, '2012-01-01', '2012-01-21', NULL),
  (NULL, 'SBA1111A', 1001, '2012-02-01', '2012-02-05', NULL),
  (NULL, 'GA5555E',  1003, '2012-01-05', '2012-01-31', NULL),
  (NULL, 'GA6666F',  1004, '2012-01-20', '2012-02-20', NULL);
SELECT * FROM `rental_records`;

/*****************************SQL Queries**********************/
/*Q1. Customer 'Angel' has rented 'SBA1111A' from today for 10 days.*/
INSERT INTO rental_records VALUES
 (NULL,
'SBA1111A',
 (SELECT customer_id FROM customers WHERE name='Angel'),
 CURDATE(),
DATE_ADD(CURDATE(), INTERVAL 10 DAY),
NULL);

/*Q2. Customer 'Kumar' has rented 'GA5555E' from tomorrow for 3 months.*/
INSERT INTO rental_records VALUES
 (NULL, 'GA5555E',
 (SELECT customer_id FROM customers WHERE name='Kumar'),
 CURDATE() + 1, DATE_ADD(CURDATE() + 1, INTERVAL 3 month),
 NULL);
 
 /* Q3. List all rental records (start date, end date) with vehicle's registration number, brand, and customer name, 
 sorted by vehicle's categories followed by start date.*/
SELECT
rd.start_date AS `Start Date`,
rd.end_date AS `End Date`,
rd.veh_reg_no AS `Vehicle No`,
vr.brand AS `Vehicle Brand`,
cust.name AS `Customer Name`
FROM rental_records AS rd
INNER JOIN vehicles AS vr USING (veh_reg_no)
INNER JOIN customers AS cust USING (customer_id)
ORDER BY vr.category, start_date;

/* Q4. List all the expired rental records (end_date before CURDATE()).*/
SELECT end_date
FROM rental_records
WHERE end_date < curdate();

/* Q5. List the vehicles rented out on '2012-01-10' (not available for rental), in columns of vehicle registration no, customer name, start date and end date.
 (Hint: the given date is in between the start_date and end_date.)*/
SELECT 
rental_records.veh_reg_no AS 'vehicle registration no',
customers.name AS 'customer name',
rental_records.start_date AS 'start date',
rental_records.end_date AS 'end date'
FROM rental_records
INNER JOIN customers
ON customers.customer_id = rental_records.customer_id
WHERE '2012-01-10' BETWEEN rental_records.start_date AND rental_records.end_date;

/* Q6. List all vehicles rented out today, in columns registration number, customer name, start date, end date.*/
SELECT
rental_records.veh_reg_no AS 'registration number',
customers.name AS 'customer name',
rental_records.start_date AS 'start date',
rental_records.end_date AS 'end date'
FROM rental_records
INNER JOIN customers
ON customers.customer_id = rental_records.customer_id
WHERE curdate() = rental_records.start_date;

/*Q7. Similarly, list the vehicles rented out (not available for rental) for the period from '2012-01-03' to '2012-01-18'.*/
SELECT
rental_records.veh_reg_no,
customers.name,
rental_records.start_date,
rental_records.end_date
FROM rental_records
INNER JOIN customers
ON customers.customer_id = rental_records.customer_id
WHERE rental_records.start_date BETWEEN '2012-01-03' AND '2012-01-18'
OR  rental_records.end_date BETWEEN '2012-01-03' AND '2012-01-18'
OR rental_records.start_date < '2012-01-03' AND rental_records.end_date > '2012-01-18';

/*Q8. List the vehicles (registration number, brand and description) available for rental (not rented out) on '2012-01-10'*/
SELECT 
vehicles.veh_reg_no AS 'registration number',
vehicles.brand AS 'brand',
vehicles.desc AS description
FROM vehicles
LEFT JOIN rental_records
ON vehicles.veh_reg_no = rental_records.veh_reg_no
WHERE vehicles.veh_reg_no not in (
SELECT veh_reg_no 
FROM rental_records 
WHERE rental_records.start_date < '2012-01-10' 
AND rental_records.end_date > '2012-01-10');

/*Q9. Similarly, list the vehicles available for rental for the period from '2012-01-03' to '2012-01-18'*/
SELECT veh_reg_no, brand, vehicles.desc FROM vehicles
LEFT JOIN rental_records USING (veh_reg_no)
WHERE veh_reg_no NOT IN (
SELECT veh_reg_no FROM rental_records
WHERE (start_date > '2012-01-03' AND start_date < '2012-01-18') OR
(end_date < '2012-01-03' AND end_date < '2012-01-18') OR 
(start_date < '2012-01-03' AND end_date > '2012-01-18')
);

/*Q10. Similarly, list the vehicles available for rental from today for 10 days.*/
SELECT DISTINCT
vehicles.veh_reg_no AS 'registration number',
vehicles.brand AS 'brand',
vehicles.desc AS description
FROM vehicles
LEFT JOIN rental_records
ON vehicles.veh_reg_no = rental_records.veh_reg_no
WHERE vehicles.veh_reg_no NOT IN  (
SELECT veh_reg_no 
FROM rental_records 
WHERE rental_records.start_date BETWEEN curdate() AND date_add(curdate(), INTERVAL 10 DAY));