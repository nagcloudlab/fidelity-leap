/***********************************************************************
  Lab 07: Time Travel & Fail-safe
  Snowflake Workshop for Beginners

  Objective : Learn to use Time Travel to query historical data,
              recover dropped objects, and understand Fail-safe.
  Duration  : 30 minutes
  Database  : WORKSHOP_DB (created in Lab 03)
***********************************************************************/


-- =====================================================================
-- SECTION 1: SETUP
-- Create a dedicated schema and a demo table with sample data.
-- =====================================================================

USE DATABASE WORKSHOP_DB;

CREATE OR REPLACE SCHEMA TIME_TRAVEL_LAB;

USE SCHEMA TIME_TRAVEL_LAB;

-- Create a table to experiment with
CREATE OR REPLACE TABLE customer_orders (
    order_id        INT,
    customer_name   STRING,
    product         STRING,
    quantity        INT,
    order_total     DECIMAL(10,2),
    order_date      DATE,
    status          STRING
);

-- Insert sample data (10 orders)
INSERT INTO customer_orders VALUES
    (1001, 'Alice Johnson',   'Laptop',        1, 1299.99, '2025-01-15', 'Shipped'),
    (1002, 'Bob Smith',       'Keyboard',      2,   89.98, '2025-01-16', 'Delivered'),
    (1003, 'Carol Williams',  'Monitor',       1,  449.99, '2025-01-17', 'Shipped'),
    (1004, 'David Brown',     'Mouse',         3,   74.97, '2025-01-18', 'Processing'),
    (1005, 'Eve Davis',       'Headphones',    1,  199.99, '2025-01-19', 'Delivered'),
    (1006, 'Frank Miller',    'Webcam',        1,   79.99, '2025-01-20', 'Shipped'),
    (1007, 'Grace Wilson',    'USB Hub',       2,   49.98, '2025-01-21', 'Delivered'),
    (1008, 'Henry Taylor',    'External SSD',  1,  129.99, '2025-01-22', 'Processing'),
    (1009, 'Irene Anderson',  'Desk Lamp',     1,   34.99, '2025-01-23', 'Shipped'),
    (1010, 'Jack Thomas',     'Chair Mat',     1,   44.99, '2025-01-24', 'Delivered');

-- Verify: you should see 10 rows
SELECT * FROM customer_orders ORDER BY order_id;


-- =====================================================================
-- SECTION 2: CHECK CURRENT TIME TRAVEL SETTINGS
-- Every table has a DATA_RETENTION_TIME_IN_DAYS setting that controls
-- how far back in time you can travel.
-- =====================================================================

-- Show the retention_time column for our table
SHOW TABLES LIKE 'CUSTOMER_ORDERS';

-- You can also check it via INFORMATION_SCHEMA
SELECT table_name,
       retention_time
  FROM INFORMATION_SCHEMA.TABLES
 WHERE table_schema = 'TIME_TRAVEL_LAB'
   AND table_name   = 'CUSTOMER_ORDERS';

-- NOTE: The default is 1 day for Standard edition, 1 day for Enterprise
--       (but Enterprise can be set up to 90 days).


-- =====================================================================
-- SECTION 3: RECORD A TIMESTAMP, THEN MAKE CHANGES
-- We will capture the current time, then modify data so we can use
-- Time Travel to look back at the original state.
-- =====================================================================

-- Step 3a: Save the current timestamp.
--   Copy the result of this query -- you will use it later.
SELECT CURRENT_TIMESTAMP() AS before_changes_timestamp;

-- Let a few seconds pass so the timestamps are clearly different.
-- (In a real scenario you would not need this; data changes happen naturally.)

-- Step 3b: UPDATE -- change the status of some orders
UPDATE customer_orders
   SET status = 'Cancelled'
 WHERE order_id IN (1004, 1008);

-- Verify the update
SELECT * FROM customer_orders WHERE order_id IN (1004, 1008);
-- Expected: status is now 'Cancelled' for orders 1004 and 1008


