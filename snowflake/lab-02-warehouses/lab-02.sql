-- ============================================================
-- LAB 02: Virtual Warehouses
-- ============================================================
-- Objective: Create, configure, resize, and manage warehouses
-- Duration: 30 minutes
-- ============================================================

USE ROLE SYSADMIN;

-- ============================================================
-- STEP 1: Explore existing warehouses
-- ============================================================

SHOW WAREHOUSES;

-- Check details of a specific warehouse
DESCRIBE WAREHOUSE COMPUTE_WH;

-- ============================================================
-- STEP 2: Create warehouses of different sizes
-- ============================================================

-- Create an X-Small warehouse for development work
CREATE OR REPLACE WAREHOUSE WH_DEV
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 60          -- Suspend after 60 seconds of inactivity
    AUTO_RESUME = TRUE         -- Auto-start when query arrives
    MIN_CLUSTER_COUNT = 1
    MAX_CLUSTER_COUNT = 1
    INITIALLY_SUSPENDED = TRUE -- Don't start it immediately
    COMMENT = 'Development warehouse for workshop';

-- Create a Small warehouse for analytics
CREATE OR REPLACE WAREHOUSE WH_ANALYTICS
    WAREHOUSE_SIZE = 'SMALL'
    AUTO_SUSPEND = 120
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Analytics warehouse for workshop';

-- Verify both warehouses were created
SHOW WAREHOUSES LIKE 'WH_%';

-- ============================================================
-- STEP 3: Compare performance across warehouse sizes
-- ============================================================

-- Use the sample data for testing
USE DATABASE SNOWFLAKE_SAMPLE_DATA;
USE SCHEMA TPCH_SF1;

-- Run a query on the DEV warehouse (X-Small)
USE WAREHOUSE WH_DEV;

-- Note the execution time in the Query Profile
SELECT
    O_ORDERPRIORITY,
    COUNT(*) AS order_count,
    SUM(O_TOTALPRICE) AS total_revenue,
    AVG(O_TOTALPRICE) AS avg_order_value
FROM ORDERS
GROUP BY O_ORDERPRIORITY
ORDER BY total_revenue DESC;

-- Run the same query on the ANALYTICS warehouse (Small)
USE WAREHOUSE WH_ANALYTICS;

SELECT
    O_ORDERPRIORITY,
    COUNT(*) AS order_count,
    SUM(O_TOTALPRICE) AS total_revenue,
    AVG(O_TOTALPRICE) AS avg_order_value
FROM ORDERS
GROUP BY O_ORDERPRIORITY
ORDER BY total_revenue DESC;

-- TIP: Compare the execution times in the Query History!
-- The Small warehouse should be faster (more compute nodes)

-- ============================================================
-- STEP 4: Resize a warehouse dynamically
-- ============================================================

-- Resize WH_DEV from X-Small to Medium (no restart needed!)
ALTER WAREHOUSE WH_DEV SET WAREHOUSE_SIZE = 'MEDIUM';

-- Verify the size changed
SHOW WAREHOUSES LIKE 'WH_DEV';

-- Run the same query -- observe the performance difference
USE WAREHOUSE WH_DEV;

SELECT
    O_ORDERPRIORITY,
    COUNT(*) AS order_count,
    SUM(O_TOTALPRICE) AS total_revenue,
    AVG(O_TOTALPRICE) AS avg_order_value
FROM ORDERS
GROUP BY O_ORDERPRIORITY
ORDER BY total_revenue DESC;

-- Scale it back down to save credits
ALTER WAREHOUSE WH_DEV SET WAREHOUSE_SIZE = 'X-SMALL';

-- ============================================================
-- STEP 5: Configure multi-cluster warehouse (Enterprise+)
-- ============================================================

-- Multi-cluster = scale OUT (more clusters for concurrency)
-- Resizing = scale UP (bigger clusters for complex queries)

CREATE OR REPLACE WAREHOUSE WH_MULTI_CLUSTER
    WAREHOUSE_SIZE = 'X-SMALL'
    MIN_CLUSTER_COUNT = 1      -- Minimum 1 cluster
    MAX_CLUSTER_COUNT = 3      -- Scale up to 3 clusters
    SCALING_POLICY = 'STANDARD' -- STANDARD or ECONOMY
    AUTO_SUSPEND = 120
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Multi-cluster warehouse demo';

-- STANDARD policy: Adds clusters quickly when queries queue
-- ECONOMY policy: Adds clusters only when load is sustained (saves credits)

SHOW WAREHOUSES LIKE 'WH_MULTI%';

-- ============================================================
-- STEP 6: Suspend and resume warehouses
-- ============================================================

-- Manually suspend a warehouse (stops credit consumption)
ALTER WAREHOUSE WH_ANALYTICS SUSPEND;

-- Check status
SHOW WAREHOUSES LIKE 'WH_ANALYTICS';

-- Manually resume
ALTER WAREHOUSE WH_ANALYTICS RESUME;

-- Check status again
SHOW WAREHOUSES LIKE 'WH_ANALYTICS';

-- ============================================================
-- STEP 7: Modify warehouse properties
-- ============================================================

-- Change auto-suspend timeout
ALTER WAREHOUSE WH_DEV SET AUTO_SUSPEND = 300;

-- Add a resource monitor (requires ACCOUNTADMIN)
USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE RESOURCE MONITOR WORKSHOP_MONITOR
    WITH
        CREDIT_QUOTA = 10  -- 10 credits max
        FREQUENCY = DAILY
        START_TIMESTAMP = IMMEDIATELY
        TRIGGERS
            ON 75 PERCENT DO NOTIFY
            ON 90 PERCENT DO NOTIFY
            ON 100 PERCENT DO SUSPEND;

-- Assign monitor to a warehouse
ALTER WAREHOUSE WH_DEV SET RESOURCE_MONITOR = WORKSHOP_MONITOR;

-- ============================================================
-- STEP 8: Monitor warehouse usage
-- ============================================================

-- Check warehouse load history (last 24 hours)
SELECT *
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
WHERE WAREHOUSE_NAME IN ('WH_DEV', 'WH_ANALYTICS')
ORDER BY START_TIME DESC
LIMIT 20;

-- Check credit usage by warehouse
SELECT
    WAREHOUSE_NAME,
    SUM(CREDITS_USED) AS total_credits,
    SUM(CREDITS_USED_COMPUTE) AS compute_credits,
    SUM(CREDITS_USED_CLOUD_SERVICES) AS cloud_credits
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE START_TIME >= DATEADD('day', -7, CURRENT_TIMESTAMP())
GROUP BY WAREHOUSE_NAME
ORDER BY total_credits DESC;

-- ============================================================
-- STEP 9: Clean up (suspend warehouses to save credits)
-- ============================================================

USE ROLE SYSADMIN;

ALTER WAREHOUSE WH_DEV SUSPEND;
ALTER WAREHOUSE WH_ANALYTICS SUSPEND;
ALTER WAREHOUSE WH_MULTI_CLUSTER SUSPEND;

-- NOTE: We keep the warehouses for later labs
-- To fully remove: DROP WAREHOUSE WH_DEV;

-- ============================================================
-- CONGRATULATIONS! You've completed Lab 02!
-- You now understand virtual warehouses and how to manage them.
-- Move on to Lab 03: Databases, Schemas & Tables
-- ============================================================
