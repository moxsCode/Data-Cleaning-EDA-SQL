-- SECOND PROJECT DATA CLEANING
SHOW DATABASES;

USE fast_food_sales;

SELECT * FROM b_fast_food_sales;

-- 1. Remove Duplicates
-- 2. Standardize the Data
-- 3. Handle Null Values
-- 4. Remove Unnecessary Columns

-- I.)
CREATE TABLE salesTransactions LIKE b_fast_food_sales;

INSERT INTO salesTransactions
SELECT * FROM b_fast_food_sales;

SELECT * FROM salesTransactions;

WITH duplicate_cte AS(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY order_id, `date`, item_name, item_type, item_price, quantity, transaction_amount, transaction_type, received_by, time_of_sale) AS row_num
FROM SalesTransactions)

SELECT * FROM duplicate_cte
WHERE row_num > 2;

-- No Duplicates

-- II.)
SELECT * FROM b_fast_food_sales;

SELECT `date` 
FROM salesTransactions;

UPDATE salesTransactions 
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y')
WHERE `date` LIKE '%/%/%';

UPDATE salesTransactions 
SET `date` = STR_TO_DATE(`date`, '%m-%d-%Y')
WHERE `date` LIKE '%-%-%';

UPDATE salesTransactions 
SET `date` = STR_TO_DATE(`date`, '%m-%d-%Y')
WHERE `date` LIKE '%-%-%' AND `date` NOT LIKE '____-__-__';