-- Step 3c: DELETE -- remove some rows
DELETE FROM customer_orders
 WHERE status = 'Delivered';

-- Verify the delete
SELECT * FROM customer_orders ORDER BY order_id;
-- Expected: orders 1002, 1005, 1007, 1010 are gone (they were 'Delivered')
-- You should now have 6 rows remaining.

-- Let's also count to confirm
SELECT COUNT(*) AS remaining_rows FROM customer_orders;


-- =====================================================================
-- SECTION 4: TIME TRAVEL WITH AT(TIMESTAMP => ...)
-- Query the table as it existed at a specific point in time.
-- =====================================================================

-- Replace the timestamp below with the value you copied from Step 3a.
-- Format: 'YYYY-MM-DD HH:MI:SS.FFF -HHMM'
-- Example: '2025-06-15 10:30:00.000 -0700'

-- See all 10 original rows, exactly as they were before any changes:
SELECT *
  FROM customer_orders
       AT(TIMESTAMP => '<paste_your_timestamp_here>'::TIMESTAMP_TZ)
 ORDER BY order_id;

-- TIP: You can also use DATEADD to go back a relative amount of time:
SELECT *
  FROM customer_orders
       AT(TIMESTAMP => DATEADD(MINUTES, -5, CURRENT_TIMESTAMP()))
 ORDER BY order_id;


-- =====================================================================
-- SECTION 5: TIME TRAVEL WITH AT(OFFSET => ...)
-- OFFSET uses seconds. Negative values mean "that many seconds ago."
-- =====================================================================

-- Query the table as it was 5 minutes ago (5 * 60 = 300 seconds)
SELECT *
  FROM customer_orders
       AT(OFFSET => -60*5)
 ORDER BY order_id;

-- If you ran the INSERT less than 5 minutes ago, this will show
-- the original 10 rows (or possibly an empty/non-existent table
-- if the table was created less than 5 minutes ago).


-- =====================================================================
-- SECTION 6: TIME TRAVEL WITH BEFORE(STATEMENT => ...)
-- Query the table as it was just BEFORE a specific SQL statement ran.
-- This is the most precise method -- you target an exact query.
-- =====================================================================

-- Step 6a: First, find the query IDs for the UPDATE and DELETE we ran.
--   Look in Query History (UI) or run:
SELECT query_id,
       query_text,
       start_time
  FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY_BY_SESSION())
 WHERE query_text ILIKE '%customer_orders%'
   AND (query_text ILIKE 'UPDATE%' OR query_text ILIKE 'DELETE%')
 ORDER BY start_time DESC
 LIMIT 5;

-- Step 6b: Copy the query_id of the DELETE statement and paste it below.
-- This shows the data as it was just BEFORE the DELETE ran
-- (i.e., after the UPDATE but before the DELETE):

SELECT *
  FROM customer_orders
       BEFORE(STATEMENT => '<paste_delete_query_id_here>')
 ORDER BY order_id;
-- Expected: 10 rows, but orders 1004 and 1008 show status='Cancelled'

-- Step 6c: Copy the query_id of the UPDATE statement and paste it below.
-- This shows the data as it was just BEFORE the UPDATE ran
-- (i.e., the original 10 rows, untouched):

SELECT *
  FROM customer_orders
       BEFORE(STATEMENT => '<paste_update_query_id_here>')
 ORDER BY order_id;
-- Expected: all 10 original rows with original statuses


-- =====================================================================
-- SECTION 7: OOPS! ACCIDENTAL DELETE -- FULL TABLE RECOVERY
-- A very common real-world scenario: someone runs a DELETE without
-- a WHERE clause and wipes the entire table.
-- =====================================================================

-- Step 7a: Record the current timestamp (we will need it to recover)
SELECT CURRENT_TIMESTAMP() AS before_disaster_timestamp;

-- Step 7b: Simulate the accident!
DELETE FROM customer_orders;

-- Verify: the table is now empty
SELECT COUNT(*) AS rows_after_accident FROM customer_orders;
-- Expected: 0

