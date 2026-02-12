/***********************************************************************
 *  LAB 13 -- DYNAMIC TABLES & MATERIALIZED VIEWS
 *  Snowflake Workshop for Beginners
 *
 *  Objective : Learn declarative data pipelines with Dynamic Tables
 *              and query acceleration with Materialized Views.
 *
 *  Duration  : ~30 minutes
 *
 *  NOTE: Run each section in order. Statements are separated by
 *        semicolons so you can execute them one at a time or in blocks.
 ***********************************************************************/


-- =====================================================================
-- STEP 1: SET UP THE ENVIRONMENT
-- =====================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE WORKSHOP_WH;
USE DATABASE WORKSHOP_DB;

-- Create schemas for the medallion layers and analytics.
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS ANALYTICS;


-- =====================================================================
-- =====================================================================
--
--  PART A: DYNAMIC TABLES
--
-- =====================================================================
-- =====================================================================


-- =====================================================================
-- STEP 2: CREATE THE RAW SOURCE TABLE
-- =====================================================================
-- This table simulates IoT sensor readings arriving as raw data.
-- In a real scenario this would be fed by Snowpipe or an external stage.

USE SCHEMA RAW;

CREATE OR REPLACE TABLE RAW.RAW_SENSOR_READINGS (
    reading_id      INT,
    device_id       VARCHAR(20),
    reading_ts      VARCHAR(30),       -- Arrives as a string from the source
    temperature_c   VARCHAR(10),       -- Arrives as a string (may contain errors)
    humidity_pct    VARCHAR(10),       -- Arrives as a string (may contain errors)
    battery_pct     NUMBER(5,2),
    location        VARCHAR(50),
    raw_payload     VARIANT            -- Optional JSON blob for extensibility
);

-- Insert initial raw data (note the messy string types and some bad values).
INSERT INTO RAW.RAW_SENSOR_READINGS
    (reading_id, device_id, reading_ts, temperature_c, humidity_pct, battery_pct, location)
VALUES
    (1,  'SENSOR-001', '2025-06-01 08:00:00', '22.5',  '45.0',  98.50, 'Building-A Floor-1'),
    (2,  'SENSOR-002', '2025-06-01 08:01:00', '23.1',  '47.2',  87.30, 'Building-A Floor-2'),
    (3,  'SENSOR-003', '2025-06-01 08:02:00', '19.8',  '52.1',  92.10, 'Building-B Floor-1'),
    (4,  'SENSOR-001', '2025-06-01 08:05:00', '22.7',  '44.8',  98.40, 'Building-A Floor-1'),
    (5,  'SENSOR-004', '2025-06-01 08:03:00', 'ERR',   '60.0',  15.00, 'Building-B Floor-2'),
    (6,  'SENSOR-002', '2025-06-01 08:06:00', '23.4',  'NULL',  87.00, 'Building-A Floor-2'),
    (7,  'SENSOR-005', '2025-06-01 08:04:00', '21.0',  '50.5',  76.50, 'Building-C Floor-1'),
    (8,  'SENSOR-003', '2025-06-01 08:07:00', '20.1',  '51.8',  91.80, 'Building-B Floor-1'),
    (9,  'SENSOR-001', '2025-06-01 08:10:00', '22.9',  '44.5',  98.30, 'Building-A Floor-1'),
    (10, 'SENSOR-006', '2025-06-01 08:05:00', '25.3',  '38.9',  65.20, 'Building-C Floor-2');

-- Quick look at the raw data.
SELECT * FROM RAW.RAW_SENSOR_READINGS ORDER BY reading_id;


-- =====================================================================
-- STEP 3: CREATE YOUR FIRST DYNAMIC TABLE (BRONZE LAYER)
-- =====================================================================
-- The Bronze layer cleans and types the raw data:
--   - Cast string timestamps to TIMESTAMP
--   - Cast temperature and humidity to NUMBER (NULL if not parseable)
--   - Add an ingestion timestamp
--
-- TARGET_LAG = '1 minute' means this table will never be more than
-- 1 minute behind the source table.

USE SCHEMA ANALYTICS;

