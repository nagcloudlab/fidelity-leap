-- ============================================================
-- LAB 01: Getting Started with Snowflake
-- ============================================================
-- Objective: Navigate Snowsight, set context, explore your account
-- Duration: 20 minutes
-- ============================================================

-- ============================================================
-- STEP 1: Check your current session info
-- ============================================================

-- What version of Snowflake are we running?
SELECT CURRENT_VERSION();

-- Who am I logged in as?
SELECT CURRENT_USER();

-- What role am I currently using?
SELECT CURRENT_ROLE();

-- What is my current warehouse, database, schema?
SELECT CURRENT_WAREHOUSE(), CURRENT_DATABASE(), CURRENT_SCHEMA();

-- ============================================================
-- STEP 2: Set your session context
-- ============================================================

-- Use the ACCOUNTADMIN role (highest privilege - for exploration only)
USE ROLE ACCOUNTADMIN;

-- Use the default compute warehouse
USE WAREHOUSE COMPUTE_WH;

-- Verify context is set
SELECT CURRENT_ROLE(), CURRENT_WAREHOUSE();

-- ============================================================
-- STEP 3: Explore your account with SHOW commands
-- ============================================================

-- List all databases in your account
SHOW DATABASES;

-- List all warehouses
SHOW WAREHOUSES;

-- List all roles
SHOW ROLES;

-- List all users
SHOW USERS;

-- ============================================================
-- STEP 4: Explore system databases
-- ============================================================

-- Snowflake provides built-in databases for metadata
-- Let's explore SNOWFLAKE database (account usage & info schema)
SHOW SCHEMAS IN DATABASE SNOWFLAKE;

-- Look at account-level usage information
SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.DATABASES
ORDER BY CREATED DESC
LIMIT 10;

-- Check login history (last 10 logins)
SELECT *
FROM SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY
ORDER BY EVENT_TIMESTAMP DESC
LIMIT 10;

-- ============================================================
-- STEP 5: Explore INFORMATION_SCHEMA
-- ============================================================

-- The INFORMATION_SCHEMA exists in every database
-- Let's check what's in the default SNOWFLAKE_SAMPLE_DATA database
USE DATABASE SNOWFLAKE_SAMPLE_DATA;

-- List all schemas
SHOW SCHEMAS;

-- List tables in the TPCH_SF1 schema (sample data)
SHOW TABLES IN SCHEMA TPCH_SF1;

-- Describe a specific table structure
DESCRIBE TABLE TPCH_SF1.CUSTOMER;

-- Quick preview of data
SELECT * FROM TPCH_SF1.CUSTOMER LIMIT 10;

-- Count rows in the table
SELECT COUNT(*) AS total_customers FROM TPCH_SF1.CUSTOMER;

-- ============================================================
-- STEP 6: Understanding Snowflake's sample data
-- ============================================================

-- Snowflake provides TPC-H benchmark data at different scales
-- TPCH_SF1   = Scale Factor 1   (~1 GB, ~6M rows in LINEITEM)
-- TPCH_SF10  = Scale Factor 10  (~10 GB)
-- TPCH_SF100 = Scale Factor 100 (~100 GB)

-- Let's see how much data is in each scale
SELECT COUNT(*) AS row_count FROM TPCH_SF1.LINEITEM;

-- Quick query on sample data
SELECT
    C_MKTSEGMENT,
    COUNT(*) AS customer_count
FROM TPCH_SF1.CUSTOMER
GROUP BY C_MKTSEGMENT
ORDER BY customer_count DESC;

-- ============================================================
-- STEP 7: Useful utility functions
-- ============================================================

-- Current timestamp
SELECT CURRENT_TIMESTAMP();

-- Current date
SELECT CURRENT_DATE();

-- System functions
SELECT SYSTEM$WHITELIST();  -- Shows allowed IPs/endpoints

-- Check your account edition & details
SELECT SYSTEM$RETURN_CURRENT_ORG_NAME();

-- ============================================================
-- CONGRATULATIONS! You've completed Lab 01!
-- You can now navigate Snowsight, set context, and explore
-- your Snowflake account. Move on to Lab 02: Virtual Warehouses
-- ============================================================
