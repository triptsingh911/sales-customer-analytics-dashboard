-- Total Revenue

SELECT 
    SUM(amount) AS total_revenue
FROM fact_transactions
WHERE status = 'Completed';

-- Total Orders

SELECT 
    COUNT(DISTINCT transaction_id) AS total_orders
FROM fact_transactions
WHERE status = 'Completed';


-- Average Order Value (AOV)

SELECT 
    ROUND(
        SUM(amount) / COUNT(DISTINCT transaction_id),
        2
    ) AS avg_order_value
FROM fact_transactions
WHERE status = 'Completed';

-- Total Quantity Sold

SELECT 
    SUM(quantity) AS total_units_sold
FROM fact_transactions
WHERE status = 'Completed';

-- Revenue by Year

SELECT 
    d.year,
    SUM(f.amount) AS revenue
FROM fact_transactions f
JOIN dim_date d ON f.date_id = d.date_id
WHERE f.status = 'Completed'
GROUP BY d.year
ORDER BY d.year;

-- Revenue by Month (Trend)

SELECT 
    d.year,
    d.month,
    d.month_name,
    SUM(f.amount) AS revenue
FROM fact_transactions f
JOIN dim_date d ON f.date_id = d.date_id
WHERE f.status = 'Completed'
GROUP BY d.year, d.month, d.month_name
ORDER BY d.year, d.month;

-- Top 10 Product by revenue

SELECT 
    p.product_name,
    SUM(f.amount) AS revenue
FROM fact_transactions f
JOIN dim_product p ON f.product_id = p.product_id
WHERE f.status = 'Completed'
GROUP BY p.product_name
ORDER BY revenue DESC
LIMIT 10;

-- Revenue by Product Category

SELECT 
    p.category,
    SUM(f.amount) AS revenue
FROM fact_transactions f
JOIN dim_product p ON f.product_id = p.product_id
WHERE f.status = 'Completed'
GROUP BY p.category
ORDER BY revenue DESC;

-- Revenue by Customer Type

SELECT 
    c.customer_type,
    SUM(f.amount) AS revenue
FROM fact_transactions f
JOIN dim_customer c ON f.customer_id = c.customer_id
WHERE f.status = 'Completed'
GROUP BY c.customer_type;

-- Top Customers by Revenue

SELECT 
    c.customer_name,
    SUM(f.amount) AS revenue
FROM fact_transactions f
JOIN dim_customer c ON f.customer_id = c.customer_id
WHERE f.status = 'Completed'
GROUP BY c.customer_name
ORDER BY revenue DESC
LIMIT 10;

-- Revenue by region

SELECT 
    c.region,
    SUM(f.amount) AS revenue
FROM fact_transactions f
JOIN dim_customer c ON f.customer_id = c.customer_id
WHERE f.status = 'Completed'
GROUP BY c.region
ORDER BY revenue DESC;


-- Revenue by location (City)

SELECT 
    l.city,
    l.state,
    SUM(f.amount) AS revenue
FROM fact_transactions f
JOIN dim_location l ON f.location_id = l.location_id
WHERE f.status = 'Completed'
GROUP BY l.city, l.state
ORDER BY revenue DESC;

-- Quarterly Revenue Trend

SELECT 
    d.year,
    d.quarter,
    SUM(f.amount) AS revenue
FROM fact_transactions f
JOIN dim_date d ON f.date_id = d.date_id
WHERE f.status = 'Completed'
GROUP BY d.year, d.quarter
ORDER BY d.year, d.quarter;

-- Order status distribution

SELECT 
    status,
    COUNT(*) AS total_transactions
FROM fact_transactions
GROUP BY status;

-- Repeat Customers (Month than 1 order)

SELECT 
    customer_id,
    COUNT(DISTINCT transaction_id) AS orders
FROM fact_transactions
WHERE status = 'Completed'
GROUP BY customer_id
HAVING COUNT(DISTINCT transaction_id) > 1;


