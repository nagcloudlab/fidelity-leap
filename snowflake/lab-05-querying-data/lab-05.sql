-- ============================================================
-- LAB 05: Querying Data
-- ============================================================
-- Objective: Master CTEs, window functions, QUALIFY, FLATTEN,
--            PIVOT/UNPIVOT, SAMPLE, RESULT_SCAN, and MERGE
-- Duration: 45 minutes
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;

-- ============================================================
-- STEP 1: Set up context
-- ============================================================
-- We will use WORKSHOP_DB for custom tables and
-- SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 for realistic query data.

USE DATABASE SNOWFLAKE_SAMPLE_DATA;
USE SCHEMA TPCH_SF1;

-- Quick sanity check: confirm we can read the sample data
SELECT COUNT(*) AS total_orders FROM ORDERS;
SELECT COUNT(*) AS total_customers FROM CUSTOMER;

-- ============================================================
-- STEP 2: Common Table Expressions (CTEs)
-- ============================================================

-- -----------------------------------------------------------
-- 2a. Simple CTE -- Summarize revenue by nation
-- -----------------------------------------------------------
-- CTEs make complex queries readable by breaking them into
-- named building blocks.

WITH nation_revenue AS (
    SELECT
        n.N_NAME        AS nation,
        r.R_NAME        AS region,
        SUM(o.O_TOTALPRICE) AS total_revenue,
        COUNT(*)        AS order_count
    FROM ORDERS o
    JOIN CUSTOMER c ON o.O_CUSTKEY = c.C_CUSTKEY
    JOIN NATION   n ON c.C_NATIONKEY = n.N_NATIONKEY
    JOIN REGION   r ON n.N_REGIONKEY = r.R_REGIONKEY
    GROUP BY n.N_NAME, r.R_NAME
)
SELECT
    nation,
    region,
    total_revenue,
    order_count,
    ROUND(total_revenue / order_count, 2) AS avg_order_value
FROM nation_revenue
ORDER BY total_revenue DESC
LIMIT 10;

-- -----------------------------------------------------------
-- 2b. Chained CTEs -- Region summary built from nation summary
-- -----------------------------------------------------------
-- You can define multiple CTEs separated by commas and have
-- later CTEs reference earlier ones.

WITH nation_revenue AS (
    SELECT
        n.N_NAME            AS nation,
        r.R_NAME            AS region,
        SUM(o.O_TOTALPRICE) AS total_revenue
    FROM ORDERS o
    JOIN CUSTOMER c ON o.O_CUSTKEY  = c.C_CUSTKEY
    JOIN NATION   n ON c.C_NATIONKEY = n.N_NATIONKEY
    JOIN REGION   r ON n.N_REGIONKEY = r.R_REGIONKEY
    GROUP BY n.N_NAME, r.R_NAME
),
region_summary AS (
    SELECT
        region,
        SUM(total_revenue)                       AS region_revenue,
        COUNT(*)                                 AS nation_count,
        ROUND(AVG(total_revenue), 2)             AS avg_nation_revenue
    FROM nation_revenue
    GROUP BY region
)
SELECT *
FROM region_summary
ORDER BY region_revenue DESC;

-- -----------------------------------------------------------
-- 2c. Recursive CTE -- Generate a date sequence
-- -----------------------------------------------------------
-- Recursive CTEs are useful for generating series, traversing
-- hierarchies, and filling calendar gaps.

-- Switch to WORKSHOP_DB for creating objects
USE DATABASE WORKSHOP_DB;
USE SCHEMA PUBLIC;

WITH RECURSIVE date_series AS (
    -- Anchor: start date
    SELECT DATE '2024-01-01' AS cal_date

    UNION ALL

    -- Recursive step: add one day
    SELECT DATEADD(DAY, 1, cal_date)
    FROM date_series
    WHERE cal_date < DATE '2024-01-31'
)
SELECT
    cal_date,
    DAYNAME(cal_date)  AS day_name,
    WEEKISO(cal_date)  AS iso_week
FROM date_series
ORDER BY cal_date;

-- ============================================================
-- STEP 3: Window Functions -- Ranking
-- ============================================================

-- Switch back to sample data for ranking queries
USE DATABASE SNOWFLAKE_SAMPLE_DATA;
USE SCHEMA TPCH_SF1;

