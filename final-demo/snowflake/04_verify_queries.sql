-- ============================================================
-- 04_verify_queries.sql
-- Run these after placing orders to verify data landing
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE TRAINING_WH;
USE DATABASE WORKSHOP_DB;
USE SCHEMA ANALYTICS;

-- 1. Check raw orders
SELECT * FROM ORDERS_ANALYTICS ORDER BY LOADED_AT DESC LIMIT 20;

-- 2. Check order items
SELECT * FROM ORDER_ITEMS_ANALYTICS ORDER BY LOADED_AT DESC LIMIT 20;

-- 3. Daily summary view
SELECT * FROM V_DAILY_ORDER_SUMMARY;

-- 4. Product performance view
SELECT * FROM V_PRODUCT_PERFORMANCE;

-- 5. Customer spend view
SELECT * FROM V_CUSTOMER_SPEND;

-- 6. Check stream status (should show 0 rows after task runs)
SELECT SYSTEM$STREAM_HAS_DATA('ORDERS_ANALYTICS_STREAM') AS HAS_DATA;
SELECT * FROM ORDERS_ANALYTICS_STREAM;

-- 7. Realtime summary (populated by task)
SELECT * FROM REALTIME_ORDER_SUMMARY ORDER BY SUMMARY_DATE DESC;

-- 8. Task execution history
SELECT *
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(
    TASK_NAME => 'REFRESH_ORDER_SUMMARY',
    SCHEDULED_TIME_RANGE_START => DATEADD('HOUR', -1, CURRENT_TIMESTAMP())
))
ORDER BY SCHEDULED_TIME DESC;
