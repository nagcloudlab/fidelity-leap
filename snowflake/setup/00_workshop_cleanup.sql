-- ============================================================
-- SNOWFLAKE WORKSHOP: MASTER CLEANUP SCRIPT
-- ============================================================
-- Run this script AFTER completing all labs to remove
-- all workshop objects and free up resources.
--
-- WARNING: This will permanently delete all workshop data!
-- ============================================================

USE ROLE ACCOUNTADMIN;

-- ============================================================
-- STEP 1: Drop warehouses created during the workshop
-- ============================================================
DROP WAREHOUSE IF EXISTS WH_DEV;
DROP WAREHOUSE IF EXISTS WH_ANALYTICS;
DROP WAREHOUSE IF EXISTS WH_MULTI_CLUSTER;

-- ============================================================
-- STEP 2: Drop databases created during the workshop
-- ============================================================
DROP DATABASE IF EXISTS WORKSHOP_DB;
DROP DATABASE IF EXISTS WORKSHOP_DB_CLONE;
DROP DATABASE IF EXISTS WORKSHOP_DB_DEV;
DROP DATABASE IF EXISTS ECOMMERCE_DW;
DROP DATABASE IF EXISTS ECOMMERCE_DW_DEV;

-- ============================================================
-- STEP 3: Drop shares created during the workshop
-- ============================================================
DROP SHARE IF EXISTS WORKSHOP_SHARE;
DROP SHARE IF EXISTS ECOMMERCE_SHARE;

-- ============================================================
-- STEP 4: Drop custom roles created during the workshop
-- ============================================================
USE ROLE SECURITYADMIN;

DROP ROLE IF EXISTS WORKSHOP_ADMIN;
DROP ROLE IF EXISTS WORKSHOP_ANALYST;
DROP ROLE IF EXISTS WORKSHOP_DEVELOPER;
DROP ROLE IF EXISTS WORKSHOP_READER;
DROP ROLE IF EXISTS ECOMMERCE_ANALYST;
DROP ROLE IF EXISTS ECOMMERCE_ADMIN;

-- ============================================================
-- STEP 5: Drop users created during the workshop
-- ============================================================
DROP USER IF EXISTS WORKSHOP_USER1;
DROP USER IF EXISTS WORKSHOP_USER2;

-- ============================================================
-- STEP 6: Drop resource monitors
-- ============================================================
USE ROLE ACCOUNTADMIN;
DROP RESOURCE MONITOR IF EXISTS WORKSHOP_MONITOR;

-- ============================================================
-- CLEANUP COMPLETE!
-- All workshop objects have been removed.
-- ============================================================

-- Verify cleanup
SHOW DATABASES LIKE 'WORKSHOP%';
SHOW DATABASES LIKE 'ECOMMERCE%';
SHOW WAREHOUSES LIKE 'WH_%';
SHOW ROLES LIKE 'WORKSHOP_%';
SHOW ROLES LIKE 'ECOMMERCE_%';