-- Step 7c: Don't panic! Use Time Travel to recover.
-- Method A: Create a new table from the pre-disaster state.
CREATE OR REPLACE TABLE customer_orders_recovered AS
SELECT *
  FROM customer_orders
       AT(OFFSET => -60)   -- 60 seconds ago (adjust if needed)
 ORDER BY order_id;

-- Verify the recovered data
SELECT * FROM customer_orders_recovered ORDER BY order_id;

-- Step 7d: Swap the tables to restore the original name.
ALTER TABLE customer_orders          RENAME TO customer_orders_damaged;
ALTER TABLE customer_orders_recovered RENAME TO customer_orders;

-- Verify: the "customer_orders" table has data again
SELECT COUNT(*) AS recovered_rows FROM customer_orders;

-- Clean up the damaged table
DROP TABLE customer_orders_damaged;


-- =====================================================================
-- SECTION 8: UNDROP TABLE
-- If you DROP a table (not just delete rows), UNDROP brings it back.
-- =====================================================================

-- Step 8a: Drop the table
DROP TABLE customer_orders;

-- Verify: it is gone
-- This will produce an error:
-- SELECT * FROM customer_orders;

-- Step 8b: Recover it with UNDROP
UNDROP TABLE customer_orders;

-- Verify: it is back!
SELECT COUNT(*) AS rows_after_undrop FROM customer_orders;
SELECT * FROM customer_orders ORDER BY order_id;


-- =====================================================================
-- SECTION 9: UNDROP SCHEMA
-- You can also recover an entire schema that was accidentally dropped.
-- =====================================================================

-- Step 9a: Create a second schema with a table, then drop the schema
CREATE OR REPLACE SCHEMA TEMPORARY_SCHEMA;
USE SCHEMA TEMPORARY_SCHEMA;

CREATE TABLE important_data (id INT, value STRING);
INSERT INTO important_data VALUES (1, 'critical'), (2, 'vital');

SELECT * FROM important_data;

-- Drop the schema (this drops everything inside it)
DROP SCHEMA TEMPORARY_SCHEMA;

-- Verify: it is gone
-- SHOW SCHEMAS LIKE 'TEMPORARY_SCHEMA';

-- Step 9b: Recover it
UNDROP SCHEMA TEMPORARY_SCHEMA;

-- Verify: schema and its table are back
USE SCHEMA TEMPORARY_SCHEMA;
SELECT * FROM important_data;


-- =====================================================================
-- SECTION 10: UNDROP DATABASE
-- Even a dropped database can be recovered within the retention period.
-- =====================================================================

-- Step 10a: Create a temporary database, then drop it
CREATE OR REPLACE DATABASE TEMP_DEMO_DB;
CREATE SCHEMA TEMP_DEMO_DB.DEMO_SCHEMA;
CREATE TABLE TEMP_DEMO_DB.DEMO_SCHEMA.demo_table (id INT);
INSERT INTO TEMP_DEMO_DB.DEMO_SCHEMA.demo_table VALUES (1), (2), (3);

-- Drop the entire database
DROP DATABASE TEMP_DEMO_DB;

-- Step 10b: Recover it
UNDROP DATABASE TEMP_DEMO_DB;

-- Verify
SELECT * FROM TEMP_DEMO_DB.DEMO_SCHEMA.demo_table;