-- Customer Contribution % (Pareto)

SELECT 
    c.customer_name,
    ROUND(
        SUM(f.amount) * 100.0 / 
        (SELECT SUM(amount) FROM fact_transactions WHERE status = 'Completed'),
        2
    ) AS revenue_pct
FROM fact_transactions f
JOIN dim_customer c ON f.customer_id = c.customer_id
WHERE f.status = 'Completed'
GROUP BY c.customer_name
ORDER BY revenue_pct DESC;

-- Daily Sales Teand 

SELECT 
    d.full_date,
    SUM(f.amount) AS revenue
FROM fact_transactions f
JOIN dim_date d ON f.date_id = d.date_id
WHERE f.status = 'Completed'
GROUP BY d.full_date
ORDER BY d.full_date;


-- ---------------Fixing locations ------------------------

SELECT transaction_id, location_id
FROM enterprise_mis.fact_transactions
WHERE location_id = -1;


SELECT * 
FROM enterprise_mis.dim_location;


INSERT INTO enterprise_mis.dim_location
(location_id, city, state, country, location_type)
VALUES
(1, 'Bangalore', 'Karnataka', 'India', 'Urban'),
(2, 'Delhi', 'Delhi', 'India', 'Urban');

SELECT * FROM enterprise_mis.dim_location;



UPDATE enterprise_mis.fact_transactions
SET location_id = 1
WHERE transaction_id = 1001;

UPDATE enterprise_mis.fact_transactions
SET location_id = 2
WHERE transaction_id = 1005;

SELECT transaction_id, location_id
FROM enterprise_mis.fact_transactions;


DELETE FROM enterprise_mis.dim_location
WHERE location_id = -1;



-- ------------------ADDING Realistic fact_transitions----------------

SELECT DATABASE();
SHOW TABLES;

SELECT date_id, full_date
FROM dim_date
ORDER BY full_date
LIMIT 20;

SELECT location_id, city, state FROM dim_location;
SELECT product_id, product_name, standard_cost FROM dim_product;
SELECT customer_id, customer_name, customer_type FROM dim_customer;
SELECT date_id, full_date FROM dim_date LIMIT 10;

SELECT location_id, city, state FROM dim_location;

SELECT product_id, product_name, standard_cost FROM dim_product;
SELECT customer_id, customer_name, customer_type FROM dim_customer;

SELECT product_id, product_name, standard_cost FROM dim_product;


INSERT INTO fact_transactions
(transaction_id, date_id, transaction_type, product_id, customer_id, location_id, quantity, amount, status, created_at)
VALUES
-- 2021 (enterprise-heavy launch)
(3001, 20211001, 'SALE', 53, 1, 1, 10, 500000, 'Completed', '2021-10-01'),
(3002, 20211015, 'SALE', 56, 1, 1, 5, 60000,  'Completed', '2021-10-15'),

-- 2022 (growth year)
(3003, 20220410, 'SALE', 53, 1, 1, 8, 400000, 'Completed', '2022-04-10'),
(3004, 20220512, 'SALE', 54, 1, 1, 3, 180000, 'Completed', '2022-05-12'),
(3005, 20220705, 'SALE', 55, 2, 2, 2, 90000,  'Completed', '2022-07-05'),

-- 2023 (retail expansion)
(3006, 20230120, 'SALE', 53, 2, 2, 3, 135000, 'Completed', '2023-01-20'),
(3007, 20230218, 'SALE', 56, 2, 2, 2, 24000,  'Completed', '2023-02-18'),
(3008, 20230310, 'SALE', 55, 2, 2, 4, 180000, 'Completed', '2023-03-10'),

-- realistic noise
(3009, 20230401, 'SALE', 53, 2, 1, 2, 90000,  'Cancelled', '2023-04-01');


SELECT customer_id, customer_name FROM dim_customer;
SELECT date_id, full_date FROM dim_date ORDER BY full_date;


