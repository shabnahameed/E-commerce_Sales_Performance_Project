-- =====================================
-- PROJECT: ECOMMERCE SALES DATA CLEANING
-- DATABASE: PROJECT
-- TABLE: Ecomm_Dataset
-- =====================================

-- Step 1: Create Database and Table
CREATE DATABASE Project;
USE Project;

CREATE TABLE Ecomm_Dataset (
    customer_id     VARCHAR(20) NOT NULL,
    first_name      VARCHAR(20) NOT NULL,
    last_name       VARCHAR(20) NOT NULL,
    gender          VARCHAR(20) NOT NULL,
    age_group       VARCHAR(20) NOT NULL,
    signup_date     DATE NOT NULL,
    country         VARCHAR(20) NOT NULL,
    product_id      VARCHAR(20) NOT NULL,
    product_name    VARCHAR(50) NOT NULL,
    category        VARCHAR(30) NOT NULL,
    quantity        INT NOT NULL,
    unit_price      DECIMAL(10,2) NOT NULL, 
    order_id        VARCHAR(20) NOT NULL,
    order_date      DATE NOT NULL,
    order_status    VARCHAR(20) NOT NULL,
    payment_method  VARCHAR(20) NOT NULL,
    rating          INT NOT NULL,
    review_text     VARCHAR(100) NOT NULL,
    review_id       VARCHAR(20) NOT NULL,
    review_date     DATE NOT NULL,
    PRIMARY KEY (customer_id)
);

--  Load Data from CSV File

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Ecommerce sales data.csv'
INTO TABLE Ecomm_Dataset
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(customer_id, first_name, last_name, gender, age_group, @signup_date, country,
 product_id, product_name, category, quantity, unit_price, order_id, @order_date,
 order_status, payment_method, rating, review_text, review_id, @review_date)
SET 
 signup_date = STR_TO_DATE(@signup_date, '%d-%m-%Y'),
 order_date  = STR_TO_DATE(@order_date, '%d-%m-%Y'),
 review_date = STR_TO_DATE(@review_date, '%d-%m-%Y');

-- : Update Primary Key

ALTER TABLE Ecomm_Dataset
DROP PRIMARY KEY,
ADD PRIMARY KEY (customer_id, order_id);

-- : Check secure file path

SHOW VARIABLES LIKE 'secure_file_priv';

--  Check Missing Values

SELECT 
    SUM(customer_id IS NULL OR customer_id='') AS missing_customer_id,
    SUM(first_name IS NULL OR first_name='') AS missing_first_name,
    SUM(last_name IS NULL OR last_name='') AS missing_last_name,
    SUM(gender IS NULL OR gender='') AS missing_gender,
    SUM(age_group IS NULL OR age_group='') AS missing_age_group,
    SUM(signup_date IS NULL) AS missing_signup_date,
    SUM(country IS NULL OR country='') AS missing_country,
    SUM(product_id IS NULL OR product_id='') AS missing_product_id,
    SUM(product_name IS NULL OR product_name='') AS missing_product_name,
    SUM(category IS NULL OR category='') AS missing_category,
    SUM(quantity IS NULL) AS missing_quantity,
    SUM(unit_price IS NULL) AS missing_unit_price,
    SUM(order_id IS NULL OR order_id='') AS missing_order_id,
    SUM(order_date IS NULL) AS missing_order_date,
    SUM(order_status IS NULL OR order_status='') AS missing_order_status,
    SUM(payment_method IS NULL OR payment_method='') AS missing_payment_method,
    SUM(rating IS NULL) AS missing_rating,
    SUM(review_text IS NULL OR review_text='') AS missing_review_text,
    SUM(review_id IS NULL OR review_id='') AS missing_review_id,
    SUM(review_date IS NULL) AS missing_review_date
FROM Ecomm_Dataset;

-- Create a Cleaned Table with UPPERCASE Columns

CREATE TABLE Ecommerce_Dataset AS 
SELECT
    customer_id   AS CUSTOMER_ID,
    first_name    AS FIRST_NAME,
    last_name     AS LAST_NAME,
    gender        AS GENDER,
    age_group     AS AGE_GROUP,
    signup_date   AS SIGNUP_DATE,
    country       AS COUNTRY,
    product_id    AS PRODUCT_ID,
    product_name  AS PRODUCT_NAME,
    category      AS CATEGORY,
    quantity      AS QUANTITY,
    unit_price    AS UNIT_PRICE,
    order_id      AS ORDER_ID,
    order_date    AS ORDER_DATE,
    order_status  AS ORDER_STATUS,
    payment_method AS PAYMENT_METHOD,
    rating        AS RATING,
    review_text   AS REVIEW_TEXT,
    review_id     AS REVIEW_ID,
    review_date   AS REVIEW_DATE
FROM Ecomm_Dataset;

-- Trim Extra Spaces

SET SQL_SAFE_UPDATES = 0;
UPDATE Ecommerce_Dataset
SET
    FIRST_NAME = TRIM(FIRST_NAME),
    LAST_NAME = TRIM(LAST_NAME),
    GENDER = TRIM(GENDER),
    AGE_GROUP = TRIM(AGE_GROUP),
    COUNTRY = TRIM(COUNTRY),
    PRODUCT_NAME = TRIM(PRODUCT_NAME),
    CATEGORY = TRIM(CATEGORY),
    ORDER_STATUS = TRIM(ORDER_STATUS),
    PAYMENT_METHOD = TRIM(PAYMENT_METHOD),
    REVIEW_TEXT = TRIM(REVIEW_TEXT);
SET SQL_SAFE_UPDATES = 1;

-- : Check for Duplicates

SELECT CUSTOMER_ID, ORDER_ID, COUNT(*) AS duplicate_count
FROM Ecommerce_Dataset
GROUP BY CUSTOMER_ID, ORDER_ID
HAVING COUNT(*) > 1;

-- Detect Outliers (Rating-based)

WITH stats AS (
    SELECT AVG(RATING) AS mean_rating, STDDEV(RATING) AS std_rating
    FROM Ecommerce_Dataset
)
SELECT e.*, ROUND((e.RATING - s.mean_rating)/s.std_rating, 2) AS z_score
FROM Ecommerce_Dataset e
CROSS JOIN stats s
WHERE ABS((e.RATING - s.mean_rating)/s.std_rating) > 3;

-- Add Calculated Columns

ALTER TABLE Ecommerce_Dataset
ADD COLUMN SALES DECIMAL(10,2),
ADD COLUMN ORDER_MONTH VARCHAR(15);

-- Calculate Sales (Excluding Returned/Cancelled)

SET SQL_SAFE_UPDATES = 0;
UPDATE Ecommerce_Dataset
SET SALES = CASE
    WHEN ORDER_STATUS NOT IN ('Returned', 'Cancelled') THEN QUANTITY * UNIT_PRICE
    ELSE 0
END;
SET SQL_SAFE_UPDATES = 1;

-- Extract Order Month

SET SQL_SAFE_UPDATES = 0;
UPDATE Ecommerce_Dataset
SET ORDER_MONTH = DATE_FORMAT(ORDER_DATE, '%Y-%M');
SET SQL_SAFE_UPDATES = 1;

-- Final Check

SELECT * FROM Ecommerce_Dataset;
