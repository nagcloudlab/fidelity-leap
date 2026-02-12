-- ============================================================
-- LAB 08: Zero-Copy Cloning
-- ============================================================
-- Objective: Learn how to use zero-copy cloning to instantly
--            create copies of tables, schemas, and databases
--            without duplicating storage
-- Duration: 25 minutes
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE WORKSHOP_DB;
USE SCHEMA PUBLIC;

-- ============================================================
-- STEP 1: Set up sample data for cloning exercises
-- ============================================================

-- Create a source table with sample product data
CREATE OR REPLACE TABLE PRODUCTS (
    PRODUCT_ID      INT,
    PRODUCT_NAME    VARCHAR(100),
    CATEGORY        VARCHAR(50),
    PRICE           DECIMAL(10,2),
    STOCK_QUANTITY  INT,
    CREATED_AT      TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- Insert sample data
INSERT INTO PRODUCTS (PRODUCT_ID, PRODUCT_NAME, CATEGORY, PRICE, STOCK_QUANTITY)
VALUES
    (1, 'Laptop Pro 15',     'Electronics', 1299.99, 150),
    (2, 'Wireless Mouse',    'Electronics',   29.99, 500),
    (3, 'Standing Desk',     'Furniture',    449.00,  75),
    (4, 'Ergonomic Chair',   'Furniture',    389.00, 120),
    (5, 'USB-C Hub',         'Electronics',   59.99, 300),
    (6, 'Monitor 27 inch',   'Electronics',  399.99, 200),
    (7, 'Keyboard Mech',     'Electronics',   89.99, 400),
    (8, 'Desk Lamp LED',     'Furniture',     34.99, 250),
    (9, 'Webcam HD',         'Electronics',   74.99, 180),
   (10, 'Cable Management',  'Accessories',   19.99, 600);

-- Verify the source data
SELECT * FROM PRODUCTS ORDER BY PRODUCT_ID;
-- Expected: 10 rows

SELECT COUNT(*) AS total_products, SUM(PRICE) AS total_price_sum
FROM PRODUCTS;

-- ============================================================
-- STEP 2: Clone a table
-- ============================================================
-- Zero-copy cloning creates an instant copy by duplicating
-- only metadata (pointers to micro-partitions). No data is
-- physically copied. This is nearly instantaneous even for
-- tables with terabytes of data.

-- Clone the PRODUCTS table
CREATE OR REPLACE TABLE PRODUCTS_CLONE CLONE PRODUCTS;

-- Verify the clone has the exact same data
SELECT * FROM PRODUCTS_CLONE ORDER BY PRODUCT_ID;
-- Expected: Same 10 rows as the original

-- Compare row counts to confirm they match
SELECT
    'ORIGINAL' AS source, COUNT(*) AS row_count, SUM(PRICE) AS price_sum
FROM PRODUCTS
UNION ALL
SELECT
    'CLONE' AS source, COUNT(*) AS row_count, SUM(PRICE) AS price_sum
FROM PRODUCTS_CLONE;
-- Expected: Both rows show identical counts and sums

-- ============================================================
-- STEP 3: Modify the clone and prove independence
-- ============================================================
-- Changes to the clone do NOT affect the original. This is
-- the "copy-on-write" model -- new micro-partitions are
-- created only for the modified data in the clone.

-- Insert a new row into the CLONE only
INSERT INTO PRODUCTS_CLONE (PRODUCT_ID, PRODUCT_NAME, CATEGORY, PRICE, STOCK_QUANTITY)
VALUES (11, 'Noise-Canceling Headphones', 'Electronics', 249.99, 90);

-- Update a price in the CLONE only
UPDATE PRODUCTS_CLONE
SET PRICE = 999.99
WHERE PRODUCT_ID = 1;

-- Delete a row from the CLONE only
DELETE FROM PRODUCTS_CLONE
WHERE PRODUCT_ID = 10;

-- Now compare: the original should be UNCHANGED
SELECT 'ORIGINAL' AS source, COUNT(*) AS row_count FROM PRODUCTS
UNION ALL
SELECT 'CLONE' AS source, COUNT(*) AS row_count FROM PRODUCTS_CLONE;
-- Expected: ORIGINAL = 10 rows, CLONE = 10 rows (added 1, deleted 1)

-- Check the specific rows that changed
-- Original still has PRODUCT_ID=1 at $1299.99
SELECT PRODUCT_ID, PRODUCT_NAME, PRICE
FROM PRODUCTS
WHERE PRODUCT_ID = 1;
-- Expected: 1299.99

-- Clone has PRODUCT_ID=1 at $999.99
SELECT PRODUCT_ID, PRODUCT_NAME, PRICE
FROM PRODUCTS_CLONE
WHERE PRODUCT_ID = 1;
-- Expected: 999.99

-- Original still has PRODUCT_ID=10
SELECT COUNT(*) AS has_product_10
FROM PRODUCTS
WHERE PRODUCT_ID = 10;
-- Expected: 1

-- Clone does NOT have PRODUCT_ID=10
SELECT COUNT(*) AS has_product_10
FROM PRODUCTS_CLONE
WHERE PRODUCT_ID = 10;
-- Expected: 0

-- Clone has PRODUCT_ID=11 (the new headphones)
SELECT COUNT(*) AS has_product_11
FROM PRODUCTS_CLONE
WHERE PRODUCT_ID = 11;
-- Expected: 1

-- Original does NOT have PRODUCT_ID=11
SELECT COUNT(*) AS has_product_11
FROM PRODUCTS
WHERE PRODUCT_ID = 11;
-- Expected: 0

-- ============================================================
-- STEP 4: Check storage to demonstrate zero-copy behavior
-- ============================================================
-- Immediately after cloning, both objects share the same
-- micro-partitions, so the clone uses no additional storage.
-- After modifications, only the changed partitions are new.

-- View table-level storage information
SELECT
    TABLE_NAME,
    ROW_COUNT,
    BYTES,
    ROUND(BYTES / 1024, 2) AS SIZE_KB
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'PUBLIC'
  AND TABLE_NAME IN ('PRODUCTS', 'PRODUCTS_CLONE')
ORDER BY TABLE_NAME;

-- NOTE: For small tables the storage difference may appear
-- minimal. In production with large tables (millions of rows),
-- the storage savings from zero-copy cloning are dramatic --
-- a clone of a 10 TB table initially uses 0 TB extra storage.

-- For account-level storage details (requires ACCOUNTADMIN)
-- you can query TABLE_STORAGE_METRICS:
-- USE ROLE ACCOUNTADMIN;
-- SELECT
--     TABLE_NAME,
--     ACTIVE_BYTES,
--     RETAINED_FOR_CLONE_BYTES
-- FROM SNOWFLAKE.ACCOUNT_USAGE.TABLE_STORAGE_METRICS
-- WHERE TABLE_CATALOG = 'WORKSHOP_DB'
--   AND TABLE_SCHEMA = 'PUBLIC'
--   AND TABLE_NAME IN ('PRODUCTS', 'PRODUCTS_CLONE')
-- ORDER BY TABLE_NAME;

-- ============================================================
-- STEP 5: Clone an entire schema
-- ============================================================
-- Cloning a schema copies ALL objects within it: tables,
-- views, sequences, file formats, stages (internal), etc.

USE ROLE SYSADMIN;

-- First, let's create a schema with a few objects to clone
CREATE OR REPLACE SCHEMA WORKSHOP_DB.SALES_DATA;

CREATE OR REPLACE TABLE WORKSHOP_DB.SALES_DATA.CUSTOMERS (
    CUSTOMER_ID   INT,
    CUSTOMER_NAME VARCHAR(100),
    EMAIL         VARCHAR(200),
    REGION        VARCHAR(50)
);

INSERT INTO WORKSHOP_DB.SALES_DATA.CUSTOMERS VALUES
    (1, 'Acme Corp',       'contact@acme.com',    'North America'),
    (2, 'Global Imports',  'info@globalimports.com', 'Europe'),
    (3, 'Tech Solutions',  'hello@techsol.com',   'Asia Pacific');

CREATE OR REPLACE TABLE WORKSHOP_DB.SALES_DATA.ORDERS (
    ORDER_ID    INT,
    CUSTOMER_ID INT,
    ORDER_DATE  DATE,
    AMOUNT      DECIMAL(10,2)
);

INSERT INTO WORKSHOP_DB.SALES_DATA.ORDERS VALUES
    (101, 1, '2025-01-15', 5000.00),
    (102, 2, '2025-01-20', 3200.00),
    (103, 1, '2025-02-01', 7500.00),
    (104, 3, '2025-02-10', 4100.00);

CREATE OR REPLACE VIEW WORKSHOP_DB.SALES_DATA.CUSTOMER_ORDER_SUMMARY AS
SELECT
    c.CUSTOMER_NAME,
    c.REGION,
    COUNT(o.ORDER_ID) AS TOTAL_ORDERS,
    SUM(o.AMOUNT) AS TOTAL_REVENUE
FROM WORKSHOP_DB.SALES_DATA.CUSTOMERS c
JOIN WORKSHOP_DB.SALES_DATA.ORDERS o ON c.CUSTOMER_ID = o.CUSTOMER_ID
GROUP BY c.CUSTOMER_NAME, c.REGION;

-- Now clone the entire schema in one command
CREATE OR REPLACE SCHEMA WORKSHOP_DB.SALES_DATA_CLONE CLONE WORKSHOP_DB.SALES_DATA;

-- Verify: the cloned schema has all the same objects
SHOW TABLES IN SCHEMA WORKSHOP_DB.SALES_DATA_CLONE;
SHOW VIEWS IN SCHEMA WORKSHOP_DB.SALES_DATA_CLONE;

-- Verify: data is present in the cloned tables
SELECT * FROM WORKSHOP_DB.SALES_DATA_CLONE.CUSTOMERS;
SELECT * FROM WORKSHOP_DB.SALES_DATA_CLONE.ORDERS;

-- The view works in the cloned schema too
SELECT * FROM WORKSHOP_DB.SALES_DATA_CLONE.CUSTOMER_ORDER_SUMMARY;

-- ============================================================
-- STEP 6: Clone an entire database
-- ============================================================
-- Cloning a database copies ALL schemas and ALL objects within
-- them. This is the fastest way to create a full environment
-- copy for dev or testing.

CREATE OR REPLACE DATABASE WORKSHOP_DB_CLONE CLONE WORKSHOP_DB;

-- Verify: all schemas were cloned
SHOW SCHEMAS IN DATABASE WORKSHOP_DB_CLONE;

-- Verify: tables exist in the cloned database
SHOW TABLES IN SCHEMA WORKSHOP_DB_CLONE.PUBLIC;
SHOW TABLES IN SCHEMA WORKSHOP_DB_CLONE.SALES_DATA;

-- Confirm data integrity
SELECT COUNT(*) AS product_count FROM WORKSHOP_DB_CLONE.PUBLIC.PRODUCTS;
SELECT COUNT(*) AS customer_count FROM WORKSHOP_DB_CLONE.SALES_DATA.CUSTOMERS;
SELECT COUNT(*) AS order_count FROM WORKSHOP_DB_CLONE.SALES_DATA.ORDERS;

-- ============================================================
-- STEP 7: Clone with Time Travel
-- ============================================================
-- You can clone a table as it existed at a specific point in
-- the past by combining CLONE with the AT or BEFORE clause.
-- This is extremely powerful for recovering from mistakes.

USE DATABASE WORKSHOP_DB;
USE SCHEMA PUBLIC;

-- Record the current state
SELECT COUNT(*) AS before_count FROM PRODUCTS;
-- Expected: 10 rows

-- Simulate a mistake: accidentally delete important data!
DELETE FROM PRODUCTS WHERE CATEGORY = 'Electronics';

-- Oh no! How many rows remain?
SELECT COUNT(*) AS after_delete_count FROM PRODUCTS;
-- Expected: Only 4 rows (the non-Electronics items)

-- Use Time Travel cloning to recover the table from 1 minute ago
-- (The OFFSET is in seconds; negative means "X seconds ago")
CREATE OR REPLACE TABLE PRODUCTS_RECOVERED
    CLONE PRODUCTS AT(OFFSET => -60);

-- Check the recovered table -- it should have all 10 rows!
SELECT COUNT(*) AS recovered_count FROM PRODUCTS_RECOVERED;
-- Expected: 10 rows (the full dataset before the delete)

SELECT * FROM PRODUCTS_RECOVERED ORDER BY PRODUCT_ID;

-- Restore the original table from the recovered clone
CREATE OR REPLACE TABLE PRODUCTS CLONE PRODUCTS_RECOVERED;

-- Verify the restoration
SELECT COUNT(*) AS restored_count FROM PRODUCTS;
-- Expected: 10 rows

-- You can also clone from a specific timestamp:
-- CREATE TABLE MY_TABLE_CLONE
--     CLONE MY_TABLE AT(TIMESTAMP => '2025-01-15 10:30:00'::TIMESTAMP);

-- Or before a specific query ID:
-- CREATE TABLE MY_TABLE_CLONE
--     CLONE MY_TABLE BEFORE(STATEMENT => '<query_id>');

-- ============================================================
-- STEP 8: Cloning with COPY GRANTS
-- ============================================================
-- By default, cloning does NOT copy access privileges.
-- Use COPY GRANTS to preserve them on the cloned object.

USE ROLE SECURITYADMIN;

-- Grant SELECT on the original table to a role
GRANT SELECT ON TABLE WORKSHOP_DB.PUBLIC.PRODUCTS TO ROLE PUBLIC;

-- Verify the grant exists on the original
SHOW GRANTS ON TABLE WORKSHOP_DB.PUBLIC.PRODUCTS;

USE ROLE SYSADMIN;

-- Clone WITHOUT copy grants (default behavior)
CREATE OR REPLACE TABLE WORKSHOP_DB.PUBLIC.PRODUCTS_NO_GRANTS
    CLONE WORKSHOP_DB.PUBLIC.PRODUCTS;

-- Clone WITH copy grants
CREATE OR REPLACE TABLE WORKSHOP_DB.PUBLIC.PRODUCTS_WITH_GRANTS
    COPY GRANTS
    CLONE WORKSHOP_DB.PUBLIC.PRODUCTS;

-- Compare grants on each table
SHOW GRANTS ON TABLE WORKSHOP_DB.PUBLIC.PRODUCTS_NO_GRANTS;
-- Expected: Only ownership grant (no SELECT for PUBLIC)

SHOW GRANTS ON TABLE WORKSHOP_DB.PUBLIC.PRODUCTS_WITH_GRANTS;
-- Expected: Includes SELECT grant to PUBLIC role (copied from original)

-- COPY GRANTS also works with schemas and databases:
-- CREATE SCHEMA MY_SCHEMA_CLONE CLONE MY_SCHEMA COPY GRANTS;
-- CREATE DATABASE MY_DB_CLONE CLONE MY_DB COPY GRANTS;

-- ============================================================
-- STEP 9: Practical scenario -- dev copy of production
-- ============================================================
-- Scenario: Your team needs a safe development environment
-- to test a new pricing algorithm. You need an exact copy of
-- production data without affecting the live system.

-- Simulate a "production" schema with realistic data
CREATE OR REPLACE SCHEMA WORKSHOP_DB.PROD_ECOMMERCE;

CREATE OR REPLACE TABLE WORKSHOP_DB.PROD_ECOMMERCE.PRODUCTS (
    PRODUCT_ID      INT AUTOINCREMENT,
    PRODUCT_NAME    VARCHAR(200),
    CATEGORY        VARCHAR(50),
    CURRENT_PRICE   DECIMAL(10,2),
    COST            DECIMAL(10,2),
    MARGIN_PCT      DECIMAL(5,2),
    IS_ACTIVE       BOOLEAN DEFAULT TRUE,
    LAST_UPDATED    TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

INSERT INTO WORKSHOP_DB.PROD_ECOMMERCE.PRODUCTS
    (PRODUCT_NAME, CATEGORY, CURRENT_PRICE, COST, MARGIN_PCT)
VALUES
    ('Premium Laptop',      'Electronics', 1499.99, 900.00, 40.00),
    ('Budget Laptop',       'Electronics',  599.99, 400.00, 33.34),
    ('Wireless Earbuds',    'Audio',        129.99,  50.00, 61.54),
    ('Studio Headphones',   'Audio',        349.99, 150.00, 57.14),
    ('4K Monitor',          'Electronics',  699.99, 350.00, 50.00),
    ('Mechanical Keyboard', 'Peripherals',  149.99,  60.00, 60.00),
    ('Gaming Mouse',        'Peripherals',   79.99,  30.00, 62.50),
    ('USB Microphone',      'Audio',        119.99,  45.00, 62.50);

-- View production data
SELECT * FROM WORKSHOP_DB.PROD_ECOMMERCE.PRODUCTS ORDER BY PRODUCT_ID;

-- STEP A: Clone the production schema for development
CREATE OR REPLACE SCHEMA WORKSHOP_DB.DEV_ECOMMERCE
    CLONE WORKSHOP_DB.PROD_ECOMMERCE;

-- STEP B: Verify the dev environment has all the data
SELECT COUNT(*) AS dev_product_count
FROM WORKSHOP_DB.DEV_ECOMMERCE.PRODUCTS;
-- Expected: 8 products (same as production)

-- STEP C: Test a new pricing algorithm in dev (10% discount on Electronics)
UPDATE WORKSHOP_DB.DEV_ECOMMERCE.PRODUCTS
SET CURRENT_PRICE = ROUND(CURRENT_PRICE * 0.90, 2),
    MARGIN_PCT = ROUND((1 - COST / (CURRENT_PRICE * 0.90)) * 100, 2),
    LAST_UPDATED = CURRENT_TIMESTAMP()
WHERE CATEGORY = 'Electronics';

-- STEP D: Analyze the impact in dev
SELECT
    PRODUCT_NAME,
    CATEGORY,
    p.CURRENT_PRICE AS DEV_PRICE,
    o.CURRENT_PRICE AS PROD_PRICE,
    p.CURRENT_PRICE - o.CURRENT_PRICE AS PRICE_DIFFERENCE,
    p.MARGIN_PCT AS DEV_MARGIN,
    o.MARGIN_PCT AS PROD_MARGIN
FROM WORKSHOP_DB.DEV_ECOMMERCE.PRODUCTS p
JOIN WORKSHOP_DB.PROD_ECOMMERCE.PRODUCTS o
    ON p.PRODUCT_ID = o.PRODUCT_ID
ORDER BY PRICE_DIFFERENCE;

-- STEP E: Confirm production is completely unaffected
SELECT PRODUCT_NAME, CURRENT_PRICE, MARGIN_PCT
FROM WORKSHOP_DB.PROD_ECOMMERCE.PRODUCTS
WHERE CATEGORY = 'Electronics'
ORDER BY PRODUCT_NAME;
-- Expected: Original prices (1499.99, 599.99, 699.99) unchanged

-- ============================================================
-- STEP 10: Clean up -- drop all cloned objects
-- ============================================================

USE ROLE SYSADMIN;

-- Drop cloned tables in PUBLIC schema
DROP TABLE IF EXISTS WORKSHOP_DB.PUBLIC.PRODUCTS_CLONE;
DROP TABLE IF EXISTS WORKSHOP_DB.PUBLIC.PRODUCTS_RECOVERED;
DROP TABLE IF EXISTS WORKSHOP_DB.PUBLIC.PRODUCTS_NO_GRANTS;
DROP TABLE IF EXISTS WORKSHOP_DB.PUBLIC.PRODUCTS_WITH_GRANTS;

-- Drop cloned schemas
DROP SCHEMA IF EXISTS WORKSHOP_DB.SALES_DATA_CLONE;
DROP SCHEMA IF EXISTS WORKSHOP_DB.DEV_ECOMMERCE;

-- Drop cloned database
DROP DATABASE IF EXISTS WORKSHOP_DB_CLONE;

-- Drop the schemas we created for the exercises
DROP SCHEMA IF EXISTS WORKSHOP_DB.SALES_DATA;
DROP SCHEMA IF EXISTS WORKSHOP_DB.PROD_ECOMMERCE;

-- Drop the source table we created
DROP TABLE IF EXISTS WORKSHOP_DB.PUBLIC.PRODUCTS;

-- Revoke the grant we added
USE ROLE SECURITYADMIN;
REVOKE SELECT ON TABLE WORKSHOP_DB.PUBLIC.PRODUCTS FROM ROLE PUBLIC;
-- Note: This may show an error if PRODUCTS was already dropped. That is fine.

USE ROLE SYSADMIN;

-- Verify cleanup
SHOW SCHEMAS IN DATABASE WORKSHOP_DB;

-- ============================================================
-- CONGRATULATIONS! You have completed Lab 08!
--
-- You learned how to:
--   * Clone tables, schemas, and entire databases instantly
--   * Modify cloned data without affecting the original
--   * Understand the zero-copy storage model (copy-on-write)
--   * Combine cloning with Time Travel for point-in-time copies
--   * Use COPY GRANTS to preserve access privileges on clones
--   * Apply cloning to a real-world dev/test workflow
--
-- Move on to Lab 09: Streams and Tasks
-- ============================================================
