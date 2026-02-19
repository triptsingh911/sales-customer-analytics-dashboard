CREATE DATABASE enterprise_mis;
USE enterprise_mis;


-- CREATE TABLE dim_data
CREATE TABLE dim_date(
	date_id INT PRIMARY KEY,
    full_date DATE NOT NULL,
    day int,
    month int,
    month_name VARCHAR(10),
    quater VARCHAR(2),
    year INT,
    week INT
);

-- Product/Service dimension

CREATE TABLE dim_product(
	product_id INT PRIMARY KEY AUTO_INCREMENT,
    product_name VARCHAR(100),
    category VARCHAR(50),
    sub_category VARCHAR(50),
    standard_cost DECIMAL(10,2),
    active_flag CHAR(1) DEFAULT 'Y'
);

-- Customer Dimension

CREATE TABLE dim_customer(
	customer_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_name VARCHAR(100),
    customer_type VARCHAR(30),
    industry VARCHAR(50),
    region  VARCHAR(50),
    active_flag CHAR(1) DEFAULT 'Y'
);

-- Location Dimension

CREATE TABLE dim_location (
	location_id INT PRIMARY KEY AUTO_INCREMENT,
    location_name VARCHAR(100),
    location_type VARCHAR(30), -- Plant/Office/Region
    country VARCHAR(50),
    state VARCHAR(50),
    city VARCHAR(50)
);

-- Core Fact Table