CREATE OR REPLACE DYNAMIC TABLE ANALYTICS.DT_SENSOR_BRONZE
    TARGET_LAG = '1 minute'
    WAREHOUSE  = WORKSHOP_WH
AS
SELECT
    reading_id,
    device_id,
    TRY_TO_TIMESTAMP(reading_ts)                    AS reading_ts,
    TRY_TO_NUMBER(temperature_c, 10, 2)             AS temperature_c,
    TRY_TO_NUMBER(humidity_pct, 10, 2)              AS humidity_pct,
    battery_pct,
    location,
    CURRENT_TIMESTAMP()                             AS ingested_at
FROM RAW.RAW_SENSOR_READINGS;

-- Wait a few seconds, then query the Bronze dynamic table.
-- You should see the raw data with proper types and NULLs for bad values.
SELECT * FROM ANALYTICS.DT_SENSOR_BRONZE ORDER BY reading_id;


-- =====================================================================
-- STEP 4: BUILD THE DYNAMIC TABLE CHAIN (SILVER AND GOLD)
-- =====================================================================
-- Silver: Filter out invalid readings, extract building/floor, flag
--         low battery. Only valid temperature readings pass through.
--
-- TARGET_LAG = DOWNSTREAM tells Snowflake: "Only refresh this table
-- when a downstream dynamic table (Gold) needs fresh data."

CREATE OR REPLACE DYNAMIC TABLE ANALYTICS.DT_SENSOR_SILVER
    TARGET_LAG = DOWNSTREAM
    WAREHOUSE  = WORKSHOP_WH
AS
SELECT
    reading_id,
    device_id,
    reading_ts,
    temperature_c,
    humidity_pct,
    battery_pct,
    location,
    -- Extract building and floor from the location string.
    SPLIT_PART(location, ' ', 1)                    AS building,
    SPLIT_PART(location, ' ', 2)                    AS floor,
    -- Flag devices with low battery.
    CASE
        WHEN battery_pct < 20 THEN TRUE
        ELSE FALSE
    END                                             AS low_battery_flag,
    ingested_at
FROM ANALYTICS.DT_SENSOR_BRONZE
WHERE temperature_c IS NOT NULL                    -- Drop rows where temp was unparseable
  AND reading_ts    IS NOT NULL;                   -- Drop rows where timestamp was invalid


-- Gold: Aggregate by device -- compute average temperature, humidity,
-- min battery, and reading count. This is the dashboard-ready layer.
--
-- TARGET_LAG = '1 minute' -- dashboards need data within 1 minute.

CREATE OR REPLACE DYNAMIC TABLE ANALYTICS.DT_SENSOR_GOLD
    TARGET_LAG = '1 minute'
    WAREHOUSE  = WORKSHOP_WH
AS
SELECT
    device_id,
    building,
    floor,
    COUNT(*)                                        AS total_readings,
    ROUND(AVG(temperature_c), 2)                    AS avg_temperature_c,
    ROUND(AVG(humidity_pct), 2)                     AS avg_humidity_pct,
    ROUND(MIN(battery_pct), 2)                      AS min_battery_pct,
    MAX(reading_ts)                                 AS latest_reading_ts,
    MAX(low_battery_flag)                           AS has_low_battery_alert
FROM ANALYTICS.DT_SENSOR_SILVER
GROUP BY device_id, building, floor;

-- Wait a moment for the pipeline to refresh, then query each layer.
-- BRONZE: cleaned and typed (includes rows with NULL temperature).
SELECT '--- BRONZE ---' AS layer;
SELECT * FROM ANALYTICS.DT_SENSOR_BRONZE ORDER BY reading_id;

-- SILVER: valid readings only, with derived columns.
SELECT '--- SILVER ---' AS layer;
SELECT * FROM ANALYTICS.DT_SENSOR_SILVER ORDER BY reading_id;

-- GOLD: aggregated summaries per device.
SELECT '--- GOLD ---' AS layer;
SELECT * FROM ANALYTICS.DT_SENSOR_GOLD ORDER BY device_id;


-- =====================================================================
-- STEP 5: OBSERVE AUTOMATIC REFRESH
-- =====================================================================
-- Insert new data into the RAW source table. The dynamic table chain
-- (Bronze -> Silver -> Gold) will refresh automatically within the
-- target lag period.

