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

-- Basic Validation Queries (SHOW YOU TEST DATA)

SHOW TABLES;

DESCRIBE fact_transactions;

SELECT COUNT(*)
FROM fact_transactions
WHERE product_id NOT IN (SELECT product_id FROM dim_product);

SELECT COUNT(*) FROM fact_transactions;
SELECT COUNT(*) FROM dim_product;

SELECT COUNT(*) fROM fact_transactions
where customer_id NOT IN (SELECT customer_id FROM dim_customer);
