-- Clean up (we don't need this database anymore)
DROP DATABASE TEMP_DEMO_DB;


-- =====================================================================
-- SECTION 11: RESTORE DATA BY CLONING FROM TIME TRAVEL
-- CLONE combined with AT/BEFORE lets you create a point-in-time copy.
-- =====================================================================

USE DATABASE WORKSHOP_DB;
USE SCHEMA TIME_TRAVEL_LAB;

-- Create a clone of the customer_orders table as it was 2 minutes ago
CREATE TABLE customer_orders_backup
  CLONE customer_orders
  AT(OFFSET => -60*2);

-- Compare current vs backup
SELECT 'current' AS source, COUNT(*) AS row_count FROM customer_orders
UNION ALL
SELECT 'backup',            COUNT(*)               FROM customer_orders_backup;

-- Drop the backup when done
DROP TABLE customer_orders_backup;


-- =====================================================================
-- SECTION 12: CHANGE DATA_RETENTION_TIME_IN_DAYS
-- Adjust how far back Time Travel can reach for a specific table.
-- =====================================================================

-- Check the current retention setting
SHOW TABLES LIKE 'CUSTOMER_ORDERS';

-- Increase retention to 5 days (requires Enterprise edition or higher)
-- On Standard edition, the maximum is 1 day and this will error.
ALTER TABLE customer_orders
  SET DATA_RETENTION_TIME_IN_DAYS = 5;

-- Verify the change
SHOW TABLES LIKE 'CUSTOMER_ORDERS';

-- You can also set it at the schema or database level:
-- ALTER SCHEMA TIME_TRAVEL_LAB SET DATA_RETENTION_TIME_IN_DAYS = 5;
-- ALTER DATABASE WORKSHOP_DB   SET DATA_RETENTION_TIME_IN_DAYS = 5;

-- To disable Time Travel entirely (not recommended for important data):
-- ALTER TABLE customer_orders SET DATA_RETENTION_TIME_IN_DAYS = 0;

-- Reset to default (1 day)
ALTER TABLE customer_orders
  SET DATA_RETENTION_TIME_IN_DAYS = 1;


-- =====================================================================
-- SECTION 13: UNDERSTANDING FAIL-SAFE (CONCEPTUAL)
-- Fail-safe cannot be demonstrated directly -- it is managed entirely
-- by Snowflake. This section explains what you need to know.
-- =====================================================================

/*
  FAIL-SAFE OVERVIEW
  ==================

  What is Fail-safe?
  - A 7-day recovery period that begins AFTER Time Travel expires.
  - It is a safety net for catastrophic failures or data corruption.
  - Only Snowflake Support can recover data from Fail-safe.
  - You CANNOT query, clone, or UNDROP data that is in Fail-safe.

  Timeline example (with 1-day Time Travel):
  +-----------+------------------+---------------+-------------------+
  | Day 0     | Days 0-1         | Days 1-8      | After Day 8       |
  | Data      | Time Travel      | Fail-safe     | Data is purged    |
  | changed   | (self-service)   | (Snowflake    | permanently       |
  |           |                  |  Support only)|                   |
  +-----------+------------------+---------------+-------------------+

  Timeline example (with 90-day Time Travel, Enterprise):
  +-----------+------------------+---------------+-------------------+
  | Day 0     | Days 0-90        | Days 90-97    | After Day 97      |
  | Data      | Time Travel      | Fail-safe     | Data is purged    |
  | changed   | (self-service)   | (Snowflake    | permanently       |
  |           |                  |  Support only)|                   |
  +-----------+------------------+---------------+-------------------+

  Storage costs:
  - Both Time Travel and Fail-safe consume storage.
  - You are billed for the additional storage used by changed/deleted data.
  - Transient and temporary tables have NO Fail-safe (saves cost).

  When to contact Snowflake Support:
  - You realize data was lost AFTER the Time Travel period has expired.
  - A system failure corrupted data beyond what Time Travel can fix.
  - You need to recover data and it has been more than your retention days
    but less than retention days + 7.

  To check storage used by Time Travel and Fail-safe:
*/

-- Query storage metrics for your tables
-- (Requires ACCOUNTADMIN or appropriate privileges)
SELECT table_name,
       active_bytes,
       time_travel_bytes,
       failsafe_bytes,
       ROUND(time_travel_bytes / (1024*1024), 2) AS time_travel_mb,
       ROUND(failsafe_bytes   / (1024*1024), 2) AS failsafe_mb
  FROM SNOWFLAKE.ACCOUNT_USAGE.TABLE_STORAGE_METRICS
 WHERE table_catalog = 'WORKSHOP_DB'
   AND table_schema  = 'TIME_TRAVEL_LAB'
   AND active_bytes  > 0
 ORDER BY table_name;

-- NOTE: ACCOUNT_USAGE views have a latency of up to 2 hours,
--       so recently created tables may not appear immediately.


-- =====================================================================
-- SECTION 14: BONUS -- PRACTICAL RECOVERY WORKFLOW
-- A realistic step-by-step workflow for recovering from a mistake.
-- =====================================================================

/*
  SCENARIO: A developer accidentally runs an UPDATE without a WHERE clause,
  setting every customer's status to 'Cancelled'.

  Recovery workflow:
  1. Immediately check QUERY_HISTORY to find the bad query's ID.
  2. Use BEFORE(STATEMENT => ...) to verify the pre-mistake data.
  3. Create a recovery table from the pre-mistake state.
  4. Validate the recovered data.
  5. Swap the tables (rename) to restore the original.
  6. Document the incident and the recovery steps taken.
*/

-- Simulate: the developer runs a bad UPDATE
UPDATE customer_orders SET status = 'Cancelled';

-- Step 1: Find the query ID of the bad update
SELECT query_id,
       query_text,
       start_time,
       end_time
  FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY_BY_SESSION())
 WHERE query_text ILIKE 'UPDATE%customer_orders%'
 ORDER BY start_time DESC
 LIMIT 1;