INSERT INTO RAW.RAW_SENSOR_READINGS
    (reading_id, device_id, reading_ts, temperature_c, humidity_pct, battery_pct, location)
VALUES
    (11, 'SENSOR-001', '2025-06-01 08:15:00', '23.0',  '44.2',  98.20, 'Building-A Floor-1'),
    (12, 'SENSOR-007', '2025-06-01 08:12:00', '26.1',  '35.0',  55.00, 'Building-D Floor-1'),
    (13, 'SENSOR-004', '2025-06-01 08:14:00', '18.5',  '62.3',  14.00, 'Building-B Floor-2'),
    (14, 'SENSOR-002', '2025-06-01 08:16:00', '23.8',  '46.9',  86.50, 'Building-A Floor-2'),
    (15, 'SENSOR-005', '2025-06-01 08:13:00', '21.3',  '49.8',  76.00, 'Building-C Floor-1');

-- Wait about 60 seconds (the TARGET_LAG), then query the Gold table again.
-- You should see updated aggregates including the new readings.
-- SENSOR-007 should appear as a new device.
-- SENSOR-004 should now show a low battery alert.

SELECT * FROM ANALYTICS.DT_SENSOR_GOLD ORDER BY device_id;

-- Tip: If you do not want to wait, you can manually refresh:
ALTER DYNAMIC TABLE ANALYTICS.DT_SENSOR_BRONZE REFRESH;
-- Then wait a moment for Silver and Gold to cascade.


-- =====================================================================
-- STEP 6: MANAGE DYNAMIC TABLES
-- =====================================================================

-- 6a. Describe the dynamic table to see its definition and properties.
DESCRIBE DYNAMIC TABLE ANALYTICS.DT_SENSOR_BRONZE;

-- 6b. Show all dynamic tables in the schema.
SHOW DYNAMIC TABLES IN SCHEMA ANALYTICS;

-- 6c. Check refresh history -- see when each refresh happened and how long it took.
SELECT *
FROM TABLE(INFORMATION_SCHEMA.DYNAMIC_TABLE_REFRESH_HISTORY(
    NAME => 'WORKSHOP_DB.ANALYTICS.DT_SENSOR_BRONZE'
))
ORDER BY REFRESH_START_TIME DESC
LIMIT 10;

-- 6d. Change the target lag on the Bronze table from 1 minute to 5 minutes.
--     This reduces refresh frequency and lowers compute cost.
ALTER DYNAMIC TABLE ANALYTICS.DT_SENSOR_BRONZE
    SET TARGET_LAG = '5 minutes';

-- 6e. Verify the change.
SHOW DYNAMIC TABLES LIKE 'DT_SENSOR_BRONZE' IN SCHEMA ANALYTICS;

-- 6f. Suspend and resume a dynamic table.
--     Suspending stops automatic refreshes. Resuming re-enables them.
ALTER DYNAMIC TABLE ANALYTICS.DT_SENSOR_BRONZE SUSPEND;
ALTER DYNAMIC TABLE ANALYTICS.DT_SENSOR_BRONZE RESUME;

-- 6g. Reset the target lag back to 1 minute for the rest of the lab.
ALTER DYNAMIC TABLE ANALYTICS.DT_SENSOR_BRONZE
    SET TARGET_LAG = '1 minute';


-- =====================================================================
-- =====================================================================
--
--  PART B: MATERIALIZED VIEWS
--
-- =====================================================================
-- =====================================================================


-- =====================================================================
-- STEP 7: CREATE A BASE TABLE WITH ENOUGH DATA FOR COMPARISON
-- =====================================================================
-- We create a larger table to make the performance difference between
-- a regular view and a materialized view more visible.

USE SCHEMA ANALYTICS;

CREATE OR REPLACE TABLE ANALYTICS.SALES_TRANSACTIONS (
    txn_id          INT AUTOINCREMENT START 1 INCREMENT 1,
    txn_date        DATE,
    store_id        VARCHAR(10),
    product_id      VARCHAR(10),
    category        VARCHAR(30),
    quantity         INT,
    unit_price      DECIMAL(10,2),
    total_amount    DECIMAL(12,2)
);

