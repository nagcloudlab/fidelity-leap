-- ============================================================================
-- LAB 09: STREAMS & TASKS
-- ============================================================================
-- Objective : Build an automated ETL pipeline using Streams (change data
--             capture) and Tasks (scheduled SQL execution).
-- Scenario  : Raw e-commerce orders land in RAW.RAW_ORDERS. A stream
--             captures every change. A scheduled task consumes those
--             changes and writes processed rows into
--             ANALYTICS.PROCESSED_ORDERS. A child task then refreshes
--             a daily summary table.
-- Duration  : 45 minutes
-- ============================================================================


-- ============================================================================
-- SECTION 1: ENVIRONMENT SETUP
-- ============================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE WORKSHOP_WH;
USE DATABASE WORKSHOP_DB;

-- Create schemas if they do not already exist.
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS ANALYTICS;

-- 1a. Source table -- simulates raw order data arriving from an upstream system.
CREATE OR REPLACE TABLE RAW.RAW_ORDERS (
    ORDER_ID        INT,
    CUSTOMER_NAME   VARCHAR(100),
    PRODUCT         VARCHAR(100),
    QUANTITY        INT,
    UNIT_PRICE      NUMBER(10,2),
    ORDER_STATUS    VARCHAR(20),
    ORDER_DATE      DATE,
    LOADED_AT       TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 1b. Target table -- cleaned / enriched orders for analytics consumption.
CREATE OR REPLACE TABLE ANALYTICS.PROCESSED_ORDERS (
    ORDER_ID        INT,
    CUSTOMER_NAME   VARCHAR(100),
    PRODUCT         VARCHAR(100),
    QUANTITY        INT,
    UNIT_PRICE      NUMBER(10,2),
    TOTAL_AMOUNT    NUMBER(12,2),
    ORDER_STATUS    VARCHAR(20),
    ORDER_DATE      DATE,
    PROCESSED_AT    TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 1c. Summary table -- daily aggregation produced by a child task.
CREATE OR REPLACE TABLE ANALYTICS.DAILY_ORDER_SUMMARY (
    ORDER_DATE      DATE,
    TOTAL_ORDERS    INT,
    TOTAL_REVENUE   NUMBER(14,2),
    AVG_ORDER_VALUE NUMBER(12,2),
    REFRESHED_AT    TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);


-- ============================================================================
-- SECTION 2: CREATE A STREAM ON THE SOURCE TABLE
-- ============================================================================
-- A standard stream captures INSERT, UPDATE, and DELETE changes.

CREATE OR REPLACE STREAM RAW.RAW_ORDERS_STREAM
    ON TABLE RAW.RAW_ORDERS;

-- Confirm the stream exists.
SHOW STREAMS IN SCHEMA RAW;

-- Query the stream -- it should be empty because no changes have occurred yet.
SELECT * FROM RAW.RAW_ORDERS_STREAM;


-- ============================================================================
-- SECTION 3: INSERT DATA AND OBSERVE THE STREAM
-- ============================================================================

-- 3a. Insert a batch of raw orders.
INSERT INTO RAW.RAW_ORDERS (ORDER_ID, CUSTOMER_NAME, PRODUCT, QUANTITY, UNIT_PRICE, ORDER_STATUS, ORDER_DATE)
VALUES
    (1001, 'Alice Johnson',  'Wireless Mouse',     2,  29.99, 'COMPLETED', '2025-01-15'),
    (1002, 'Bob Smith',      'Mechanical Keyboard', 1, 149.99, 'COMPLETED', '2025-01-15'),
    (1003, 'Carol Williams', 'USB-C Hub',           3,  45.00, 'PENDING',   '2025-01-16'),
    (1004, 'David Brown',    'Monitor Stand',       1,  89.95, 'COMPLETED', '2025-01-16'),
    (1005, 'Eva Martinez',   'Webcam HD',           1,  74.50, 'SHIPPED',   '2025-01-17');

-- 3b. Query the stream to see captured INSERT changes.
--     Notice the three metadata columns that Snowflake adds automatically.
SELECT
    METADATA$ACTION,
    METADATA$ISUPDATE,
    METADATA$ROW_ID,
    ORDER_ID,
    CUSTOMER_NAME,
    PRODUCT,
    QUANTITY,
    UNIT_PRICE,
    ORDER_STATUS
FROM RAW.RAW_ORDERS_STREAM;

-- All rows show:
--   METADATA$ACTION   = 'INSERT'
--   METADATA$ISUPDATE = FALSE


-- ============================================================================
-- SECTION 4: UPDATE DATA AND OBSERVE THE STREAM
-- ============================================================================

-- 4a. Update the status of order 1003 from PENDING to SHIPPED.
UPDATE RAW.RAW_ORDERS
SET    ORDER_STATUS = 'SHIPPED'
WHERE  ORDER_ID = 1003;

-- 4b. Query the stream again.
--     The UPDATE appears as two rows:
--       - A DELETE row (old version) with METADATA$ISUPDATE = TRUE
--       - An INSERT row (new version) with METADATA$ISUPDATE = TRUE
SELECT
    METADATA$ACTION,
    METADATA$ISUPDATE,
    METADATA$ROW_ID,
    ORDER_ID,
    CUSTOMER_NAME,
    ORDER_STATUS
FROM RAW.RAW_ORDERS_STREAM
WHERE ORDER_ID = 1003;

-- 4c. View the complete stream contents (all pending changes so far).
SELECT
    METADATA$ACTION,
    METADATA$ISUPDATE,
    ORDER_ID,
    CUSTOMER_NAME,
    PRODUCT,
    ORDER_STATUS
FROM RAW.RAW_ORDERS_STREAM
ORDER BY ORDER_ID, METADATA$ACTION;


-- ============================================================================
-- SECTION 5: DELETE DATA AND OBSERVE THE STREAM
-- ============================================================================

-- 5a. Delete order 1005 (perhaps the customer cancelled).
DELETE FROM RAW.RAW_ORDERS
WHERE ORDER_ID = 1005;

-- 5b. Query the stream for the deleted row.
--     METADATA$ACTION = 'DELETE' and METADATA$ISUPDATE = FALSE.
SELECT
    METADATA$ACTION,
    METADATA$ISUPDATE,
    ORDER_ID,
    CUSTOMER_NAME,
    PRODUCT,
    ORDER_STATUS
FROM RAW.RAW_ORDERS_STREAM
WHERE ORDER_ID = 1005;


-- ============================================================================
-- SECTION 6: CONSUME THE STREAM (MANUAL)
-- ============================================================================
-- Consuming a stream means reading from it inside a DML statement.
-- After the DML commits, the stream's offset advances and it empties.

-- 6a. Process the stream: insert only the net new/updated rows (ACTION = INSERT)
--     into the target table. We skip DELETE-only rows because they represent
--     removed orders that should not appear in the analytics table.
INSERT INTO ANALYTICS.PROCESSED_ORDERS (
    ORDER_ID, CUSTOMER_NAME, PRODUCT, QUANTITY, UNIT_PRICE,
    TOTAL_AMOUNT, ORDER_STATUS, ORDER_DATE
)
SELECT
    ORDER_ID,
    CUSTOMER_NAME,
    PRODUCT,
    QUANTITY,
    UNIT_PRICE,
    QUANTITY * UNIT_PRICE AS TOTAL_AMOUNT,
    ORDER_STATUS,
    ORDER_DATE
FROM RAW.RAW_ORDERS_STREAM
WHERE METADATA$ACTION = 'INSERT';

-- 6b. Verify the stream is now empty -- offset has advanced.
SELECT COUNT(*) AS remaining_stream_rows
FROM RAW.RAW_ORDERS_STREAM;
-- Expected: 0

-- 6c. Check what landed in the target table.
SELECT *
FROM ANALYTICS.PROCESSED_ORDERS
ORDER BY ORDER_ID;


-- ============================================================================
-- SECTION 7: PROVE THE STREAM RESETS AFTER CONSUMPTION
-- ============================================================================

-- 7a. Insert more rows into the source table.
INSERT INTO RAW.RAW_ORDERS (ORDER_ID, CUSTOMER_NAME, PRODUCT, QUANTITY, UNIT_PRICE, ORDER_STATUS, ORDER_DATE)
VALUES
    (1006, 'Frank Lee',    'Laptop Sleeve',  1, 34.99, 'COMPLETED', '2025-01-18'),
    (1007, 'Grace Kim',    'Bluetooth Speaker', 2, 59.00, 'PENDING', '2025-01-18');

-- 7b. The stream now contains ONLY the two new rows, not the earlier ones.
SELECT
    METADATA$ACTION,
    METADATA$ISUPDATE,
    ORDER_ID,
    CUSTOMER_NAME,
    PRODUCT
FROM RAW.RAW_ORDERS_STREAM;

-- 7c. Check if the stream has data (useful for task WHEN clauses).
SELECT SYSTEM$STREAM_HAS_DATA('RAW.RAW_ORDERS_STREAM') AS HAS_DATA;
-- Expected: TRUE


-- ============================================================================
-- SECTION 8: CREATE A TASK (SCHEDULED STREAM CONSUMER)
-- ============================================================================
-- This task runs every 1 minute, but ONLY when the stream has pending data.

CREATE OR REPLACE TASK RAW.PROCESS_ORDERS_TASK
    WAREHOUSE = WORKSHOP_WH
    SCHEDULE  = '1 MINUTE'
    WHEN      SYSTEM$STREAM_HAS_DATA('RAW.RAW_ORDERS_STREAM')
AS
    INSERT INTO ANALYTICS.PROCESSED_ORDERS (
        ORDER_ID, CUSTOMER_NAME, PRODUCT, QUANTITY, UNIT_PRICE,
        TOTAL_AMOUNT, ORDER_STATUS, ORDER_DATE
    )
    SELECT
        ORDER_ID,
        CUSTOMER_NAME,
        PRODUCT,
        QUANTITY,
        UNIT_PRICE,
        QUANTITY * UNIT_PRICE AS TOTAL_AMOUNT,
        ORDER_STATUS,
        ORDER_DATE
    FROM RAW.RAW_ORDERS_STREAM
    WHERE METADATA$ACTION = 'INSERT';

-- Confirm the task was created (it starts in SUSPENDED state).
SHOW TASKS IN SCHEMA RAW;


-- ============================================================================
-- SECTION 9: CREATE A TASK TREE (PARENT -> CHILD)
-- ============================================================================
-- After the parent task processes new orders, the child task refreshes the
-- daily summary table.

CREATE OR REPLACE TASK ANALYTICS.REFRESH_DAILY_SUMMARY_TASK
    WAREHOUSE = WORKSHOP_WH
    AFTER RAW.PROCESS_ORDERS_TASK          -- fires after the parent completes
AS
    MERGE INTO ANALYTICS.DAILY_ORDER_SUMMARY tgt
    USING (
        SELECT
            ORDER_DATE,
            COUNT(*)               AS TOTAL_ORDERS,
            SUM(TOTAL_AMOUNT)      AS TOTAL_REVENUE,
            AVG(TOTAL_AMOUNT)      AS AVG_ORDER_VALUE,
            CURRENT_TIMESTAMP()    AS REFRESHED_AT
        FROM ANALYTICS.PROCESSED_ORDERS
        GROUP BY ORDER_DATE
    ) src
    ON tgt.ORDER_DATE = src.ORDER_DATE
    WHEN MATCHED THEN UPDATE SET
        tgt.TOTAL_ORDERS    = src.TOTAL_ORDERS,
        tgt.TOTAL_REVENUE   = src.TOTAL_REVENUE,
        tgt.AVG_ORDER_VALUE = src.AVG_ORDER_VALUE,
        tgt.REFRESHED_AT    = src.REFRESHED_AT
    WHEN NOT MATCHED THEN INSERT (
        ORDER_DATE, TOTAL_ORDERS, TOTAL_REVENUE, AVG_ORDER_VALUE, REFRESHED_AT
    ) VALUES (
        src.ORDER_DATE, src.TOTAL_ORDERS, src.TOTAL_REVENUE, src.AVG_ORDER_VALUE, src.REFRESHED_AT
    );


-- ============================================================================
-- SECTION 10: RESUME TASKS
-- ============================================================================
-- IMPORTANT: Resume child tasks FIRST, then the root task.
-- If you resume the root first it may fire before the child is active.

-- The ACCOUNTADMIN role (or a role with EXECUTE TASK privilege) is needed
-- to resume tasks.
USE ROLE ACCOUNTADMIN;

ALTER TASK ANALYTICS.REFRESH_DAILY_SUMMARY_TASK RESUME;   -- child first
ALTER TASK RAW.PROCESS_ORDERS_TASK RESUME;                 -- root second

-- Verify both tasks are in 'started' state.
SHOW TASKS IN SCHEMA RAW;
SHOW TASKS IN SCHEMA ANALYTICS;


-- ============================================================================
-- SECTION 11: TEST THE PIPELINE WITH NEW DATA
-- ============================================================================
-- Insert new orders and let the task pipeline pick them up automatically.

USE ROLE SYSADMIN;

INSERT INTO RAW.RAW_ORDERS (ORDER_ID, CUSTOMER_NAME, PRODUCT, QUANTITY, UNIT_PRICE, ORDER_STATUS, ORDER_DATE)
VALUES
    (1008, 'Hannah Park',   'Desk Lamp',      1, 42.00, 'COMPLETED', '2025-01-19'),
    (1009, 'Ivan Chen',     'Ergonomic Chair', 1, 399.00, 'PENDING',  '2025-01-19'),
    (1010, 'Julia Adams',   'Notebook Stand',  2, 27.50, 'COMPLETED', '2025-01-20');

-- The stream now has new data.
SELECT SYSTEM$STREAM_HAS_DATA('RAW.RAW_ORDERS_STREAM') AS HAS_DATA;

-- Wait about 1 minute for the scheduled task to run, then check the results.
-- (Or use EXECUTE TASK in the next section to trigger it immediately.)


-- ============================================================================
-- SECTION 12: MANUAL TASK EXECUTION
-- ============================================================================
-- Instead of waiting for the schedule, you can trigger the root task manually.

USE ROLE ACCOUNTADMIN;

EXECUTE TASK RAW.PROCESS_ORDERS_TASK;

-- Wait a few seconds for execution, then check the target table.
-- (Snowflake executes the task asynchronously; give it a moment.)

USE ROLE SYSADMIN;

SELECT *
FROM ANALYTICS.PROCESSED_ORDERS
ORDER BY ORDER_ID;

-- Check the daily summary (populated by the child task).
SELECT *
FROM ANALYTICS.DAILY_ORDER_SUMMARY
ORDER BY ORDER_DATE;


-- ============================================================================
-- SECTION 13: MONITOR TASK EXECUTION HISTORY
-- ============================================================================
-- TASK_HISTORY() returns details about recent task runs: status, duration,
-- error messages, etc.

USE ROLE ACCOUNTADMIN;

-- View the last 20 runs for the parent task.
SELECT
    NAME,
    STATE,
    SCHEDULED_TIME,
    COMPLETED_TIME,
    ERROR_CODE,
    ERROR_MESSAGE
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(
    TASK_NAME           => 'PROCESS_ORDERS_TASK',
    SCHEDULED_TIME_RANGE_START => DATEADD('HOUR', -1, CURRENT_TIMESTAMP()),
    RESULT_LIMIT        => 20
))
ORDER BY SCHEDULED_TIME DESC;

-- View runs for the child task.
SELECT
    NAME,
    STATE,
    SCHEDULED_TIME,
    COMPLETED_TIME,
    ERROR_CODE,
    ERROR_MESSAGE
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(
    TASK_NAME           => 'REFRESH_DAILY_SUMMARY_TASK',
    SCHEDULED_TIME_RANGE_START => DATEADD('HOUR', -1, CURRENT_TIMESTAMP()),
    RESULT_LIMIT        => 20
))
ORDER BY SCHEDULED_TIME DESC;