-- Step 2: Copy the query_id and preview the pre-mistake data
--         Replace <bad_query_id> with the actual query ID.
SELECT *
  FROM customer_orders
       BEFORE(STATEMENT => '<bad_query_id>')
 ORDER BY order_id;

-- Step 3: Create a recovery table
CREATE OR REPLACE TABLE customer_orders_fixed AS
SELECT *
  FROM customer_orders
       BEFORE(STATEMENT => '<bad_query_id>');

-- Step 4: Validate -- compare row counts and spot-check data
SELECT 'broken'  AS version, COUNT(*) AS rows, COUNT(DISTINCT status) AS statuses
  FROM customer_orders
UNION ALL
SELECT 'fixed',              COUNT(*),          COUNT(DISTINCT status)
  FROM customer_orders_fixed;

-- Step 5: Swap tables
ALTER TABLE customer_orders       RENAME TO customer_orders_broken;
ALTER TABLE customer_orders_fixed RENAME TO customer_orders;

-- Verify recovery
SELECT * FROM customer_orders ORDER BY order_id;

-- Drop the broken version
DROP TABLE customer_orders_broken;


-- =====================================================================
-- SECTION 15: CLEANUP
-- Remove the objects created in this lab.
-- =====================================================================

-- Drop the lab schema (CASCADE drops all objects inside it)
DROP SCHEMA IF EXISTS WORKSHOP_DB.TIME_TRAVEL_LAB CASCADE;

-- Drop the temporary schema if it still exists
DROP SCHEMA IF EXISTS WORKSHOP_DB.TEMPORARY_SCHEMA CASCADE;

-- Verify cleanup
USE DATABASE WORKSHOP_DB;
SHOW SCHEMAS;

-- You should no longer see TIME_TRAVEL_LAB or TEMPORARY_SCHEMA.

/*
  =====================================================================
  LAB 07 COMPLETE!
  =====================================================================

  What you learned:
  -----------------
  1. Time Travel lets you query data as it existed in the past using
     AT(TIMESTAMP), AT(OFFSET), and BEFORE(STATEMENT).

  2. UNDROP recovers dropped tables, schemas, and databases within
     the Time Travel retention period.

  3. DATA_RETENTION_TIME_IN_DAYS controls how far back you can travel
     (1 day on Standard, up to 90 days on Enterprise+).

  4. You can create recovery tables or clones from Time Travel to
     restore accidentally modified or deleted data.

  5. Fail-safe is a 7-day, non-configurable, Snowflake-managed recovery
     period that starts after Time Travel expires. Only Snowflake Support
     can recover data from Fail-safe.

  6. Both Time Travel and Fail-safe consume storage -- use transient
     tables for non-critical data to reduce costs.

  Next lab: Lab 08 will cover Roles and Access Control.
  =====================================================================
*/