INSERT INTO dim_date (date_id, full_date, day, month, month_name, quarter, year)
VALUES
(20211015, '2021-10-15', 15, 10, 'October', 4, 2021),
(20220410, '2022-04-10', 10, 4, 'April',   2, 2022),
(20220512, '2022-05-12', 12, 5, 'May',     2, 2022),
(20220705, '2022-07-05', 5,  7, 'July',    3, 2022),
(20230120, '2023-01-20', 20, 1, 'January', 1, 2023),
(20230218, '2023-02-18', 18, 2, 'February',1, 2023),
(20230310, '2023-03-10', 10, 3, 'March',   1, 2023),
(20230401, '2023-04-01', 1,  4, 'April',   2, 2023);

SELECT date_id, full_date FROM dim_date ORDER BY full_date;


INSERT INTO fact_transactions
(transaction_id, date_id, transaction_type, product_id, customer_id, location_id, quantity, amount, status, created_at)
VALUES
-- 2021 enterprise launch
(3001, 20211001, 'SALE', 53, 1, 1, 10, 500000, 'Completed', '2021-10-01'),
(3002, 20211015, 'SALE', 56, 1, 1, 5,   60000, 'Completed', '2021-10-15'),

-- 2022 growth year
(3003, 20220410, 'SALE', 53, 1, 1, 8,  400000, 'Completed', '2022-04-10'),
(3004, 20220512, 'SALE', 54, 1, 1, 3,  180000, 'Completed', '2022-05-12'),
(3005, 20220705, 'SALE', 55, 2, 2, 2,   90000, 'Completed', '2022-07-05'),

-- 2023 retail expansion
(3006, 20230120, 'SALE', 53, 2, 2, 3,  135000, 'Completed', '2023-01-20'),
(3007, 20230218, 'SALE', 56, 2, 2, 2,   24000, 'Completed', '2023-02-18'),
(3008, 20230310, 'SALE', 55, 2, 2, 4,  180000, 'Completed', '2023-03-10'),

-- noise / cancelled
(3009, 20230401, 'SALE', 53, 2, 1, 2,   90000, 'Cancelled', '2023-04-01');


SELECT COUNT(*) FROM fact_transactions;
SELECT year, SUM(amount) FROM fact_transactions f
JOIN dim_date d ON f.date_id = d.date_id
WHERE status = 'Completed'
GROUP BY year;


SELECT 
    f.transaction_id,
    f.date_id,
    f.amount
FROM fact_transactions f
JOIN dim_date d 
    ON f.date_id = d.date_id
WHERE d.year = 2023
  AND f.status = 'Completed';

SELECT COUNT(DISTINCT customer_id)
FROM fact_transactions;

SELECT DISTINCT l.state
FROM fact_transactions f
JOIN dim_location l ON f.location_id = l.location_id;

SELECT DISTINCT f.location_id
FROM fact_transactions f
LEFT JOIN dim_location l
ON f.location_id = l.location_id
WHERE l.location_id IS NULL;



-- Bulk generate customers

INSERT INTO dim_customer (customer_id, customer_name, customer_type)
SELECT
    1000 + seq,
    CONCAT('Customer_', 1000 + seq),
    CASE WHEN seq % 3 = 0 THEN 'Enterprise' ELSE 'Retail' END
FROM (
    SELECT @row := @row + 1 AS seq
    FROM information_schema.columns, (SELECT @row := 0) r
    LIMIT 500
) t;

SELECT MAX(customer_id) FROM dim_customer;

INSERT INTO dim_customer (customer_id, customer_name, customer_type)
SELECT
    @max_id + seq,
    CONCAT('Customer_', @max_id + seq),
    CASE WHEN seq % 3 = 0 THEN 'Enterprise' ELSE 'Retail' END