-- Insert a batch of sample sales data.
-- We use a generator to create a meaningful number of rows.
INSERT INTO ANALYTICS.SALES_TRANSACTIONS
    (txn_date, store_id, product_id, category, quantity, unit_price, total_amount)
SELECT
    DATEADD(day, -UNIFORM(0, 365, RANDOM()), '2025-06-01')      AS txn_date,
    'STORE-' || LPAD(UNIFORM(1, 20, RANDOM())::VARCHAR, 3, '0') AS store_id,
    'PROD-'  || LPAD(UNIFORM(1, 50, RANDOM())::VARCHAR, 4, '0') AS product_id,
    CASE UNIFORM(1, 5, RANDOM())
        WHEN 1 THEN 'Electronics'
        WHEN 2 THEN 'Clothing'
        WHEN 3 THEN 'Groceries'
        WHEN 4 THEN 'Home & Garden'
        WHEN 5 THEN 'Sports'
    END                                                          AS category,
    UNIFORM(1, 20, RANDOM())                                     AS quantity,
    ROUND(UNIFORM(5, 500, RANDOM()) + UNIFORM(0, 99, RANDOM()) / 100.0, 2) AS unit_price,
    quantity * unit_price                                        AS total_amount
FROM TABLE(GENERATOR(ROWCOUNT => 100000));

-- Verify row count.
SELECT COUNT(*) AS total_rows FROM ANALYTICS.SALES_TRANSACTIONS;

-- Preview a few rows.
SELECT * FROM ANALYTICS.SALES_TRANSACTIONS LIMIT 10;


-- =====================================================================
-- STEP 8: CREATE A REGULAR VIEW FOR COMPARISON
-- =====================================================================
-- This view computes a daily sales summary by category. Every time you
-- query it, Snowflake re-scans the full base table and re-computes
-- the aggregation from scratch.

CREATE OR REPLACE VIEW ANALYTICS.V_DAILY_CATEGORY_SALES AS
SELECT
    txn_date,
    category,
    COUNT(*)            AS txn_count,
    SUM(quantity)       AS total_units,
    SUM(total_amount)   AS total_revenue,
    AVG(total_amount)   AS avg_txn_value
FROM ANALYTICS.SALES_TRANSACTIONS
GROUP BY txn_date, category;

-- Query the regular view.
SELECT * FROM ANALYTICS.V_DAILY_CATEGORY_SALES
ORDER BY txn_date DESC, total_revenue DESC
LIMIT 20;

-- Note: Each query re-executes the full aggregation.


-- =====================================================================
-- STEP 9: CREATE A MATERIALIZED VIEW
-- =====================================================================
-- This materialized view contains the same logic but stores the result
-- physically. Queries read from the pre-computed cache instead of
-- re-scanning the base table.
--
-- IMPORTANT: Materialized views can only query a SINGLE base table.
-- No joins, no subqueries referencing other tables, no CTEs with
-- multiple tables.

CREATE OR REPLACE MATERIALIZED VIEW ANALYTICS.MV_DAILY_CATEGORY_SALES AS
SELECT
    txn_date,
    category,
    COUNT(*)            AS txn_count,
    SUM(quantity)       AS total_units,
    SUM(total_amount)   AS total_revenue,
    AVG(total_amount)   AS avg_txn_value
FROM ANALYTICS.SALES_TRANSACTIONS
GROUP BY txn_date, category;

-- Query the materialized view.
SELECT * FROM ANALYTICS.MV_DAILY_CATEGORY_SALES
ORDER BY txn_date DESC, total_revenue DESC
LIMIT 20;

-- The results should be identical to the regular view, but reads are
-- served from the stored result set rather than re-computing every time.


-- =====================================================================
-- STEP 10: COMPARE PERFORMANCE
-- =====================================================================
-- Run both queries and compare the query profiles in the Snowflake UI.
--
-- Regular view: Re-scans and aggregates the full base table.
-- Materialized view: Reads from the pre-computed result.

