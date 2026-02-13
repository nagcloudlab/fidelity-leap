-- ============================================================
-- LAB 04: Loading Data
-- ============================================================
-- Objective: Load data into Snowflake using stages, file
--            formats, COPY INTO, transformation, and unload
-- Duration:  45 minutes
-- Prerequisites: WORKSHOP_DB created in Lab 03
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE WH_DEV;
USE DATABASE WORKSHOP_DB;
USE SCHEMA RAW;

-- ============================================================
-- STEP 1: Understand stages -- your account already has them
-- ============================================================

-- Every user has a personal stage (user stage = @~)
LIST @~;

-- Every table has an automatic stage (table stage = @%table_name)
-- We will create a named stage next, which is the recommended approach.

-- ============================================================
-- STEP 2: Create file formats
-- ============================================================

-- 2A: CSV file format
-- Describes a standard CSV: comma-delimited, one header row,
-- double-quote enclosed fields, empty strings treated as NULL.

CREATE OR REPLACE FILE FORMAT FF_CSV
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    TRIM_SPACE = TRUE
    NULL_IF = ('', 'NULL', 'null', 'N/A')
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
    COMMENT = 'Standard CSV format with header row';

-- 2B: JSON file format
-- Describes a JSON file: one object per line, strip outer array
-- if the file wraps all records in [ ].

CREATE OR REPLACE FILE FORMAT FF_JSON
    TYPE = 'JSON'
    STRIP_OUTER_ARRAY = TRUE
    STRIP_NULL_VALUES = FALSE
    COMMENT = 'Standard JSON format with outer array stripping';

-- 2C: CSV format without header (for raw staged files)
CREATE OR REPLACE FILE FORMAT FF_CSV_NO_HEADER
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    SKIP_HEADER = 0
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    TRIM_SPACE = TRUE
    NULL_IF = ('', 'NULL', 'null')
    COMMENT = 'CSV format without header row';

-- 2D: Pipe-delimited format (common in legacy systems)
CREATE OR REPLACE FILE FORMAT FF_PIPE_DELIMITED
    TYPE = 'CSV'
    FIELD_DELIMITER = '|'
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    TRIM_SPACE = TRUE
    NULL_IF = ('', 'NULL', 'null')
    COMMENT = 'Pipe-delimited format with header row';

-- Verify all file formats
SHOW FILE FORMATS IN SCHEMA RAW;

-- ============================================================
-- STEP 3: Create internal named stages
-- ============================================================

-- 3A: Stage for CSV data
CREATE OR REPLACE STAGE STG_CSV
    FILE_FORMAT = FF_CSV
    COMMENT = 'Internal stage for CSV files';

-- 3B: Stage for JSON data
CREATE OR REPLACE STAGE STG_JSON
    FILE_FORMAT = FF_JSON
    COMMENT = 'Internal stage for JSON files';

-- 3C: Stage for general-purpose loading (no default file format)
CREATE OR REPLACE STAGE STG_GENERAL
    COMMENT = 'General-purpose stage without default file format';

-- Verify all stages
SHOW STAGES IN SCHEMA RAW;

-- You can also describe a stage to see its properties
DESCRIBE STAGE STG_CSV;

-- ============================================================
-- STEP 4: Create target tables
-- ============================================================

-- 4A: Customers table (target for CSV loading)
CREATE OR REPLACE TABLE CUSTOMERS_RAW (
    CUSTOMER_ID     INT,
    FIRST_NAME      VARCHAR(50),
    LAST_NAME       VARCHAR(50),
    EMAIL           VARCHAR(100),
    CITY            VARCHAR(50),
    STATE           VARCHAR(2),
    SIGNUP_DATE     DATE,
    CREDIT_LIMIT    NUMBER(10,2)
);