FROM (
    SELECT @row := @row + 1 AS seq
    FROM information_schema.columns, (SELECT @row := 0) r
    LIMIT 500
) t
CROSS JOIN (SELECT @max_id := (SELECT MAX(customer_id) FROM dim_customer)) m;


SELECT COUNT(*) FROM dim_customer;
SELECT COUNT(DISTINCT customer_id) FROM dim_customer;

SELECT COUNT(DISTINCT customer_id)
FROM fact_transactions;
-- 17


-- Check Current MAX IDs 

SELECT MAX(transaction_id) FROM fact_transactions;
SELECT MIN(date_id), MAX(date_id) FROM dim_date;
SELECT MIN(customer_id), MAX(customer_id) FROM dim_customer;
SELECT MIN(product_id), MAX(product_id) FROM dim_product;
SELECT MIN(location_id), MAX(location_id) FROM dim_location;

-- SQL 100,000) rows

INSERT INTO fact_transactions
(
    transaction_id,
    date_id,
    transaction_type,
    product_id,
    customer_id,
    location_id,
    quantity,
    amount,
    status,
    created_at
)
SELECT
    @tx := @tx + 1 AS transaction_id,

    -- random valid date
    d.date_id,

    'SALE' AS transaction_type,

    -- random product
    p.product_id,

    -- random customer
    c.customer_id,

    -- random location
    l.location_id,

    -- realistic quantity
    FLOOR(1 + RAND() * 5) AS quantity,

    -- price * quantity
    ROUND(p.standard_cost * (1 + RAND() * 0.3) * FLOOR(1 + RAND() * 5), 2) AS amount,

    -- mostly completed
    CASE WHEN RAND() < 0.9 THEN 'Completed' ELSE 'Cancelled' END AS status,

    NOW() AS created_at

FROM
    (SELECT @tx := (SELECT IFNULL(MAX(transaction_id), 0) FROM fact_transactions)) t

JOIN dim_date d
JOIN dim_product p
JOIN dim_customer c
JOIN dim_location l

-- LIMIT total rows
LIMIT 100000;


SELECT COUNT(*) FROM fact_transactions;
SELECT COUNT(DISTINCT customer_id) FROM fact_transactions;
SELECT COUNT(DISTINCT location_id) FROM fact_transactions;
SELECT COUNT(DISTINCT date_id) FROM fact_transactions;


SELECT location_id, city, state, region
FROM dim_location
WHERE region IS NULL;


DESCRIBE dim_location;
SHOW COLUMNS FROM dim_location;

ALTER TABLE dim_location
ADD COLUMN region VARCHAR(50);

UPDATE dim_location
SET region = CASE
    WHEN state IN ('Karnataka', 'Tamil Nadu', 'Telangana', 'Kerala') THEN 'South'
    WHEN state IN ('Delhi', 'Haryana', 'Punjab', 'Uttar Pradesh') THEN 'North'
    WHEN state IN ('Maharashtra', 'Gujarat') THEN 'West'
    WHEN state IN ('West Bengal', 'Odisha') THEN 'East'
    ELSE 'Other'
END;

SELECT region, COUNT(*) 
FROM dim_location
GROUP BY region;



-- Total customers in fact
SELECT COUNT(DISTINCT customer_id)
FROM fact_transactions;

-- Customers with at least one completed transaction
SELECT COUNT(DISTINCT customer_id)
FROM fact_transactions
WHERE status = 'Completed';



-- CONFORMATION BEFORE GENERATING LARGE DATA --

SELECT COUNT(*) AS orphan_customers
FROM fact_transactions f
LEFT JOIN dim_customer c
  ON f.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT COUNT(*) AS orphan_products
FROM fact_transactions f
LEFT JOIN dim_product p
  ON f.product_id = p.product_id
WHERE p.product_id IS NULL;

SELECT COUNT(*) AS orphan_locations
FROM fact_transactions f
LEFT JOIN dim_location l
  ON f.location_id = l.location_id
WHERE l.location_id IS NULL;