-- -----------------------------------------------------------
-- 3a. ROW_NUMBER, RANK, DENSE_RANK
-- -----------------------------------------------------------
-- Rank customers by total spending within each market segment.
-- ROW_NUMBER: unique sequential number (no ties)
-- RANK: same rank for ties, then gap (1,2,2,4)
-- DENSE_RANK: same rank for ties, no gap (1,2,2,3)

WITH customer_spending AS (
    SELECT
        c.C_CUSTKEY,
        c.C_NAME,
        c.C_MKTSEGMENT,
        SUM(o.O_TOTALPRICE) AS total_spent
    FROM CUSTOMER c
    JOIN ORDERS o ON c.C_CUSTKEY = o.O_CUSTKEY
    GROUP BY c.C_CUSTKEY, c.C_NAME, c.C_MKTSEGMENT
)
SELECT
    C_CUSTKEY,
    C_NAME,
    C_MKTSEGMENT,
    total_spent,
    ROW_NUMBER() OVER (PARTITION BY C_MKTSEGMENT ORDER BY total_spent DESC) AS row_num,
    RANK()       OVER (PARTITION BY C_MKTSEGMENT ORDER BY total_spent DESC) AS rnk,
    DENSE_RANK() OVER (PARTITION BY C_MKTSEGMENT ORDER BY total_spent DESC) AS dense_rnk
FROM customer_spending
ORDER BY C_MKTSEGMENT, row_num
LIMIT 30;

-- -----------------------------------------------------------
-- 3b. NTILE -- Divide customers into spending quartiles
-- -----------------------------------------------------------
-- NTILE(4) splits the ordered set into 4 roughly equal buckets.

WITH customer_spending AS (
    SELECT
        c.C_CUSTKEY,
        c.C_NAME,
        SUM(o.O_TOTALPRICE) AS total_spent
    FROM CUSTOMER c
    JOIN ORDERS o ON c.C_CUSTKEY = o.O_CUSTKEY
    GROUP BY c.C_CUSTKEY, c.C_NAME
)
SELECT
    C_CUSTKEY,
    C_NAME,
    total_spent,
    NTILE(4) OVER (ORDER BY total_spent DESC) AS spending_quartile
FROM customer_spending
ORDER BY spending_quartile, total_spent DESC
LIMIT 20;

-- ============================================================
-- STEP 4: Window Functions -- LAG and LEAD
-- ============================================================
-- Compare each order with the customer's previous and next order.

SELECT
    O_CUSTKEY,
    O_ORDERKEY,
    O_ORDERDATE,
    O_TOTALPRICE,

    -- Previous order amount for this customer
    LAG(O_TOTALPRICE, 1)  OVER (PARTITION BY O_CUSTKEY ORDER BY O_ORDERDATE) AS prev_order_amount,

    -- Next order amount for this customer
    LEAD(O_TOTALPRICE, 1) OVER (PARTITION BY O_CUSTKEY ORDER BY O_ORDERDATE) AS next_order_amount,

    -- Change from previous order
    O_TOTALPRICE - LAG(O_TOTALPRICE, 1) OVER (PARTITION BY O_CUSTKEY ORDER BY O_ORDERDATE)
        AS change_from_prev
FROM ORDERS
WHERE O_CUSTKEY IN (1, 2, 3, 4, 5)   -- Limit to a few customers for readability
ORDER BY O_CUSTKEY, O_ORDERDATE;

-- ============================================================
-- STEP 5: Running Totals and Moving Averages
-- ============================================================

-- -----------------------------------------------------------
-- 5a. Monthly revenue with running total
-- -----------------------------------------------------------
-- SUM ... ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
-- accumulates from the first row to the current row.

WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('MONTH', O_ORDERDATE) AS order_month,
        SUM(O_TOTALPRICE)                AS monthly_total
    FROM ORDERS
    WHERE O_ORDERDATE BETWEEN '1995-01-01' AND '1996-12-31'
    GROUP BY order_month
)
SELECT
    order_month,
    monthly_total,

    -- Running (cumulative) total
    SUM(monthly_total) OVER (
        ORDER BY order_month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total,

    -- 3-month moving average
    ROUND(AVG(monthly_total) OVER (
        ORDER BY order_month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_3mo

FROM monthly_revenue
ORDER BY order_month;

-- -----------------------------------------------------------
-- 5b. Cumulative percentage of total revenue
-- -----------------------------------------------------------

WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('MONTH', O_ORDERDATE) AS order_month,
        SUM(O_TOTALPRICE)                AS monthly_total
    FROM ORDERS
    WHERE O_ORDERDATE BETWEEN '1995-01-01' AND '1996-12-31'
    GROUP BY order_month
)
SELECT
    order_month,
    monthly_total,
    SUM(monthly_total) OVER (ORDER BY order_month) AS running_total,
    ROUND(
        100.0 * SUM(monthly_total) OVER (ORDER BY order_month)
              / SUM(monthly_total) OVER (), 2
    ) AS cumulative_pct
FROM monthly_revenue
ORDER BY order_month;

-- ============================================================
-- STEP 6: QUALIFY Clause (Snowflake-specific)
-- ============================================================
-- QUALIFY filters the output of window functions directly,
-- eliminating the need to wrap the query in a subquery.

-- -----------------------------------------------------------
-- 6a. Top customer per market segment -- without QUALIFY
-- -----------------------------------------------------------
-- The traditional approach requires a subquery.

SELECT * FROM (
    SELECT
        c.C_NAME,
        c.C_MKTSEGMENT,
        SUM(o.O_TOTALPRICE) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.C_MKTSEGMENT ORDER BY SUM(o.O_TOTALPRICE) DESC) AS rn
    FROM CUSTOMER c
    JOIN ORDERS o ON c.C_CUSTKEY = o.O_CUSTKEY
    GROUP BY c.C_NAME, c.C_MKTSEGMENT
) sub
WHERE rn = 1
ORDER BY total_spent DESC;

-- -----------------------------------------------------------
-- 6b. Same result using QUALIFY -- much cleaner!
-- -----------------------------------------------------------

SELECT
    c.C_NAME,
    c.C_MKTSEGMENT,
    SUM(o.O_TOTALPRICE) AS total_spent
FROM CUSTOMER c
JOIN ORDERS o ON c.C_CUSTKEY = o.O_CUSTKEY
GROUP BY c.C_NAME, c.C_MKTSEGMENT
QUALIFY ROW_NUMBER() OVER (PARTITION BY c.C_MKTSEGMENT ORDER BY SUM(o.O_TOTALPRICE) DESC) = 1
ORDER BY total_spent DESC;

-- -----------------------------------------------------------
-- 6c. QUALIFY with RANK -- top 3 nations by order count
-- -----------------------------------------------------------

SELECT
    n.N_NAME        AS nation,
    r.R_NAME        AS region,
    COUNT(*)        AS order_count
FROM ORDERS o
JOIN CUSTOMER c ON o.O_CUSTKEY   = c.C_CUSTKEY
JOIN NATION   n ON c.C_NATIONKEY = n.N_NATIONKEY
JOIN REGION   r ON n.N_REGIONKEY = r.R_REGIONKEY
GROUP BY n.N_NAME, r.R_NAME
QUALIFY RANK() OVER (PARTITION BY r.R_NAME ORDER BY COUNT(*) DESC) <= 3
ORDER BY region, order_count DESC;

-- ============================================================
-- STEP 7: FLATTEN for Semi-Structured (JSON/VARIANT) Data
-- ============================================================

-- Switch to WORKSHOP_DB to create tables
USE DATABASE WORKSHOP_DB;
USE SCHEMA PUBLIC;

-- -----------------------------------------------------------
-- 7a. Create a table with VARIANT column and insert JSON
-- -----------------------------------------------------------

CREATE OR REPLACE TABLE customer_profiles (
    id          INT,
    profile     VARIANT
);

INSERT INTO customer_profiles (id, profile)
SELECT 1, PARSE_JSON('{
    "name": "Alice Johnson",
    "email": "alice@example.com",
    "tier": "Gold",
    "preferences": {
        "newsletter": true,
        "language": "en",
        "currency": "USD"
    },
    "tags": ["loyal", "high-value", "early-adopter"]
}');

INSERT INTO customer_profiles (id, profile)
SELECT 2, PARSE_JSON('{
    "name": "Bob Smith",
    "email": "bob@example.com",
    "tier": "Silver",
    "preferences": {
        "newsletter": false,
        "language": "fr",
        "currency": "EUR"
    },
    "tags": ["new", "international"]
}');

INSERT INTO customer_profiles (id, profile)
SELECT 3, PARSE_JSON('{
    "name": "Carla Reyes",
    "email": "carla@example.com",
    "tier": "Platinum",
    "preferences": {
        "newsletter": true,
        "language": "es",
        "currency": "MXN"
    },
    "tags": ["loyal", "high-value", "vip", "early-adopter"]
}');

-- -----------------------------------------------------------
-- 7b. Query JSON fields directly using dot notation
-- -----------------------------------------------------------

SELECT
    id,
    profile:name::STRING               AS customer_name,
    profile:email::STRING              AS email,
    profile:tier::STRING               AS tier,
    profile:preferences.language::STRING AS language,
    profile:preferences.currency::STRING AS currency
FROM customer_profiles;

-- -----------------------------------------------------------
-- 7c. FLATTEN the tags array into individual rows
-- -----------------------------------------------------------
-- FLATTEN converts each element of an array (or key-value pairs
-- of an object) into its own row.

SELECT
    cp.id,
    cp.profile:name::STRING AS customer_name,
    f.INDEX                 AS tag_position,
    f.VALUE::STRING         AS tag
FROM customer_profiles cp,
     TABLE(FLATTEN(input => cp.profile:tags)) f
ORDER BY cp.id, f.INDEX;

-- -----------------------------------------------------------
-- 7d. FLATTEN an object to get key-value pairs
-- -----------------------------------------------------------

SELECT
    cp.id,
    cp.profile:name::STRING AS customer_name,
    f.KEY                   AS preference_key,
    f.VALUE::STRING         AS preference_value
FROM customer_profiles cp,
     TABLE(FLATTEN(input => cp.profile:preferences)) f
ORDER BY cp.id, f.KEY;

-- ============================================================
-- STEP 8: LATERAL FLATTEN for Nested Arrays
-- ============================================================

-- -----------------------------------------------------------
-- 8a. Create a table with nested JSON (orders with line items)
-- -----------------------------------------------------------

CREATE OR REPLACE TABLE orders_json (
    order_id    INT,
    order_data  VARIANT
);

INSERT INTO orders_json
SELECT 1001, PARSE_JSON('{
    "customer": "Alice Johnson",
    "order_date": "2024-03-15",
    "items": [
        {"product": "Laptop",    "quantity": 1, "price": 1299.99},
        {"product": "Mouse",     "quantity": 2, "price": 29.99},
        {"product": "USB Cable", "quantity": 3, "price": 9.99}
    ]
}');

INSERT INTO orders_json
SELECT 1002, PARSE_JSON('{
    "customer": "Bob Smith",
    "order_date": "2024-03-16",
    "items": [
        {"product": "Monitor",  "quantity": 1, "price": 549.00},
        {"product": "Keyboard", "quantity": 1, "price": 89.99}
    ]
}');

INSERT INTO orders_json
SELECT 1003, PARSE_JSON('{
    "customer": "Carla Reyes",
    "order_date": "2024-03-17",
    "items": [
        {"product": "Tablet",     "quantity": 2, "price": 399.99},
        {"product": "Stylus Pen", "quantity": 2, "price": 49.99},
        {"product": "Case",       "quantity": 2, "price": 34.99},
        {"product": "Screen Protector", "quantity": 4, "price": 12.99}
    ]
}');

-- -----------------------------------------------------------
-- 8b. LATERAL FLATTEN to explode line items
-- -----------------------------------------------------------
-- LATERAL lets the FLATTEN function reference columns from
-- the table on its left side in the FROM clause.

SELECT
    oj.order_id,
    oj.order_data:customer::STRING      AS customer,
    oj.order_data:order_date::DATE      AS order_date,
    items.VALUE:product::STRING         AS product,
    items.VALUE:quantity::INT           AS quantity,
    items.VALUE:price::FLOAT            AS unit_price,
    items.VALUE:quantity::INT * items.VALUE:price::FLOAT AS line_total
FROM orders_json oj,
     LATERAL FLATTEN(input => oj.order_data:items) items
ORDER BY oj.order_id, items.INDEX;

-- -----------------------------------------------------------
-- 8c. Aggregate flattened data -- order-level summary
-- -----------------------------------------------------------

SELECT
    oj.order_id,
    oj.order_data:customer::STRING AS customer,
    COUNT(*)                       AS line_item_count,
    SUM(items.VALUE:quantity::INT * items.VALUE:price::FLOAT) AS order_total
FROM orders_json oj,
     LATERAL FLATTEN(input => oj.order_data:items) items
GROUP BY oj.order_id, oj.order_data:customer::STRING
ORDER BY order_total DESC;

-- ============================================================
-- STEP 9: PIVOT and UNPIVOT
-- ============================================================

-- -----------------------------------------------------------
-- 9a. Create source data for pivoting
-- -----------------------------------------------------------

CREATE OR REPLACE TABLE quarterly_sales (
    region      STRING,
    quarter     STRING,
    revenue     NUMBER(12,2)
);

INSERT INTO quarterly_sales VALUES
    ('North', 'Q1', 150000), ('North', 'Q2', 180000),
    ('North', 'Q3', 200000), ('North', 'Q4', 220000),
    ('South', 'Q1', 120000), ('South', 'Q2', 135000),
    ('South', 'Q3', 160000), ('South', 'Q4', 190000),
    ('East',  'Q1', 200000), ('East',  'Q2', 210000),
    ('East',  'Q3', 230000), ('East',  'Q4', 250000),
    ('West',  'Q1', 170000), ('West',  'Q2', 195000),
    ('West',  'Q3', 215000), ('West',  'Q4', 240000);

-- Original row-based view
SELECT * FROM quarterly_sales ORDER BY region, quarter;

-- -----------------------------------------------------------
-- 9b. PIVOT -- Rotate quarters into columns
-- -----------------------------------------------------------
-- Each distinct value in the quarter column becomes its own column.

SELECT *
FROM quarterly_sales
    PIVOT(SUM(revenue) FOR quarter IN ('Q1', 'Q2', 'Q3', 'Q4'))
    AS pivoted (region, q1_revenue, q2_revenue, q3_revenue, q4_revenue)
ORDER BY region;

-- -----------------------------------------------------------
-- 9c. UNPIVOT -- Rotate columns back into rows
-- -----------------------------------------------------------
-- Create a pivoted table first, then unpivot it.

CREATE OR REPLACE TABLE pivoted_sales AS
SELECT *
FROM quarterly_sales
    PIVOT(SUM(revenue) FOR quarter IN ('Q1', 'Q2', 'Q3', 'Q4'))
    AS pivoted (region, q1_revenue, q2_revenue, q3_revenue, q4_revenue);

SELECT *
FROM pivoted_sales
    UNPIVOT(revenue FOR quarter IN (q1_revenue, q2_revenue, q3_revenue, q4_revenue))
ORDER BY region, quarter;

-- ============================================================
-- STEP 10: SAMPLE and TABLESAMPLE
-- ============================================================

USE DATABASE SNOWFLAKE_SAMPLE_DATA;
USE SCHEMA TPCH_SF1;

-- -----------------------------------------------------------
-- 10a. Row-based sampling -- Return ~10% of rows randomly
-- -----------------------------------------------------------
-- SAMPLE uses BERNOULLI (row-level) by default.

SELECT
    O_ORDERKEY,
    O_CUSTKEY,
    O_TOTALPRICE,
    O_ORDERDATE
FROM ORDERS
SAMPLE (10)          -- 10% of rows, randomly selected
LIMIT 20;

-- -----------------------------------------------------------
-- 10b. Block-based sampling (SYSTEM method) -- faster on large tables
-- -----------------------------------------------------------
-- SYSTEM sampling selects random micro-partitions (blocks),
-- which is faster but less granular.

SELECT
    O_ORDERKEY,
    O_CUSTKEY,
    O_TOTALPRICE,
    O_ORDERDATE
FROM ORDERS
SAMPLE SYSTEM (5)    -- ~5% of data blocks
LIMIT 20;

-- -----------------------------------------------------------
-- 10c. Fixed-row sampling -- Return exactly N rows
-- -----------------------------------------------------------

SELECT
    O_ORDERKEY,
    O_CUSTKEY,
    O_TOTALPRICE,
    O_ORDERDATE
FROM ORDERS
SAMPLE (100 ROWS);   -- Exactly 100 random rows

-- -----------------------------------------------------------
-- 10d. Repeatable sampling with a seed
-- -----------------------------------------------------------
-- Use a seed value to get the same sample every time.

SELECT
    O_ORDERKEY,
    O_TOTALPRICE
FROM ORDERS
SAMPLE (50 ROWS) SEED (42);

-- ============================================================
-- STEP 11: RESULT_SCAN
-- ============================================================
-- RESULT_SCAN lets you query the output of a previous statement.
-- This is especially useful with SHOW commands whose output
-- cannot be filtered directly.

-- -----------------------------------------------------------
-- 11a. Run SHOW DATABASES, then query its results
-- -----------------------------------------------------------

SHOW DATABASES;

-- Query the SHOW output as if it were a table
SELECT
    "name"       AS database_name,
    "owner"      AS owner,
    "created_on" AS created
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
WHERE "name" ILIKE '%WORKSHOP%'
ORDER BY "created_on" DESC;

-- -----------------------------------------------------------
-- 11b. Run a query, then query its results
-- -----------------------------------------------------------

-- First, run a summary query
SELECT
    O_ORDERPRIORITY,
    COUNT(*)            AS cnt,
    SUM(O_TOTALPRICE)   AS total_rev
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS
GROUP BY O_ORDERPRIORITY
ORDER BY total_rev DESC;

-- Now query the results of that statement
SELECT *
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
WHERE "CNT" > 300000;

-- ============================================================
-- STEP 12: MERGE Statement (Upsert)
-- ============================================================

USE DATABASE WORKSHOP_DB;
USE SCHEMA PUBLIC;

-- -----------------------------------------------------------
-- 12a. Create a target table (product inventory)
-- -----------------------------------------------------------

CREATE OR REPLACE TABLE product_inventory (
    product_id      INT,
    product_name    STRING,
    quantity        INT,
    unit_price      NUMBER(10,2),
    last_updated    TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

INSERT INTO product_inventory VALUES
    (101, 'Laptop',   50, 1299.99, CURRENT_TIMESTAMP()),
    (102, 'Mouse',   200,   29.99, CURRENT_TIMESTAMP()),
    (103, 'Keyboard', 150,   89.99, CURRENT_TIMESTAMP()),
    (104, 'Monitor',   75,  549.00, CURRENT_TIMESTAMP());

SELECT * FROM product_inventory ORDER BY product_id;

-- -----------------------------------------------------------
-- 12b. Create a staging table (incoming inventory updates)
-- -----------------------------------------------------------

CREATE OR REPLACE TABLE product_inventory_staging (
    product_id      INT,
    product_name    STRING,
    quantity        INT,
    unit_price      NUMBER(10,2)
);

INSERT INTO product_inventory_staging VALUES
    (102, 'Mouse',        250,   24.99),  -- UPDATE: price drop, more stock
    (103, 'Keyboard',     150,   89.99),  -- NO CHANGE: same data
    (104, 'Monitor',       80,  529.00),  -- UPDATE: new price and quantity
    (105, 'USB-C Hub',    100,   49.99),  -- INSERT: new product
    (106, 'Webcam',       120,   79.99);  -- INSERT: new product

-- -----------------------------------------------------------
-- 12c. MERGE -- upsert staging into target
-- -----------------------------------------------------------
-- WHEN MATCHED AND values differ: update the row
-- WHEN NOT MATCHED: insert the new row

MERGE INTO product_inventory AS tgt
USING product_inventory_staging AS src
    ON tgt.product_id = src.product_id
WHEN MATCHED
    AND (tgt.quantity   != src.quantity
      OR tgt.unit_price != src.unit_price)
    THEN UPDATE SET
        tgt.product_name  = src.product_name,
        tgt.quantity      = src.quantity,
        tgt.unit_price    = src.unit_price,
        tgt.last_updated  = CURRENT_TIMESTAMP()
WHEN NOT MATCHED
    THEN INSERT (product_id, product_name, quantity, unit_price, last_updated)
         VALUES (src.product_id, src.product_name, src.quantity, src.unit_price, CURRENT_TIMESTAMP());

-- Verify the merge results
SELECT * FROM product_inventory ORDER BY product_id;

-- You should see:
--   101 Laptop    50  1299.99  (unchanged, not in staging)
--   102 Mouse    250    24.99  (updated)
--   103 Keyboard 150    89.99  (matched but no change, skipped)
--   104 Monitor   80   529.00  (updated)
--   105 USB-C Hub 100   49.99  (inserted)
--   106 Webcam   120    79.99  (inserted)

-- ============================================================
-- STEP 13: Clean Up
-- ============================================================

USE DATABASE WORKSHOP_DB;
USE SCHEMA PUBLIC;

-- Drop tables created during this lab
DROP TABLE IF EXISTS customer_profiles;
DROP TABLE IF EXISTS orders_json;
DROP TABLE IF EXISTS quarterly_sales;
DROP TABLE IF EXISTS pivoted_sales;
DROP TABLE IF EXISTS product_inventory;
DROP TABLE IF EXISTS product_inventory_staging;

-- ============================================================
-- CONGRATULATIONS! You have completed Lab 05!
-- You now know how to use CTEs, window functions, QUALIFY,
-- FLATTEN, PIVOT/UNPIVOT, SAMPLE, RESULT_SCAN, and MERGE.
-- Move on to Lab 06: Roles & Access Control
-- ============================================================
