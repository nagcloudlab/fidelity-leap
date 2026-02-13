-- ============================================================
-- 01_setup_analytics_tables.sql
-- Creates the analytics schema and tables in Snowflake
-- Target: WORKSHOP_DB.ANALYTICS
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE TRAINING_WH;
USE DATABASE WORKSHOP_DB;

-- Create analytics schema
CREATE SCHEMA IF NOT EXISTS ANALYTICS;
USE SCHEMA ANALYTICS;

-- Orders analytics table (denormalized order header)
CREATE OR REPLACE TABLE ORDERS_ANALYTICS (
    ORDER_ID        NUMBER          NOT NULL,
    CUSTOMER_NAME   VARCHAR(200)    NOT NULL,
    CUSTOMER_EMAIL  VARCHAR(200)    NOT NULL,
    ORDER_DATE      TIMESTAMP_NTZ   NOT NULL,
    STATUS          VARCHAR(50)     NOT NULL,
    TOTAL_AMOUNT    NUMBER(12,2)    NOT NULL,
    ITEM_COUNT      NUMBER          NOT NULL,
    LOADED_AT       TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (ORDER_ID)
);

-- Order items analytics table (line-item detail)
CREATE OR REPLACE TABLE ORDER_ITEMS_ANALYTICS (
    ORDER_ID        NUMBER          NOT NULL,
    PRODUCT_ID      NUMBER          NOT NULL,
    PRODUCT_NAME    VARCHAR(200)    NOT NULL,
    QUANTITY        NUMBER          NOT NULL,
    UNIT_PRICE      NUMBER(10,2)    NOT NULL,
    LINE_TOTAL      NUMBER(12,2)    NOT NULL,
    LOADED_AT       TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP(),
    FOREIGN KEY (ORDER_ID) REFERENCES ORDERS_ANALYTICS(ORDER_ID)
);

-- Verify tables
SHOW TABLES IN SCHEMA ANALYTICS;