-- ============================================================================
-- SECTION 14: BONUS -- APPEND-ONLY STREAM EXAMPLE
-- ============================================================================
-- Append-only streams track INSERT operations only. Updates and deletes
-- are ignored. Useful for staging/landing tables.

USE ROLE SYSADMIN;

CREATE OR REPLACE STREAM RAW.RAW_ORDERS_APPEND_STREAM
    ON TABLE RAW.RAW_ORDERS
    APPEND_ONLY = TRUE;

-- Insert a new row.
INSERT INTO RAW.RAW_ORDERS (ORDER_ID, CUSTOMER_NAME, PRODUCT, QUANTITY, UNIT_PRICE, ORDER_STATUS, ORDER_DATE)
VALUES (1011, 'Kevin White', 'USB Cable', 5, 9.99, 'COMPLETED', '2025-01-20');

-- Update an existing row.
UPDATE RAW.RAW_ORDERS SET ORDER_STATUS = 'SHIPPED' WHERE ORDER_ID = 1009;

-- Delete a row.
DELETE FROM RAW.RAW_ORDERS WHERE ORDER_ID = 1004;

-- The append-only stream shows ONLY the INSERT (order 1011).
-- The UPDATE and DELETE are not captured.
SELECT
    METADATA$ACTION,
    METADATA$ISUPDATE,
    ORDER_ID,
    CUSTOMER_NAME,
    PRODUCT,
    ORDER_STATUS