CREATE TABLE fact_transactions(
	transaction_id BIGINT PRIMARY KEY,
    date_id INT,
    transaction_type VARCHAR(30), -- Sale/Production/Invouice/Text
    product_id INT,
    customer_id INT,
    location_id INT,
    quantity INT,
    amount DECIMAL(12,2),
    status VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	
    FOREIGN KEY(date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY(product_id) REFERENCES dim_product(product_id),
    FOREIGN KEY(customer_id) REFERENCES dim_customer(customer_id),
    FOREIGN KEY(location_id) REFERENCES dim_location(location_id)
);

-- Targets Fact Table (Planning VS Actual)

CREATE TABLE fact_targets(
	target_id INT PRIMARY KEY AUTO_INCREMENT,
    target_month INT, -- YYYYMM
    product_id INT,
    location_id INT,
    target_amount DECIMAL(12,2),
    
    FOREIGN KEY(product_id) REFERENCES dim_product(product_id),
    FOREIGN KEY(location_id) REFERENCES dim_location(location_id)
);


-- Support FACT TABLE(CX/SLA)

CREATE TABLE fact_support_metrics (
	ticket_id BIGINT PRIMARY KEY,
    opened_date INT,
    closed_date INT,
    sla_hours INT,
    resolution_hours INT,
    agent_id INT,
    status VARCHAR(20),
    
    FOREIGN KEY (opened_date) REFERENCES dim_date(date_id),
    FOREIGN KEY (closed_date) REFERENCES dim_date(date_id)
);

-- ETL LOGGING TABLE (ENTERPRICE TOUCH)

CREATE TABLE etl_logs (
	run_id INT PRIMARY KEY AUTO_INCREMENT,
    source_name VARCHAR(50),
    rows_read INT,
    rows_loaded INT,
    error_count INT,
    run_status VARCHAR(20),
    run_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

show tables;

SET SQL_SAFE_UPDATES = 0;
DELETE FROM fact_transactions;
DELETE FROM dim_date;
SET SQL_SAFE_UPDATES = 1;

INSERT INTO dim_date (date_id, full_date, year, month, day, month_name, quarter)
SELECT
    DATE_FORMAT(gen_date, '%Y%m%d') AS date_id,
    gen_date AS full_date,
    YEAR(gen_date) AS year,
    MONTH(gen_date) AS month,
    DAY(gen_date) AS day,
    MONTHNAME(gen_date) AS month_name,
    QUARTER(gen_date) AS quarter
FROM (
    SELECT DATE('2022-01-01') + INTERVAL seq DAY AS gen_date
    FROM (
        SELECT a.N + b.N*10 + c.N*100 + d.N*1000 AS seq
        FROM
        (SELECT 0 N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
        (SELECT 0 N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b,
        (SELECT 0 N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) c,
        (SELECT 0 N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3) d
    ) seqs
    WHERE seq <= 1460
) dates;

SET SQL_SAFE_UPDATES = 0;
DELETE FROM fact_transactions;
SET SQL_SAFE_UPDATES = 1;

-- DAILY / MONTHLY / YEARLY SALES
-- Total Revenue by Day
SELECT
    d.full_date,
    SUM(f.amount) AS total_revenue
FROM fact_transactions f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.full_date
ORDER BY d.full_date;

-- Monthly Revenue

SELECT
    d.year,
    d.month,
    d.month_name,
    SUM(f.amount) AS monthly_revenue
FROM fact_transactions f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.year, d.month, d.month_name
ORDER BY d.year, d.month;

-- Yearly Revenue

SELECT
    d.year,
    d.month,
    d.month_name,
    SUM(f.amount) AS monthly_revenue
FROM fact_transactions f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.year, d.month, d.month_name
ORDER BY d.year, d.month;

-- Product Performance 

SELECT
    p.product_name,
    SUM(f.quantity) AS total_units_sold,
    SUM(f.amount) AS total_revenue
FROM fact_transactions f
JOIN dim_product p ON f.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_revenue DESC;

-- Top 5 Product by Revenue

SELECT
    p.product_name,
    SUM(f.amount) AS revenue
FROM fact_transactions f
JOIN dim_product p ON f.product_id = p.product_id
GROUP BY p.product_name
ORDER BY revenue DESC
LIMIT 5;

-- Revenue by Customer

SELECT
    c.customer_name,
    SUM(f.amount) AS revenue
FROM fact_transactions f
JOIN dim_customer c ON f.customer_id = c.customer_id
GROUP BY c.customer_name
ORDER BY revenue DESC;

-- Top Customer (Pareto)

SELECT
    c.customer_name,
    SUM(f.amount) AS revenue
FROM fact_transactions f
JOIN dim_customer c ON f.customer_id = c.customer_id
GROUP BY c.customer_name
ORDER BY revenue DESC
LIMIT 10;

-- Time Based Growth
-- Month over month growth

SELECT
    year,
    month,
    month_name,
    revenue,
    revenue - LAG(revenue) OVER (ORDER BY year, month) AS mom_change,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY year, month))
        / LAG(revenue) OVER (ORDER BY year, month) * 100,
        2
    ) AS mom_growth_pct
FROM (
    SELECT
        d.year,
        d.month,
        d.month_name,
        SUM(f.amount) AS revenue
    FROM fact_transactions f
    JOIN dim_date d ON f.date_id = d.date_id
    GROUP BY d.year, d.month, d.month_name
) t;

-- Quater wise revenue

SELECT
    d.year,
    d.quarter,
    SUM(f.amount) AS quarterly_revenue
FROM fact_transactions f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.year, d.quarter
ORDER BY d.year, d.quarter;

-- Average order value (AOV)

SELECT
    ROUND(SUM(amount) / COUNT(DISTINCT transaction_id), 2) AS avg_order_value
FROM fact_transactions;


-- Sales Contribution % by product

SELECT
    p.product_name,
    ROUND(
        SUM(f.amount) * 100.0 /
        (SELECT SUM(amount) FROM fact_transactions),
        2
    ) AS revenue_pct
FROM fact_transactions f
JOIN dim_product p ON f.product_id = p.product_id
GROUP BY p.product_name
ORDER BY revenue_pct DESC;

-- Management Summary (one quary dashboard)

SELECT
    COUNT(DISTINCT f.transaction_id) AS total_orders,
    COUNT(DISTINCT f.customer_id) AS total_customers,
    SUM(f.quantity) AS total_units,
    SUM(f.amount) AS total_revenue,
    ROUND(SUM(f.amount) / COUNT(DISTINCT f.transaction_id), 2) AS avg_order_value
FROM fact_transactions f;

SELECT location_id, COUNT(*)
FROM dim_location
GROUP BY location_id
HAVING COUNT(*) > 1;

SET SQL_SAFE_UPDATES = 0;


DELETE l1
FROM dim_location l1
JOIN dim_location l2
  ON l1.location_id = l2.location_id
 AND l1.location_name > l2.location_name;


SET SQL_SAFE_UPDATES = 1;


SELECT location_id, COUNT(*) AS cnt
FROM fact_transactions
GROUP BY location_id
HAVING COUNT(*) > 1;





INSERT INTO dim_location (
    location_id,
    location_name,
    city,
    state,
    country,
    location_type
)
VALUES (
    -1,
    'UNKNOWN',
    'UNKNOWN',
    'UNKNOWN',
    'UNKNOWN',
    'UNKNOWN'
);

UPDATE fact_transactions
SET location_id = -1
WHERE location_id IS NULL;

SET SQL_SAFE_UPDATES = 0;
-- run update
SET SQL_SAFE_UPDATES = 1;

SELECT COUNT(*)
FROM fact_transactions
WHERE location_id IS NULL;


SELECT location_id, COUNT(*)
FROM fact_transactions
GROUP BY location_id;


SELECT
  COUNT(*) AS fact_rows,
  COUNT(DISTINCT product_id) AS products_used,
  COUNT(DISTINCT location_id) AS locations_used,
  COUNT(DISTINCT date_id) AS dates_used
FROM fact_transactions;



-- -------------BUlk Realistic-----------

SELECT date_id, full_date
FROM dim_date
ORDER BY date_id;

SELECT DISTINCT product_id, product_name
FROM dim_product
ORDER BY product_id;

SELECT customer_id, customer_name
FROM dim_customer;

SELECT location_id, city
FROM dim_location;

SELECT * FROM dim_date WHERE date_id = 20220610;




-- TEMPORARY TABLE--------
CREATE TEMPORARY TABLE seq_0_to_2000 (n INT);

INSERT INTO seq_0_to_2000 (n)
SELECT a.N + b.N * 10 + c.N * 100
FROM (SELECT 0 N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
      UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
     (SELECT 0 N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
      UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b,
     (SELECT 0 N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
      UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) c;

INSERT INTO dim_date
(date_id, full_date, day, month, month_name, quarter, year, week)
SELECT
  DATE_FORMAT(d, '%Y%m%d') AS date_id,
  d AS full_date,
  DAY(d),
  MONTH(d),
  MONTHNAME(d),
  QUARTER(d),
  YEAR(d),
  WEEK(d, 1)
FROM (
  SELECT DATE('2021-01-01') + INTERVAL n DAY AS d
  FROM seq_0_to_2000
  WHERE DATE('2021-01-01') + INTERVAL n DAY <= '2023-12-31'
) x
ON DUPLICATE KEY UPDATE full_date = full_date;

SELECT COUNT(*) FROM dim_date;

SELECT date_id, full_date FROM dim_date WHERE date_id IN
(20211001, 20220610, 20230104, 20230515);

SELECT COUNT(*) FROM dim_customer;




-- Confirm valid ID ranges
-- Customers
SELECT MIN(customer_id), MAX(customer_id) FROM dim_customer;

-- Products
SELECT MIN(product_id), MAX(product_id) FROM dim_product;

-- Locations
SELECT location_id, city FROM dim_location;

-- Dates
SELECT MIN(date_id), MAX(date_id) FROM dim_date;


-- REALISTIC DATA

INSERT INTO fact_transactions
(transaction_id, date_id, transaction_type, product_id, customer_id, location_id, quantity, amount, status, created_at)
VALUES
-- 2021 (Enterprise-heavy)
(5001, 20211001, 'SALE', 9,  1, 1, 10, 450000, 'Completed', '2021-10-01'),
(5002, 20211015, 'SALE', 10, 2, 1,  5, 260000, 'Completed', '2021-10-15'),
(5003, 20211110, 'SALE', 11, 3, 2, 20, 900000, 'Completed', '2021-11-10'),
(5004, 20211205, 'SALE', 12, 4, 2, 15, 180000, 'Completed', '2021-12-05'),

-- 2022 (Growth)
(5005, 20220112, 'SALE', 13, 5, 1,  6, 270000, 'Completed', '2022-01-12'),
(5006, 20220218, 'SALE', 14, 6, 2,  4, 208000, 'Completed', '2022-02-18'),
(5007, 20220325, 'SALE', 15, 7, 1, 12, 540000, 'Completed', '2022-03-25'),
(5008, 20220430, 'SALE', 16, 8, 2,  3,  96000, 'Completed', '2022-04-30'),
(5009, 20220610, 'SALE', 17, 9, 1,  3, 135000, 'Cancelled', '2022-06-10'),

-- 2023 (Retail expansion)
(5010, 20230104, 'SALE', 18, 10, 1,  2, 104000, 'Completed', '2023-01-04'),
(5011, 20230218, 'SALE', 19, 11, 2,  5, 225000, 'Completed', '2023-02-18'),
(5012, 20230310, 'SALE', 20, 12, 2,  3,  36000, 'Completed', '2023-03-10'),
(5013, 20230422, 'SALE', 21, 13, 1,  4, 180000, 'Completed', '2023-04-22'),
(5014, 20230515, 'SALE', 22, 14, 2,  1,  52000, 'Cancelled', '2023-05-15');


SELECT
  COUNT(*) AS fact_rows,
  COUNT(DISTINCT customer_id) AS customers,
  COUNT(DISTINCT product_id) AS products,
  COUNT(DISTINCT location_id) AS locations,
  COUNT(DISTINCT date_id) AS dates
FROM fact_transactions;




-- ----------SCALING THE DATA------------

INSERT INTO dim_location (location_id, city, state, country, location_type)
VALUES
(3, 'Mumbai', 'Maharashtra', 'India', 'Urban'),
(4, 'Pune', 'Maharashtra', 'India', 'Urban'),
(5, 'Chennai', 'Tamil Nadu', 'India', 'Urban'),
(6, 'Coimbatore', 'Tamil Nadu', 'India', 'Urban'),
(7, 'Hyderabad', 'Telangana', 'India', 'Urban'),
(8, 'Warangal', 'Telangana', 'India', 'Urban'),
(9, 'Kolkata', 'West Bengal', 'India', 'Urban'),
(10, 'Howrah', 'West Bengal', 'India', 'Urban'),
(11, 'Jaipur', 'Rajasthan', 'India', 'Urban'),
(12, 'Udaipur', 'Rajasthan', 'India', 'Urban');



INSERT INTO dim_customer (customer_id, customer_name, customer_type)
SELECT
  id,
  CONCAT('Customer_', id),
  CASE
    WHEN id % 5 = 0 THEN 'Enterprise'
    ELSE 'Retail'
  END
FROM (
  SELECT 1001 AS id UNION ALL SELECT 1002 UNION ALL SELECT 1003
  -- generate up to 2000 using your DB method
) t;

INSERT INTO fact_transactions
(transaction_id, date_id, transaction_type, product_id, customer_id,
 location_id, quantity, amount, status, created_at)
SELECT
  600000 + ROW_NUMBER() OVER (),
  d.date_id,
  'SALE',
  p.product_id,
  c.customer_id,
  l.location_id,
  FLOOR(1 + RAND()*5),
  FLOOR(20000 + RAND()*300000),
  CASE WHEN RAND() < 0.9 THEN 'Completed' ELSE 'Cancelled' END,
  d.full_date
FROM dim_date d
JOIN dim_customer c ON c.customer_id BETWEEN 1001 AND 1500
JOIN dim_product p ON p.product_id IN (9,10,11,12)
JOIN dim_location l ON l.location_id BETWEEN 1 AND 12
WHERE d.year BETWEEN 2021 AND 2024
LIMIT 50000;