-- Query the regular view (check the query profile for table scan).
SELECT category, SUM(total_revenue) AS grand_total
FROM ANALYTICS.V_DAILY_CATEGORY_SALES
GROUP BY category
ORDER BY grand_total DESC;

-- Query the materialized view (check the query profile for MV scan).
SELECT category, SUM(total_revenue) AS grand_total
FROM ANALYTICS.MV_DAILY_CATEGORY_SALES
GROUP BY category
ORDER BY grand_total DESC;

-- TIP: Open the Query Profile for each query in the Snowflake UI.
-- The regular view profile will show a full TableScan on SALES_TRANSACTIONS.
-- The materialized view profile will show a scan on the MV itself, which
-- is much smaller and faster.


-- =====================================================================
-- STEP 11: OBSERVE MV AUTO-REFRESH
-- =====================================================================
-- Insert new data into the base table. Snowflake automatically refreshes
-- the materialized view in the background.

INSERT INTO ANALYTICS.SALES_TRANSACTIONS
    (txn_date, store_id, product_id, category, quantity, unit_price, total_amount)
VALUES
    ('2025-06-02', 'STORE-001', 'PROD-0001', 'Electronics',  5, 299.99, 1499.95),
    ('2025-06-02', 'STORE-001', 'PROD-0010', 'Clothing',     3,  49.99,  149.97),
    ('2025-06-02', 'STORE-005', 'PROD-0025', 'Groceries',   10,  12.50,  125.00),
    ('2025-06-02', 'STORE-010', 'PROD-0030', 'Electronics',  2, 499.00,  998.00),
    ('2025-06-02', 'STORE-015', 'PROD-0042', 'Sports',       1, 150.00,  150.00);

-- Query the MV -- the new rows for 2025-06-02 should appear.
-- Snowflake refreshes the MV automatically; you may need to wait a few seconds.
SELECT *
FROM ANALYTICS.MV_DAILY_CATEGORY_SALES
WHERE txn_date = '2025-06-02'
ORDER BY category;


-- =====================================================================
-- STEP 12: EXPLORE MV METADATA
-- =====================================================================

-- 12a. Describe the materialized view to see its columns and types.
DESCRIBE MATERIALIZED VIEW ANALYTICS.MV_DAILY_CATEGORY_SALES;

-- 12b. Show all materialized views in the schema.
SHOW MATERIALIZED VIEWS IN SCHEMA ANALYTICS;

-- 12c. Check the refresh state and details.
--      Look at the "is_invalid", "behind_by" and other columns.
SELECT *
FROM TABLE(INFORMATION_SCHEMA.MATERIALIZED_VIEW_REFRESH_HISTORY(
    VIEW_NAME => 'WORKSHOP_DB.ANALYTICS.MV_DAILY_CATEGORY_SALES'
))
ORDER BY START_TIME DESC
LIMIT 10;


-- =====================================================================
-- STEP 13: UNDERSTAND MV LIMITATIONS
-- =====================================================================
-- Materialized Views have strict restrictions. This step demonstrates
-- the most important one: NO JOINS.

-- 13a. Attempt to create an MV with a JOIN -- this WILL FAIL.
--      Uncomment the block below to see the error.

-- CREATE OR REPLACE MATERIALIZED VIEW ANALYTICS.MV_WITH_JOIN AS
-- SELECT
--     s.txn_id,
--     s.txn_date,
--     s.total_amount,
--     r.reading_id
-- FROM ANALYTICS.SALES_TRANSACTIONS s
-- JOIN RAW.RAW_SENSOR_READINGS r ON s.txn_id = r.reading_id;
--
-- ERROR: Materialized views can only be created on a single base table.

-- 13b. Other MV limitations to be aware of:
--   - No UNION, INTERSECT, EXCEPT
--   - No nested subqueries referencing other tables
--   - No window functions (in some Snowflake editions)
--   - No non-deterministic functions like CURRENT_TIMESTAMP()
--   - The base table must not be a view or dynamic table

-- 13c. For queries that need JOINs, use a Dynamic Table instead:
--      (This is just for illustration; we will not create it.)
--
-- CREATE DYNAMIC TABLE my_joined_result
--     TARGET_LAG = '5 minutes'
--     WAREHOUSE  = WORKSHOP_WH
-- AS
-- SELECT s.*, r.temperature_c
-- FROM sales_transactions s
-- JOIN sensor_bronze r ON s.txn_id = r.reading_id;