FROM RAW.RAW_ORDERS_APPEND_STREAM;


-- ============================================================================
-- SECTION 15: BONUS -- CRON SCHEDULE EXAMPLE
-- ============================================================================
-- For production workloads you typically use a CRON expression instead of a
-- simple minute interval. Below is an example (not executed) that runs every
-- day at 6:00 AM UTC.

-- CREATE OR REPLACE TASK RAW.DAILY_ORDER_LOAD_TASK
--     WAREHOUSE = WORKSHOP_WH
--     SCHEDULE  = 'USING CRON 0 6 * * * UTC'
--     WHEN      SYSTEM$STREAM_HAS_DATA('RAW.RAW_ORDERS_STREAM')
-- AS
--     INSERT INTO ANALYTICS.PROCESSED_ORDERS (...)
--     SELECT ... FROM RAW.RAW_ORDERS_STREAM WHERE METADATA$ACTION = 'INSERT';


-- ============================================================================
-- SECTION 16: CLEANUP
-- ============================================================================
-- Always suspend tasks before dropping them.

USE ROLE ACCOUNTADMIN;

-- 16a. Suspend tasks (root first, then children -- reverse of resume order).
ALTER TASK RAW.PROCESS_ORDERS_TASK SUSPEND;
ALTER TASK ANALYTICS.REFRESH_DAILY_SUMMARY_TASK SUSPEND;

-- 16b. Drop tasks.
DROP TASK IF EXISTS ANALYTICS.REFRESH_DAILY_SUMMARY_TASK;
DROP TASK IF EXISTS RAW.PROCESS_ORDERS_TASK;

-- 16c. Drop streams.
USE ROLE SYSADMIN;

DROP STREAM IF EXISTS RAW.RAW_ORDERS_STREAM;
DROP STREAM IF EXISTS RAW.RAW_ORDERS_APPEND_STREAM;

-- 16d. Drop tables (optional -- uncomment if you want a full reset).
-- DROP TABLE IF EXISTS RAW.RAW_ORDERS;
-- DROP TABLE IF EXISTS ANALYTICS.PROCESSED_ORDERS;
-- DROP TABLE IF EXISTS ANALYTICS.DAILY_ORDER_SUMMARY;

-- ============================================================================
-- END OF LAB 09
-- ============================================================================