SELECT COUNT(*) AS orphan_dates
FROM fact_transactions f
LEFT JOIN dim_date d
  ON f.date_id = d.date_id
WHERE d.date_id IS NULL;


SELECT transaction_id, COUNT(*)
FROM fact_transactions
GROUP BY transaction_id
HAVING COUNT(*) > 1;

SELECT customer_id, COUNT(*)
FROM dim_customer
GROUP BY customer_id
HAVING COUNT(*) > 1;

SELECT COUNT(*) AS blank_regions
FROM dim_location
WHERE region IS NULL OR TRIM(region) = '';



SELECT l.region, COUNT(*) AS txn_count
FROM fact_transactions f
JOIN dim_location l
  ON f.location_id = l.location_id
GROUP BY l.region;

SELECT COUNT(DISTINCT customer_id) AS total_customers
FROM fact_transactions;

SELECT COUNT(DISTINCT customer_id) AS completed_customers
FROM fact_transactions
WHERE status = 'Completed';

SELECT
  (SELECT COUNT(*) FROM dim_customer) AS customers,
  (SELECT COUNT(*) FROM dim_product)  AS products,
  (SELECT COUNT(*) FROM dim_location) AS locations,
  (SELECT COUNT(*) FROM dim_date)     AS dates;
  
  
  
  SELECT
  MAX(transaction_id) AS max_txn_id,
  COUNT(*) AS total_txns
FROM fact_transactions;

SELECT
  SUM(f.amount) AS fact_revenue,
  SUM(f.quantity * p.standard_cost) AS expected_revenue
FROM fact_transactions f
JOIN dim_product p
  ON f.product_id = p.product_id;


SELECT
  COUNT(DISTINCT customer_id)                            AS all_customers,
  COUNT(DISTINCT CASE WHEN status = 'Completed' THEN customer_id END) AS completed_customers,
  COUNT(DISTINCT CASE 
    WHEN status = 'Completed'
     AND created_at BETWEEN '2021-01-01' AND '2023-09-27'
    THEN customer_id END) AS completed_in_range
FROM fact_transactions;



-- customers available
SELECT COUNT(*) FROM dim_customer;

-- locations available
SELECT location_id, state, region FROM dim_location;

-- products available
SELECT product_id, product_name, standard_cost FROM dim_product;

-- dates available
SELECT MIN(date_id), MAX(date_id) FROM dim_date;





-- make sure safe updates don't block inserts
SET SQL_SAFE_UPDATES = 0;

-- get max existing transaction_id
SET @start_txn :=
(
  SELECT IFNULL(MAX(transaction_id), 0)
  FROM fact_transactions
);

-- insert 100k realistic transactions



SELECT VERSION();

CREATE TABLE IF NOT EXISTS seq_100k (
  n INT PRIMARY KEY
);