-- 4B: Orders table (target for CSV loading)
CREATE OR REPLACE TABLE ORDERS_RAW (
    ORDER_ID        INT,
    CUSTOMER_ID     INT,
    ORDER_DATE      DATE,
    PRODUCT_NAME    VARCHAR(100),
    QUANTITY        INT,
    UNIT_PRICE      NUMBER(10,2),
    TOTAL_AMOUNT    NUMBER(12,2)
);

-- 4C: Events table with VARIANT column (target for JSON loading)
CREATE OR REPLACE TABLE EVENTS_RAW (
    EVENT_DATA      VARIANT,
    LOADED_AT       TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 4D: Table for transformation-during-load demo
CREATE OR REPLACE TABLE CUSTOMERS_TRANSFORMED (
    CUSTOMER_ID     INT,
    FULL_NAME       VARCHAR(100),
    EMAIL           VARCHAR(100),
    LOCATION        VARCHAR(100),
    SIGNUP_YEAR     INT,
    CREDIT_TIER     VARCHAR(10),
    LOADED_AT       TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ============================================================
-- STEP 5: Generate sample data and load CSV
-- ============================================================
-- NOTE: The PUT command uploads local files to a stage, but it
-- only works in SnowSQL (CLI), NOT in Snowsight worksheets.
-- To practice COPY INTO, we first create data inside Snowflake,
-- unload it to a stage, then reload it -- simulating the full
-- pipeline without needing local files.

-- 5A: Create a temporary source table and populate it
CREATE OR REPLACE TEMPORARY TABLE CUSTOMERS_SOURCE (
    CUSTOMER_ID     INT,
    FIRST_NAME      VARCHAR(50),
    LAST_NAME       VARCHAR(50),
    EMAIL           VARCHAR(100),
    CITY            VARCHAR(50),
    STATE           VARCHAR(2),
    SIGNUP_DATE     DATE,
    CREDIT_LIMIT    NUMBER(10,2)
);

INSERT INTO CUSTOMERS_SOURCE VALUES
    (1001, 'Alice',   'Johnson',  'alice.johnson@example.com',   'Portland',      'OR', '2024-01-15', 5000.00),
    (1002, 'Bob',     'Smith',    'bob.smith@example.com',       'Seattle',       'WA', '2024-02-20', 7500.00),
    (1003, 'Charlie', 'Williams', 'charlie.w@example.com',       'San Francisco', 'CA', '2024-03-10', 10000.00),
    (1004, 'Diana',   'Brown',    'diana.brown@example.com',     'Denver',        'CO', '2024-04-05', 3000.00),
    (1005, 'Eve',     'Davis',    'eve.davis@example.com',       'Austin',        'TX', '2024-05-22', 8500.00),
    (1006, 'Frank',   'Miller',   'frank.miller@example.com',    'Chicago',       'IL', '2024-06-18', 6000.00),
    (1007, 'Grace',   'Wilson',   'grace.wilson@example.com',    'Boston',        'MA', '2024-07-01', 12000.00),
    (1008, 'Hank',    'Moore',    'hank.moore@example.com',      'Phoenix',       'AZ', '2024-08-30', 4500.00),
    (1009, 'Iris',    'Taylor',   'iris.taylor@example.com',     'Nashville',     'TN', '2024-09-12', 9000.00),
    (1010, 'Jack',    'Anderson', 'jack.anderson@example.com',   'Miami',         'FL', '2024-10-25', 15000.00);

-- 5B: Unload the source data to a stage as CSV files
-- This simulates having CSV files in your stage (just like PUT would create)
COPY INTO @STG_CSV/customers/customers_batch1
    FROM CUSTOMERS_SOURCE
    FILE_FORMAT = (TYPE = 'CSV', HEADER = TRUE)
    OVERWRITE = TRUE;

-- Verify the file was written to the stage
LIST @STG_CSV/customers/;

-- 5C: Load CSV data from the stage into the target table
-- This is the core command you will use most often!
COPY INTO CUSTOMERS_RAW
    FROM @STG_CSV/customers/
    FILE_FORMAT = FF_CSV
    ON_ERROR = 'SKIP_FILE'          -- Skip files with errors
    PURGE = FALSE;                  -- Keep files in stage after load

-- Verify the data loaded successfully
SELECT * FROM CUSTOMERS_RAW ORDER BY CUSTOMER_ID;
SELECT COUNT(*) AS row_count FROM CUSTOMERS_RAW;

-- ============================================================
-- STEP 6: Load JSON data into a VARIANT column
-- ============================================================

-- 6A: Create a temporary source table with JSON events
CREATE OR REPLACE TEMPORARY TABLE EVENTS_SOURCE (
    EVENT_DATA VARIANT
);

INSERT INTO EVENTS_SOURCE
    SELECT PARSE_JSON(column1)
    FROM VALUES
        ('{"event_id": 1, "event_type": "page_view",  "user_id": 1001, "page": "/home",     "timestamp": "2024-11-01T10:15:00Z", "device": "mobile",  "duration_sec": 45}'),
        ('{"event_id": 2, "event_type": "click",       "user_id": 1002, "page": "/products",  "timestamp": "2024-11-01T10:18:30Z", "device": "desktop", "button": "add_to_cart"}'),
        ('{"event_id": 3, "event_type": "purchase",    "user_id": 1003, "page": "/checkout",  "timestamp": "2024-11-01T11:02:00Z", "device": "desktop", "amount": 149.99, "items": [{"sku": "A100", "qty": 2}, {"sku": "B200", "qty": 1}]}'),
        ('{"event_id": 4, "event_type": "page_view",  "user_id": 1001, "page": "/about",     "timestamp": "2024-11-01T12:30:00Z", "device": "tablet",  "duration_sec": 22}'),
        ('{"event_id": 5, "event_type": "signup",      "user_id": 1010, "page": "/register",  "timestamp": "2024-11-01T14:00:00Z", "device": "mobile",  "referrer": "google"}'),
        ('{"event_id": 6, "event_type": "click",       "user_id": 1005, "page": "/products",  "timestamp": "2024-11-02T09:05:00Z", "device": "mobile",  "button": "view_details"}'),
        ('{"event_id": 7, "event_type": "purchase",    "user_id": 1007, "page": "/checkout",  "timestamp": "2024-11-02T10:45:00Z", "device": "desktop", "amount": 299.50, "items": [{"sku": "C300", "qty": 1}]}'),
        ('{"event_id": 8, "event_type": "page_view",  "user_id": 1004, "page": "/pricing",   "timestamp": "2024-11-02T11:20:00Z", "device": "desktop", "duration_sec": 120}');

-- 6B: Unload JSON to the stage
COPY INTO @STG_JSON/events/events_batch1
    FROM (SELECT EVENT_DATA FROM EVENTS_SOURCE)
    FILE_FORMAT = (TYPE = 'JSON')
    OVERWRITE = TRUE;

-- Verify staged files
LIST @STG_JSON/events/;

-- 6C: Load JSON from the stage into the VARIANT table
COPY INTO EVENTS_RAW (EVENT_DATA)
    FROM @STG_JSON/events/
    FILE_FORMAT = FF_JSON
    ON_ERROR = 'SKIP_FILE';

-- 6D: Query the loaded JSON data using dot notation
SELECT
    EVENT_DATA:event_id::INT          AS event_id,
    EVENT_DATA:event_type::STRING     AS event_type,
    EVENT_DATA:user_id::INT           AS user_id,
    EVENT_DATA:page::STRING           AS page,
    EVENT_DATA:timestamp::TIMESTAMP   AS event_timestamp,
    EVENT_DATA:device::STRING         AS device
FROM EVENTS_RAW
ORDER BY event_id;

-- 6E: Query nested JSON arrays using FLATTEN
-- This extracts individual items from the "items" array in purchase events
SELECT
    EVENT_DATA:event_id::INT          AS event_id,
    EVENT_DATA:user_id::INT           AS user_id,
    EVENT_DATA:amount::FLOAT          AS total_amount,
    f.value:sku::STRING               AS item_sku,
    f.value:qty::INT                  AS item_qty
FROM EVENTS_RAW,
    LATERAL FLATTEN(INPUT => EVENT_DATA:items) f
WHERE EVENT_DATA:event_type::STRING = 'purchase';

-- ============================================================
-- STEP 7: Transform data during load
-- ============================================================
-- COPY INTO supports a SELECT subquery so you can reshape data
-- on the fly: reorder columns, cast types, concatenate fields,
-- compute expressions, and add metadata columns.

-- 7A: First, unload customers data with no header for this demo
COPY INTO @STG_GENERAL/transform_demo/customers
    FROM CUSTOMERS_SOURCE
    FILE_FORMAT = (TYPE = 'CSV' HEADER = FALSE)
    OVERWRITE = TRUE;

LIST @STG_GENERAL/transform_demo/;

-- 7B: Load with transformations using a SELECT subquery
-- $1, $2, $3 ... refer to the column positions in the staged file.
COPY INTO CUSTOMERS_TRANSFORMED (CUSTOMER_ID, FULL_NAME, EMAIL, LOCATION, SIGNUP_YEAR, CREDIT_TIER)
    FROM (
        SELECT
            $1::INT,                                        -- CUSTOMER_ID (cast to INT)
            CONCAT($2, ' ', $3),                            -- FULL_NAME (first + last)
            LOWER($4),                                      -- EMAIL (force lowercase)
            CONCAT($5, ', ', $6),                           -- LOCATION (city, state)
            YEAR($7::DATE),                                 -- SIGNUP_YEAR (extract year)
            CASE                                            -- CREDIT_TIER (computed)
                WHEN $8::NUMBER(10,2) >= 10000 THEN 'GOLD'
                WHEN $8::NUMBER(10,2) >= 5000  THEN 'SILVER'
                ELSE 'BRONZE'
            END
        FROM @STG_GENERAL/transform_demo/
        (FILE_FORMAT => FF_CSV_NO_HEADER)
    )
    ON_ERROR = 'ABORT_STATEMENT';

-- Verify the transformed data
SELECT * FROM CUSTOMERS_TRANSFORMED ORDER BY CUSTOMER_ID;

-- ============================================================
-- STEP 8: COPY INTO with pattern matching
-- ============================================================
-- When a stage contains many files, use PATTERN to load only
-- the files whose names match a regular expression.

-- 8A: Create several files in the stage with different names
CREATE OR REPLACE TEMPORARY TABLE ORDERS_SOURCE (
    ORDER_ID        INT,
    CUSTOMER_ID     INT,
    ORDER_DATE      DATE,
    PRODUCT_NAME    VARCHAR(100),
    QUANTITY        INT,
    UNIT_PRICE      NUMBER(10,2),
    TOTAL_AMOUNT    NUMBER(12,2)
);

INSERT INTO ORDERS_SOURCE VALUES
    (5001, 1001, '2024-11-01', 'Wireless Mouse',     2,  29.99,  59.98),
    (5002, 1002, '2024-11-01', 'Mechanical Keyboard', 1,  89.99,  89.99),
    (5003, 1003, '2024-11-02', 'USB-C Hub',           3,  34.99, 104.97),
    (5004, 1001, '2024-11-03', 'Monitor Stand',       1,  49.99,  49.99),
    (5005, 1005, '2024-11-03', 'Webcam HD',           1, 119.99, 119.99);

INSERT INTO ORDERS_SOURCE VALUES
    (5006, 1004, '2024-11-04', 'Laptop Sleeve',       2,  24.99,  49.98),
    (5007, 1007, '2024-11-05', 'Wireless Charger',    1,  39.99,  39.99),
    (5008, 1008, '2024-11-06', 'Noise-Cancel Headset',1, 199.99, 199.99);

-- Unload orders as two separate file batches
COPY INTO @STG_GENERAL/orders/orders_2024_11_01
    FROM (SELECT * FROM ORDERS_SOURCE WHERE ORDER_DATE <= '2024-11-02')
    FILE_FORMAT = (TYPE = 'CSV' HEADER = TRUE)
    OVERWRITE = TRUE;

COPY INTO @STG_GENERAL/orders/orders_2024_11_03
    FROM (SELECT * FROM ORDERS_SOURCE WHERE ORDER_DATE > '2024-11-02')
    FILE_FORMAT = (TYPE = 'CSV' HEADER = TRUE)
    OVERWRITE = TRUE;

-- Also create a file with a different prefix (to demonstrate pattern filtering)
COPY INTO @STG_GENERAL/orders/archive_old_orders
    FROM (SELECT * FROM ORDERS_SOURCE WHERE ORDER_ID = 5001)
    FILE_FORMAT = (TYPE = 'CSV' HEADER = TRUE)
    OVERWRITE = TRUE;

-- See all files in the stage
LIST @STG_GENERAL/orders/;

-- 8B: Load ONLY files matching the "orders_2024" pattern (skip the archive file)
COPY INTO ORDERS_RAW
    FROM @STG_GENERAL/orders/
    FILE_FORMAT = FF_CSV
    PATTERN = '.*orders_2024.*'     -- Regex: file name must contain "orders_2024"
    ON_ERROR = 'SKIP_FILE';

-- Verify: should contain only orders from the orders_2024 files, not the archive
SELECT * FROM ORDERS_RAW ORDER BY ORDER_ID;
SELECT COUNT(*) AS row_count FROM ORDERS_RAW;

-- ============================================================
-- STEP 9: Validate load results
-- ============================================================
-- VALIDATE() inspects the results of the most recent COPY INTO
-- on a given table. It returns rows that caused errors.

-- 9A: Demonstrate with a table that will have errors
CREATE OR REPLACE TABLE NUMBERS_RAW (
    ID      INT,
    AMOUNT  NUMBER(10,2)
);

-- Create a CSV with a deliberately bad row (text in a numeric column)
CREATE OR REPLACE TEMPORARY TABLE NUMBERS_SOURCE (col1 VARCHAR, col2 VARCHAR);
INSERT INTO NUMBERS_SOURCE VALUES
    ('1', '100.00'),
    ('2', '200.50'),
    ('3', 'NOT_A_NUMBER'),    -- This will fail
    ('4', '400.75');

COPY INTO @STG_GENERAL/validate_demo/numbers
    FROM NUMBERS_SOURCE
    FILE_FORMAT = (TYPE = 'CSV' HEADER = FALSE)
    OVERWRITE = TRUE;

-- 9B: Load with ON_ERROR = 'CONTINUE' so it loads what it can
COPY INTO NUMBERS_RAW
    FROM @STG_GENERAL/validate_demo/
    FILE_FORMAT = FF_CSV_NO_HEADER
    ON_ERROR = 'CONTINUE';

-- See what loaded (should be rows 1, 2, and 4)
SELECT * FROM NUMBERS_RAW ORDER BY ID;

-- 9C: Use VALIDATE to find the errors
-- This returns the rows that were rejected during the last COPY INTO
SELECT * FROM TABLE(VALIDATE(NUMBERS_RAW, JOB_ID => '_last'));

-- 9D: Use VALIDATION_MODE to preview errors WITHOUT loading
-- First, truncate and try again with VALIDATION_MODE
TRUNCATE TABLE NUMBERS_RAW;

-- RETURN_ERRORS: shows only the rows that would fail
COPY INTO NUMBERS_RAW
    FROM @STG_GENERAL/validate_demo/
    FILE_FORMAT = FF_CSV_NO_HEADER
    VALIDATION_MODE = 'RETURN_ERRORS';

-- RETURN_5_ROWS: validates and returns the first 5 rows (dry run)
COPY INTO NUMBERS_RAW
    FROM @STG_GENERAL/validate_demo/
    FILE_FORMAT = FF_CSV_NO_HEADER
    VALIDATION_MODE = 'RETURN_5_ROWS';

-- NOTE: VALIDATION_MODE does NOT load any data. The table is still empty.
SELECT COUNT(*) AS row_count FROM NUMBERS_RAW;

-- ============================================================
-- STEP 10: Unload data from a table to a stage
-- ============================================================
-- COPY INTO @stage exports table data as files. This is useful
-- for sharing data, creating backups, or feeding downstream
-- systems that read from cloud storage.

-- 10A: Unload CUSTOMERS_RAW as CSV
COPY INTO @STG_GENERAL/exports/customers_export
    FROM CUSTOMERS_RAW
    FILE_FORMAT = (TYPE = 'CSV' HEADER = TRUE COMPRESSION = 'GZIP')
    OVERWRITE = TRUE
    SINGLE = FALSE            -- Allow multiple output files (parallel)
    MAX_FILE_SIZE = 5000000;  -- ~5 MB per file

-- 10B: Unload EVENTS_RAW as JSON
COPY INTO @STG_GENERAL/exports/events_export
    FROM (SELECT EVENT_DATA FROM EVENTS_RAW)
    FILE_FORMAT = (TYPE = 'JSON' COMPRESSION = 'GZIP')
    OVERWRITE = TRUE;

-- 10C: Verify exported files
LIST @STG_GENERAL/exports/;

-- 10D: You can also unload with a query (join, filter, etc.)
COPY INTO @STG_GENERAL/exports/high_value_customers
    FROM (
        SELECT CUSTOMER_ID, FIRST_NAME, LAST_NAME, EMAIL, CREDIT_LIMIT
        FROM CUSTOMERS_RAW
        WHERE CREDIT_LIMIT >= 8000
        ORDER BY CREDIT_LIMIT DESC
    )
    FILE_FORMAT = (TYPE = 'CSV' HEADER = TRUE)
    OVERWRITE = TRUE;

LIST @STG_GENERAL/exports/high_value;

-- ============================================================
-- STEP 11: Inspect metadata and load history
-- ============================================================

-- 11A: Query load history for your tables
SELECT *
FROM SNOWFLAKE.ACCOUNT_USAGE.LOAD_HISTORY
WHERE TABLE_NAME IN ('CUSTOMERS_RAW', 'ORDERS_RAW', 'EVENTS_RAW', 'NUMBERS_RAW')
ORDER BY LAST_LOAD_TIME DESC
LIMIT 20;

-- 11B: Check COPY history using INFORMATION_SCHEMA (faster, no latency)
SELECT *
FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(
    TABLE_NAME => 'CUSTOMERS_RAW',
    START_TIME => DATEADD('hour', -1, CURRENT_TIMESTAMP())
))
ORDER BY LAST_LOAD_TIME DESC;

-- ============================================================
-- STEP 12: Clean up
-- ============================================================
-- Remove staged files to free storage. Keep tables and file
-- formats for future labs.

REMOVE @STG_CSV/customers/;
REMOVE @STG_JSON/events/;
REMOVE @STG_GENERAL/transform_demo/;
REMOVE @STG_GENERAL/orders/;
REMOVE @STG_GENERAL/validate_demo/;
REMOVE @STG_GENERAL/exports/;

-- Drop the validation demo table (not needed later)
DROP TABLE IF EXISTS NUMBERS_RAW;

-- Verify stages are empty
LIST @STG_CSV;
LIST @STG_JSON;
LIST @STG_GENERAL;

-- ============================================================
-- CONGRATULATIONS! You have completed Lab 04!
-- You now know how to:
--   * Create file formats (CSV, JSON) and named stages
--   * Load CSV and JSON data using COPY INTO
--   * Transform data during load (column mapping, casting, expressions)
--   * Use pattern matching to select specific files
--   * Validate and preview errors before loading
--   * Unload data from tables back to stages
-- Move on to Lab 05: Querying Data
-- ============================================================
