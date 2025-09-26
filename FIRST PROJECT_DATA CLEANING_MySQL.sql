-- Show available databases
SHOW DATABASES;

-- Use the 'world_layoffs' database
USE world_layoffs;

-- Select all data from the 'layoffs' table
SELECT * FROM layoffs;

-- 1. Remove Duplicates
-- 2. Standardize the Data
-- 3. Handle Null Values
-- 4. Remove Unnecessary Columns

-- Step 1: Create a staging table with the same structure as 'layoffs'
CREATE TABLE layoffs_staging LIKE layoffs;

-- Verify the structure of the new staging table
SELECT * FROM layoffs_staging;

-- Insert data from the original table into the staging table
INSERT INTO layoffs_staging SELECT * FROM layoffs;

-- Step 1: Remove Duplicates
-- Add a row number to each record partitioned by key columns to identify duplicates
SELECT *,
ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Create a Common Table Expression (CTE) to handle duplicates
WITH duplicate_cte AS (
    SELECT *,
    ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
    FROM layoffs_staging
)
-- Delete records from the CTE where the row number is greater than 1 (indicating duplicates)
DELETE FROM duplicate_cte WHERE row_num > 1;

-- Verify if duplicates for a specific company (e.g., 'Casper') have been removed
SELECT * FROM layoffs_staging WHERE company = 'Casper';

-- Step 2: Create a new staging table with an additional 'row_num' column to handle duplicates
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Insert data into the new staging table with 'row_num' added
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Delete records from the new staging table where 'row_num' is greater than 1 (removing duplicates)
DELETE FROM layoffs_staging2 WHERE row_num > 1;

-- Check for remaining duplicates in the new staging table
SELECT * FROM layoffs_staging2 WHERE row_num > 1;

-- Verify the data in the new staging table
SELECT * FROM layoffs_staging2;

-- Step 2: Standardize Data
-- Trim whitespace from the 'company' column
SELECT company, TRIM(company) FROM layoffs_staging2;

UPDATE layoffs_staging2 SET company = TRIM(company);

-- Check distinct values in the 'industry' column
SELECT DISTINCT industry FROM layoffs_staging2 ORDER BY 1;

-- Standardize the 'industry' column to have a consistent value for 'Crypto'
SELECT * FROM layoffs_staging2 WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging2 SET industry = 'Crypto' WHERE industry LIKE 'Crypto%';

-- Check distinct values in the 'location' column
SELECT DISTINCT location FROM layoffs_staging2 ORDER BY 1;

-- Trim trailing periods from the 'country' column
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country) FROM layoffs_staging2 ORDER BY 1;

UPDATE layoffs_staging2 SET country = TRIM(TRAILING '.' FROM country) WHERE country LIKE 'United States%';

-- Convert 'date' column to the appropriate date format
SELECT `date` FROM layoffs_staging2;

UPDATE layoffs_staging2 SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2 MODIFY COLUMN `date` DATE;

-- Step 3: Handle Null Values
-- Identify records with NULL values in key columns
SELECT * FROM layoffs_staging2 WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

SELECT * FROM layoffs_staging2 WHERE industry IS NULL OR industry = '';

-- Example: Handle NULL values for a specific company (e.g., 'Airbnb')
SELECT * FROM layoffs_staging2 WHERE company = 'Airbnb';

-- Set industry to NULL where the value is empty
UPDATE layoffs_staging2 SET industry = NULL WHERE industry = '';

-- Populate NULL 'industry' values based on other records with the same company and location
SELECT st1.industry, st2.industry
FROM layoffs_staging2 AS st1
JOIN layoffs_staging2 AS st2
    ON st1.company = st2.company AND st1.location = st2.location
WHERE (st1.industry IS NULL OR st1.industry = '') AND st2.industry IS NOT NULL;

UPDATE layoffs_staging2 AS st1
JOIN layoffs_staging2 AS st2
    ON st1.company = st2.company
SET st1.industry = st2.industry
WHERE st1.industry IS NULL AND st2.industry IS NOT NULL;

-- Verify the data after handling NULL values
SELECT * FROM layoffs_staging2;

-- Step 4: Remove Unnecessary Columns
-- Identify records with NULL values in both 'total_laid_off' and 'percentage_laid_off' columns
SELECT * FROM layoffs_staging2 WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

-- Delete records where both 'total_laid_off' and 'percentage_laid_off' are NULL
DELETE FROM layoffs_staging2 WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

-- Drop the 'row_num' column as it is no longer needed
ALTER TABLE layoffs_staging2 DROP COLUMN row_num;

-- Final verification of the data
SELECT * FROM layoffs_staging2;