INSERT IGNORE INTO seq_100k (n)
SELECT a.n + b.n * 10 + c.n * 100 + d.n * 1000 + 1
FROM
 (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
  UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
 (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
  UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b,
 (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
  UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) c,
 (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
  UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d
LIMIT 100000;

SELECT COUNT(*) FROM seq_100k;



ALTER TABLE fact_transactions
MODIFY transaction_id BIGINT NOT NULL AUTO_INCREMENT;

SHOW CREATE TABLE fact_transactions;

INSERT INTO fact_transactions
(
  date_id,
  transaction_type,
  product_id,
  customer_id,
  location_id,
  quantity,
  amount,
  status,
  created_at
)
SELECT
  d.date_id,
  'SALE',
  p.product_id,
  c.customer_id,
  l.location_id,
  q.qty,
  q.qty * p.standard_cost,
  CASE WHEN MOD(s.n, 10) <> 0 THEN 'Completed' ELSE 'Cancelled' END,
  d.full_date
FROM
  (SELECT n FROM seq_100k ORDER BY n LIMIT 10000 OFFSET 20000) s

JOIN dim_date d
  ON MOD(s.n, 1000) = MOD(d.date_id, 1000)

JOIN dim_product p
  ON MOD(s.n, (SELECT COUNT(*) FROM dim_product)) + 1 = p.product_id

JOIN dim_customer c
  ON MOD(s.n, (SELECT COUNT(*) FROM dim_customer)) + 1 = c.customer_id

JOIN dim_location l
  ON MOD(s.n, (SELECT COUNT(*) FROM dim_location)) + 1 = l.location_id

JOIN (
  SELECT 1 qty UNION ALL
  SELECT 2 UNION ALL
  SELECT 3 UNION ALL
  SELECT 4 UNION ALL
  SELECT 5
) q;



SELECT COUNT(*) FROM fact_transactions;
SELECT COUNT(DISTINCT transaction_id) FROM fact_transactions;



SELECT
  COUNT(DISTINCT customer_id) AS fact_customers,
  COUNT(*) AS total_txns
FROM fact_transactions;



SELECT COUNT(*) FROM dim_customer;
-- suppose = 533


INSERT INTO fact_transactions
(
  date_id,
  transaction_type,
  product_id,
  customer_id,
  location_id,
  quantity,
  amount,
  status,
  created_at
)
SELECT
  d.date_id,
  'SALE',
  p.product_id,
  c.customer_id,
  l.location_id,
  q.qty,
  q.qty * p.standard_cost * (1 + RAND()),
  IF(RAND() < 0.9, 'Completed', 'Cancelled'),
  d.full_date
FROM dim_date d

JOIN dim_product p
JOIN dim_location l

JOIN (
    SELECT
      dc.customer_id,
      ROW_NUMBER() OVER (ORDER BY dc.customer_id) - 1 AS rn
    FROM dim_customer dc
) c
  ON c.rn = MOD(d.date_id, 533)

JOIN (
  SELECT 1 qty UNION ALL
  SELECT 2 UNION ALL
  SELECT 3 UNION ALL
  SELECT 4 UNION ALL
  SELECT 5
) q

WHERE d.date_id BETWEEN 20210101 AND 20231231
LIMIT 200000;

SELECT
  COUNT(DISTINCT customer_id) AS customers,
  COUNT(*) AS txns
FROM fact_transactions;



SELECT
  customer_id,
  COUNT(*) AS txns
FROM fact_transactions
GROUP BY customer_id
ORDER BY txns DESC;


SELECT COUNT(*) FROM dim_customer;


INSERT INTO fact_transactions
(
  date_id,
  transaction_type,
  product_id,
  customer_id,
  location_id,
  quantity,
  amount,
  status,
  created_at
)
SELECT
  d.date_id,
  'SALE',
  p.product_id,
  c.customer_id,
  l.location_id,
  q.qty,
  q.qty * p.standard_cost * (1 + RAND()),
  IF(RAND() < 0.9, 'Completed', 'Cancelled'),
  d.full_date
FROM dim_date d

JOIN (
  SELECT
    customer_id,
    ROW_NUMBER() OVER (ORDER BY customer_id) - 1 AS rn
  FROM dim_customer
) c
  ON c.rn = MOD(d.date_id, 533)

JOIN dim_product p
JOIN dim_location l

JOIN (
  SELECT 1 qty UNION ALL
  SELECT 2 UNION ALL
  SELECT 3 UNION ALL
  SELECT 4 UNION ALL
  SELECT 5
) q

WHERE d.date_id BETWEEN 20210101 AND 20231231
LIMIT 500000;

SELECT
  COUNT(DISTINCT customer_id) AS customers,
  COUNT(*) AS txns
FROM fact_transactions;


CREATE TABLE IF NOT EXISTS seq_1m (
  n INT PRIMARY KEY
);

INSERT IGNORE INTO seq_1m (n)
SELECT a.n + b.n * 10 + c.n * 100 + d.n * 1000
FROM
 (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
  UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a
CROSS JOIN
 (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
  UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
CROSS JOIN
 (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
  UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) c
CROSS JOIN
 (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
  UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d;


INSERT INTO fact_transactions
(
  date_id,
  transaction_type,
  product_id,
  customer_id,
  location_id,
  quantity,
  amount,
  status,
  created_at
)
SELECT
  d.date_id,
  'SALE',
  p.product_id,
  c.customer_id,
  l.location_id,
  q.qty,
  q.qty * p.standard_cost * (1 + RAND()),
  IF(RAND() < 0.9, 'Completed', 'Cancelled'),
  d.full_date
FROM seq_1m s
JOIN dim_date d       ON d.date_id BETWEEN 20210101 AND 20231231
JOIN dim_product p    ON MOD(s.n, (SELECT COUNT(*) FROM dim_product)) = p.product_id % (SELECT COUNT(*) FROM dim_product)
JOIN dim_customer c   ON MOD(s.n, (SELECT COUNT(*) FROM dim_customer)) = c.customer_id % (SELECT COUNT(*) FROM dim_customer)
JOIN dim_location l   ON MOD(s.n, (SELECT COUNT(*) FROM dim_location)) = l.location_id % (SELECT COUNT(*) FROM dim_location)
JOIN (
  SELECT 1 qty UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
) q
LIMIT 500000;


SELECT
  COUNT(DISTINCT customer_id) AS customers,
  COUNT(*) AS txns
FROM fact_transactions;


SELECT
  MIN(customer_id),
  MAX(customer_id),
  COUNT(DISTINCT customer_id)
FROM dim_customer;


SELECT COUNT(*) INTO @cust_cnt FROM dim_customer;
SELECT COUNT(*) INTO @loc_cnt  FROM dim_location;


SET SQL_SAFE_UPDATES = 0;

SELECT COUNT(*) INTO @cust_cnt FROM dim_customer;
SELECT COUNT(*) INTO @loc_cnt  FROM dim_location;
SELECT COUNT(*) INTO @prod_cnt FROM dim_product;
SELECT COUNT(*) INTO @date_cnt FROM dim_date;

SELECT @cust_cnt, @loc_cnt, @prod_cnt, @date_cnt;


DROP TABLE IF EXISTS seq_100k;
CREATE TABLE seq_100k (
  n INT PRIMARY KEY
) ENGINE=InnoDB;


INSERT INTO seq_100k (n)
SELECT a.n + b.n * 10 + c.n * 100 + d.n * 1000 + e.n * 10000
FROM
 (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
  UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a
CROSS JOIN
 (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
  UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
CROSS JOIN
 (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
  UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) c
CROSS JOIN
 (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
  UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d
CROSS JOIN
 (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
  UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) e
LIMIT 100000;


SELECT COUNT(*) FROM seq_100k;



DROP TABLE IF EXISTS dim_customer_rn;
CREATE TABLE dim_customer_rn AS
SELECT
  customer_id,
  ROW_NUMBER() OVER (ORDER BY customer_id) AS rn
FROM dim_customer;


DROP TABLE IF EXISTS dim_product_rn;
CREATE TABLE dim_product_rn AS
SELECT
  product_id,
  standard_cost,
  ROW_NUMBER() OVER (ORDER BY product_id) AS rn
FROM dim_product;


DROP TABLE IF EXISTS dim_location_rn;
CREATE TABLE dim_location_rn AS
SELECT
  location_id,
  ROW_NUMBER() OVER (ORDER BY location_id) AS rn
FROM dim_location;


DROP TABLE IF EXISTS dim_date_rn;
CREATE TABLE dim_date_rn AS
SELECT
  date_id,
  full_date,
  ROW_NUMBER() OVER (ORDER BY date_id) AS rn
FROM dim_date
WHERE date_id BETWEEN 20210101 AND 20231231;


SELECT COUNT(*) FROM dim_customer_rn;
SELECT COUNT(*) FROM dim_product_rn;
SELECT COUNT(*) FROM dim_location_rn;
SELECT COUNT(*) FROM dim_date_rn;


SET SESSION net_read_timeout = 1200;
SET SESSION net_write_timeout = 1200;
SET SESSION wait_timeout = 1200;
SET SESSION interactive_timeout = 1200;


SELECT COUNT(*) INTO @cust_cnt FROM dim_customer_rn;
SELECT COUNT(*) INTO @prod_cnt FROM dim_product_rn;
SELECT COUNT(*) INTO @loc_cnt  FROM dim_location_rn;
SELECT COUNT(*) INTO @date_cnt FROM dim_date_rn;

SELECT @cust_cnt, @prod_cnt, @loc_cnt, @date_cnt;


DROP TABLE IF EXISTS stage_txn;
CREATE TABLE stage_txn (
  date_id INT,
  product_id INT,
  customer_id INT,
  location_id INT,
  qty INT,
  amount DECIMAL(12,2),
  status VARCHAR(20),
  created_at DATE
) ENGINE=InnoDB;


SET SQL_SAFE_UPDATES = 0;
ALTER TABLE seq_100k
ADD COLUMN r1 DOUBLE,
ADD COLUMN r2 DOUBLE;

UPDATE seq_100k
SET
  r1 = RAND(),
  r2 = RAND();


DROP TABLE IF EXISTS stage_txn;
CREATE TABLE stage_txn (
  date_id INT,
  product_id INT,
  customer_id INT,
  location_id INT,
  qty INT,
  amount DECIMAL(12,2),
  status VARCHAR(20),
  created_at DATE
) ENGINE=InnoDB;


SET autocommit = 1;
SET SESSION net_read_timeout = 600;
SET SESSION net_write_timeout = 600;
SET SESSION wait_timeout = 600;

SELECT COUNT(*) FROM seq_100k;


INSERT INTO fact_transactions
(
  date_id,
  transaction_type,
  product_id,
  customer_id,
  location_id,
  quantity,
  amount,
  status,
  created_at
)
SELECT
  d.date_id,
  'SALE',
  p.product_id,
  c.customer_id,
  l.location_id,
  q.qty,
  ROUND(q.qty * p.standard_cost * 1.15, 2),
  'Completed',
  d.full_date
FROM seq_100k s
JOIN dim_customer_rn c ON c.rn = (s.n MOD @cust_cnt) + 1
JOIN dim_product_rn  p ON p.rn = (s.n MOD @prod_cnt) + 1
JOIN dim_location_rn l ON l.rn = (s.n MOD @loc_cnt) + 1
JOIN dim_date_rn     d ON d.rn = (s.n MOD @date_cnt) + 1
JOIN (
  SELECT 1 qty UNION ALL SELECT 2 UNION ALL
  SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
) q
WHERE s.n BETWEEN 1001 AND 1500;

SELECT COUNT(*) FROM fact_transactions;



SELECT
  COUNT(*) AS txns,
  COUNT(DISTINCT customer_id) AS customers
FROM fact_transactions;

SELECT COUNT(*) orphan_customers
FROM fact_transactions f
LEFT JOIN dim_customer c ON f.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT
  SUM(amount) AS total_revenue,
  AVG(amount) AS avg_order_value
FROM fact_transactions;


SELECT
  COUNT(*) AS txns,
  COUNT(DISTINCT customer_id) AS customers,
  COUNT(DISTINCT product_id) AS products,
  COUNT(DISTINCT location_id) AS locations
FROM fact_transactions;


SELECT COUNT(*) 
FROM fact_transactions
WHERE customer_id IS NULL;


DELETE f
FROM fact_transactions f
LEFT JOIN dim_customer c
  ON f.customer_id = c.customer_id
WHERE c.customer_id IS NULL;





