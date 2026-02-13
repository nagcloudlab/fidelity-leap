-- ============================================================
-- 02_create_views.sql
-- Analytical views for the dashboard
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE TRAINING_WH;
USE DATABASE WORKSHOP_DB;
USE SCHEMA ANALYTICS;

-- Daily order summary: aggregates by day
CREATE OR REPLACE VIEW V_DAILY_ORDER_SUMMARY AS
SELECT
    DATE_TRUNC('DAY', ORDER_DATE)::DATE  AS ORDER_DAY,
    COUNT(*)                              AS TOTAL_ORDERS,
    SUM(TOTAL_AMOUNT)                     AS TOTAL_REVENUE,
    ROUND(AVG(TOTAL_AMOUNT), 2)           AS AVG_ORDER_VALUE,
    SUM(ITEM_COUNT)                       AS TOTAL_ITEMS
FROM ORDERS_ANALYTICS
GROUP BY ORDER_DAY
ORDER BY ORDER_DAY DESC;

-- Product performance: product-level metrics
CREATE OR REPLACE VIEW V_PRODUCT_PERFORMANCE AS
SELECT
    PRODUCT_NAME,
    COUNT(DISTINCT ORDER_ID)    AS TIMES_ORDERED,
    SUM(QUANTITY)               AS TOTAL_UNITS_SOLD,
    SUM(LINE_TOTAL)             AS TOTAL_REVENUE,
    ROUND(AVG(UNIT_PRICE), 2)  AS AVG_UNIT_PRICE
FROM ORDER_ITEMS_ANALYTICS
GROUP BY PRODUCT_NAME
ORDER BY TOTAL_REVENUE DESC;

-- Customer spend: customer-level aggregation
CREATE OR REPLACE VIEW V_CUSTOMER_SPEND AS
SELECT
    CUSTOMER_NAME,
    CUSTOMER_EMAIL,
    COUNT(*)                              AS ORDER_COUNT,
    SUM(TOTAL_AMOUNT)                     AS TOTAL_SPEND,
    ROUND(AVG(TOTAL_AMOUNT), 2)           AS AVG_ORDER_VALUE,
    MIN(ORDER_DATE)                       AS FIRST_ORDER,
    MAX(ORDER_DATE)                       AS LAST_ORDER
FROM ORDERS_ANALYTICS
GROUP BY CUSTOMER_NAME, CUSTOMER_EMAIL
ORDER BY TOTAL_SPEND DESC;

-- Verify views
SHOW VIEWS IN SCHEMA ANALYTICS;