-- =====================================================================
-- =====================================================================
--
--  PART C: COMPARISON -- WHEN TO USE WHICH
--
-- =====================================================================
-- =====================================================================

-- This section is a reference summary. No SQL to execute.
--
-- +----------------------------+------------------+---------------------+------------------+
-- | Criteria                   | Dynamic Table    | Materialized View   | Streams + Tasks  |
-- +----------------------------+------------------+---------------------+------------------+
-- | Joins supported            | Yes              | No (single table)   | Yes              |
-- | Chaining / pipelines       | Yes (DT chain)   | No                  | Yes (task DAGs)  |
-- | Refresh control            | TARGET_LAG       | Automatic           | SCHEDULE / CRON  |
-- | Query rewrite by optimizer | No               | Yes                 | No               |
-- | Best for                   | ETL pipelines    | Query acceleration  | Complex CDC      |
-- | Code complexity            | Low (declarative)| Low (declarative)   | Medium-High      |
-- | Procedural logic           | No               | No                  | Yes              |
-- +----------------------------+------------------+---------------------+------------------+
--
-- DECISION GUIDE:
--   1. "I need to transform data through multiple steps with joins."
--       --> Use Dynamic Tables.
--
--   2. "I need to speed up a slow aggregation on one big table."
--       --> Use a Materialized View.
--
--   3. "I need complex merge/upsert logic or arbitrary stored procedures."
--       --> Use Streams + Tasks (Lab 09).
--
--   4. "I need a simple view that always shows current data and I do not
--       care about performance."
--       --> Use a regular View.


-- =====================================================================
-- STEP 14: CLEANUP
-- =====================================================================
-- Drop all objects created in this lab. Run this section when you are
-- finished.

USE ROLE SYSADMIN;

-- 14a. Drop dynamic tables (drop in reverse dependency order: gold first).
DROP DYNAMIC TABLE IF EXISTS WORKSHOP_DB.ANALYTICS.DT_SENSOR_GOLD;
DROP DYNAMIC TABLE IF EXISTS WORKSHOP_DB.ANALYTICS.DT_SENSOR_SILVER;
DROP DYNAMIC TABLE IF EXISTS WORKSHOP_DB.ANALYTICS.DT_SENSOR_BRONZE;

-- 14b. Drop materialized views.
DROP MATERIALIZED VIEW IF EXISTS WORKSHOP_DB.ANALYTICS.MV_DAILY_CATEGORY_SALES;

-- 14c. Drop regular views.
DROP VIEW IF EXISTS WORKSHOP_DB.ANALYTICS.V_DAILY_CATEGORY_SALES;

-- 14d. Drop tables.
DROP TABLE IF EXISTS WORKSHOP_DB.ANALYTICS.SALES_TRANSACTIONS;
DROP TABLE IF EXISTS WORKSHOP_DB.RAW.RAW_SENSOR_READINGS;

-- 14e. Verify cleanup.
SHOW DYNAMIC TABLES IN SCHEMA WORKSHOP_DB.ANALYTICS;     -- Should return 0 rows.
SHOW MATERIALIZED VIEWS IN SCHEMA WORKSHOP_DB.ANALYTICS;  -- Should return 0 rows.


/***********************************************************************
 *  END OF LAB 13
 *
 *  Key takeaways:
 *    - Dynamic Tables let you build declarative data pipelines
 *      (Bronze -> Silver -> Gold) without writing Streams or Tasks.
 *    - TARGET_LAG controls how fresh the data must be; shorter lag
 *      means higher compute cost.
 *    - Materialized Views pre-compute and cache query results for
 *      fast reads on a single base table.
 *    - MVs auto-refresh and support transparent query rewrite.
 *    - MVs cannot contain JOINs -- use Dynamic Tables for that.
 *    - Choose Dynamic Tables for pipelines, MVs for query speed,
 *      and Streams + Tasks for procedural/CDC logic.
 *
 *  Next: Lab 14 -- Performance Tuning
 ***********************************************************************/
