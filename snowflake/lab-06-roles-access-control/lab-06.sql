/***********************************************************************
 *  LAB 06 -- ROLES & ACCESS CONTROL
 *  Snowflake Workshop for Beginners
 *
 *  Objective : Understand Snowflake's Role-Based Access Control (RBAC)
 *              model and implement a real-world access control hierarchy.
 *
 *  Duration  : ~30 minutes
 *
 *  Roles used: ACCOUNTADMIN, SECURITYADMIN, SYSADMIN, custom roles
 *
 *  NOTE: Run each section in order. Statements are separated by
 *        semicolons so you can execute them one at a time or in blocks.
 ***********************************************************************/


-- =====================================================================
-- STEP 1: EXPLORE SYSTEM-DEFINED ROLES
-- =====================================================================
-- Start with the highest-privilege role so we can inspect everything.

USE ROLE ACCOUNTADMIN;

-- 1a. List every role in the account.
--     The output includes system roles and any custom roles that already exist.
SHOW ROLES;

-- 1b. Look at the grants (privileges) that each system role holds.
SHOW GRANTS TO ROLE ACCOUNTADMIN;
SHOW GRANTS TO ROLE SYSADMIN;
SHOW GRANTS TO ROLE SECURITYADMIN;
SHOW GRANTS TO ROLE USERADMIN;
SHOW GRANTS TO ROLE PUBLIC;


-- =====================================================================
-- STEP 2: EXAMINE THE EXISTING ROLE HIERARCHY
-- =====================================================================
-- "SHOW GRANTS OF ROLE" tells us which roles or users a given role has
-- been granted TO.  This reveals the parent-child hierarchy.

-- 2a. SYSADMIN is granted to ACCOUNTADMIN (ACCOUNTADMIN inherits SYSADMIN).
SHOW GRANTS OF ROLE SYSADMIN;

-- 2b. SECURITYADMIN is also granted to ACCOUNTADMIN.
SHOW GRANTS OF ROLE SECURITYADMIN;

-- 2c. USERADMIN is granted to SECURITYADMIN.
SHOW GRANTS OF ROLE USERADMIN;

-- 2d. PUBLIC is granted to every other role automatically.
SHOW GRANTS OF ROLE PUBLIC;

-- SUMMARY OF BUILT-IN HIERARCHY:
--
--              ACCOUNTADMIN
--             /            \
--       SYSADMIN        SECURITYADMIN
--                            |
--                        USERADMIN
--                            |
--                         PUBLIC


-- =====================================================================
-- STEP 3: SET UP LAB OBJECTS (DATABASE, SCHEMA, TABLE, WAREHOUSE)
-- =====================================================================
-- We need some objects to grant privileges on.

USE ROLE SYSADMIN;

-- 3a. Create a dedicated database for this lab.
CREATE OR REPLACE DATABASE lab06_access_control_db;

-- 3b. Create a schema inside the database.
CREATE OR REPLACE SCHEMA lab06_access_control_db.sales_schema;

-- 3c. Create a sample table with data.
CREATE OR REPLACE TABLE lab06_access_control_db.sales_schema.orders (
    order_id        INT,
    customer_name   VARCHAR(100),
    product         VARCHAR(100),
    quantity        INT,
    unit_price      DECIMAL(10,2),
    order_date      DATE
);

INSERT INTO lab06_access_control_db.sales_schema.orders VALUES
    (1, 'Alice Johnson',  'Laptop',        1, 999.99,  '2025-01-15'),
    (2, 'Bob Smith',      'Keyboard',      2,  49.99,  '2025-01-16'),
    (3, 'Carol White',    'Monitor',       1, 349.00,  '2025-01-17'),
    (4, 'David Brown',    'Mouse',         3,  25.50,  '2025-01-18'),
    (5, 'Eve Martinez',   'USB-C Hub',     1,  89.00,  '2025-01-19'),
    (6, 'Frank Lee',      'Webcam',        2,  74.99,  '2025-01-20'),
    (7, 'Grace Kim',      'Laptop Stand',  1,  45.00,  '2025-01-21'),
    (8, 'Hank Patel',     'Headphones',    1, 199.99,  '2025-01-22');

-- 3d. Create a small warehouse for testing (if one does not already exist).
CREATE WAREHOUSE IF NOT EXISTS lab06_wh
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND   = 60
    AUTO_RESUME    = TRUE;


-- =====================================================================
-- STEP 4: CREATE CUSTOM ROLES
-- =====================================================================
-- Switch to SECURITYADMIN -- the recommended role for creating roles
-- and managing grants.

USE ROLE SECURITYADMIN;

-- Four custom roles representing common job functions:
--   WORKSHOP_READER    : Read-only (business stakeholders)
--   WORKSHOP_ANALYST   : Read + create views (data analysts)
--   WORKSHOP_DEVELOPER : Read/write + create tables (developers)
--   WORKSHOP_ADMIN     : Full database management (project lead)

CREATE OR REPLACE ROLE WORKSHOP_READER
    COMMENT = 'Lab 06 - Read-only access to sales data';

CREATE OR REPLACE ROLE WORKSHOP_ANALYST
    COMMENT = 'Lab 06 - Analyst: read + create views';

CREATE OR REPLACE ROLE WORKSHOP_DEVELOPER
    COMMENT = 'Lab 06 - Developer: read/write + create tables';

CREATE OR REPLACE ROLE WORKSHOP_ADMIN
    COMMENT = 'Lab 06 - Admin: full database management';

-- Verify the roles were created.
SHOW ROLES LIKE 'WORKSHOP_%';


-- =====================================================================
-- STEP 5: BUILD THE CUSTOM ROLE HIERARCHY
-- =====================================================================
-- We chain the roles from lowest to highest privilege:
--
--   PUBLIC  (auto-inherited by all roles)
--      |
--   WORKSHOP_READER
--      |
--   WORKSHOP_ANALYST
--      |
--   WORKSHOP_DEVELOPER
--      |
--   WORKSHOP_ADMIN
--      |
--   SYSADMIN            <-- custom roles roll up to SYSADMIN
--      |
--   ACCOUNTADMIN

-- 5a. WORKSHOP_ANALYST inherits WORKSHOP_READER.
GRANT ROLE WORKSHOP_READER    TO ROLE WORKSHOP_ANALYST;

-- 5b. WORKSHOP_DEVELOPER inherits WORKSHOP_ANALYST.
GRANT ROLE WORKSHOP_ANALYST   TO ROLE WORKSHOP_DEVELOPER;

-- 5c. WORKSHOP_ADMIN inherits WORKSHOP_DEVELOPER.
GRANT ROLE WORKSHOP_DEVELOPER TO ROLE WORKSHOP_ADMIN;

-- 5d. SYSADMIN inherits WORKSHOP_ADMIN (best practice: roll up to SYSADMIN).
GRANT ROLE WORKSHOP_ADMIN     TO ROLE SYSADMIN;

-- 5e. Verify the hierarchy by checking who each role is granted to.
SHOW GRANTS OF ROLE WORKSHOP_READER;     -- granted to WORKSHOP_ANALYST
SHOW GRANTS OF ROLE WORKSHOP_ANALYST;    -- granted to WORKSHOP_DEVELOPER
SHOW GRANTS OF ROLE WORKSHOP_DEVELOPER;  -- granted to WORKSHOP_ADMIN
SHOW GRANTS OF ROLE WORKSHOP_ADMIN;      -- granted to SYSADMIN


-- =====================================================================
-- STEP 6: GRANT PRIVILEGES TO EACH ROLE
-- =====================================================================
-- Privileges are granted from narrow (READER) to broad (ADMIN).
-- Because of the hierarchy, ADMIN automatically inherits everything
-- granted to DEVELOPER, ANALYST, and READER.

-- ----- 6a. WORKSHOP_READER: read-only -----

-- Warehouse access (needed to run queries).
GRANT USAGE ON WAREHOUSE lab06_wh
    TO ROLE WORKSHOP_READER;

-- Database and schema access.
GRANT USAGE ON DATABASE lab06_access_control_db
    TO ROLE WORKSHOP_READER;

GRANT USAGE ON SCHEMA lab06_access_control_db.sales_schema
    TO ROLE WORKSHOP_READER;

-- SELECT on all current tables in the schema.
GRANT SELECT ON ALL TABLES IN SCHEMA lab06_access_control_db.sales_schema
    TO ROLE WORKSHOP_READER;

-- SELECT on any tables created in the future (convenient!).
GRANT SELECT ON FUTURE TABLES IN SCHEMA lab06_access_control_db.sales_schema
    TO ROLE WORKSHOP_READER;


-- ----- 6b. WORKSHOP_ANALYST: inherits READER + can create views -----

GRANT CREATE VIEW ON SCHEMA lab06_access_control_db.sales_schema
    TO ROLE WORKSHOP_ANALYST;


-- ----- 6c. WORKSHOP_DEVELOPER: inherits ANALYST + DML + create tables -----

GRANT INSERT, UPDATE, DELETE
    ON ALL TABLES IN SCHEMA lab06_access_control_db.sales_schema
    TO ROLE WORKSHOP_DEVELOPER;

GRANT INSERT, UPDATE, DELETE
    ON FUTURE TABLES IN SCHEMA lab06_access_control_db.sales_schema
    TO ROLE WORKSHOP_DEVELOPER;

GRANT CREATE TABLE ON SCHEMA lab06_access_control_db.sales_schema
    TO ROLE WORKSHOP_DEVELOPER;


-- ----- 6d. WORKSHOP_ADMIN: inherits DEVELOPER + schema creation -----

GRANT CREATE SCHEMA ON DATABASE lab06_access_control_db
    TO ROLE WORKSHOP_ADMIN;


-- =====================================================================
-- STEP 7: CREATE TEST USERS AND ASSIGN ROLES
-- =====================================================================
-- We create four test users, one per custom role.

USE ROLE SECURITYADMIN;

CREATE OR REPLACE USER lab06_reader
    PASSWORD      = 'Reader_Temp_123!'
    DEFAULT_ROLE  = WORKSHOP_READER
    MUST_CHANGE_PASSWORD = FALSE
    COMMENT       = 'Lab 06 test user - reader';

CREATE OR REPLACE USER lab06_analyst
    PASSWORD      = 'Analyst_Temp_123!'
    DEFAULT_ROLE  = WORKSHOP_ANALYST
    MUST_CHANGE_PASSWORD = FALSE
    COMMENT       = 'Lab 06 test user - analyst';

CREATE OR REPLACE USER lab06_developer
    PASSWORD      = 'Developer_Temp_123!'
    DEFAULT_ROLE  = WORKSHOP_DEVELOPER
    MUST_CHANGE_PASSWORD = FALSE
    COMMENT       = 'Lab 06 test user - developer';

CREATE OR REPLACE USER lab06_admin
    PASSWORD      = 'Admin_Temp_123!'
    DEFAULT_ROLE  = WORKSHOP_ADMIN
    MUST_CHANGE_PASSWORD = FALSE
    COMMENT       = 'Lab 06 test user - admin';

-- Assign one custom role to each user.
GRANT ROLE WORKSHOP_READER    TO USER lab06_reader;
GRANT ROLE WORKSHOP_ANALYST   TO USER lab06_analyst;
GRANT ROLE WORKSHOP_DEVELOPER TO USER lab06_developer;
GRANT ROLE WORKSHOP_ADMIN     TO USER lab06_admin;

-- Also grant each role to YOUR current user so you can test with USE ROLE.
-- Replace <YOUR_USERNAME> with your actual Snowflake username.
-- GRANT ROLE WORKSHOP_READER    TO USER <YOUR_USERNAME>;
-- GRANT ROLE WORKSHOP_ANALYST   TO USER <YOUR_USERNAME>;
-- GRANT ROLE WORKSHOP_DEVELOPER TO USER <YOUR_USERNAME>;
-- GRANT ROLE WORKSHOP_ADMIN     TO USER <YOUR_USERNAME>;


-- =====================================================================
-- STEP 8: TEST ACCESS -- SWITCH ROLES AND VERIFY PERMISSIONS
-- =====================================================================
-- USE ROLE lets you "become" a different role in your current session.
-- This is the easiest way to test what each role can and cannot do.

-- ----- 8a. Test as WORKSHOP_READER -----
USE ROLE WORKSHOP_READER;
USE WAREHOUSE lab06_wh;
USE DATABASE lab06_access_control_db;
USE SCHEMA sales_schema;

-- This SHOULD succeed (READER has SELECT).
SELECT * FROM orders LIMIT 5;

-- This SHOULD FAIL (READER does not have INSERT).
-- Uncomment the line below to test; expect an "Insufficient privileges" error.
-- INSERT INTO orders VALUES (9, 'Test User', 'Widget', 1, 10.00, '2025-02-01');

-- This SHOULD FAIL (READER cannot create views).
-- CREATE OR REPLACE VIEW orders_summary AS SELECT product, SUM(quantity) AS total_qty FROM orders GROUP BY product;


-- ----- 8b. Test as WORKSHOP_ANALYST -----
USE ROLE WORKSHOP_ANALYST;

-- SELECT still works (inherited from READER).
SELECT product, SUM(quantity) AS total_qty
FROM orders
GROUP BY product
ORDER BY total_qty DESC;

-- Creating a view SHOULD succeed (ANALYST has CREATE VIEW).
CREATE OR REPLACE VIEW lab06_access_control_db.sales_schema.high_value_orders AS
    SELECT *
    FROM orders
    WHERE unit_price > 100;

SELECT * FROM high_value_orders;

-- INSERT SHOULD still FAIL (ANALYST does not have INSERT).
-- INSERT INTO orders VALUES (9, 'Test User', 'Widget', 1, 10.00, '2025-02-01');


-- ----- 8c. Test as WORKSHOP_DEVELOPER -----
USE ROLE WORKSHOP_DEVELOPER;

-- SELECT works (inherited from READER via ANALYST).
SELECT COUNT(*) AS row_count FROM orders;

-- INSERT SHOULD succeed (DEVELOPER has INSERT).
INSERT INTO orders VALUES
    (9,  'Ivy Chen',    'Desk Lamp', 2, 35.00, '2025-01-23'),
    (10, 'Jack Wilson', 'Cable Kit', 1, 19.99, '2025-01-24');

-- Verify the new rows.
SELECT * FROM orders WHERE order_id >= 9;

-- CREATE TABLE SHOULD succeed (DEVELOPER has CREATE TABLE).
CREATE OR REPLACE TABLE lab06_access_control_db.sales_schema.returns (
    return_id   INT,
    order_id    INT,
    reason      VARCHAR(200),
    return_date DATE
);

INSERT INTO lab06_access_control_db.sales_schema.returns VALUES
    (1, 4, 'Defective mouse button', '2025-01-25');

-- CREATE SCHEMA SHOULD FAIL (DEVELOPER does not have CREATE SCHEMA).
-- CREATE SCHEMA lab06_access_control_db.new_schema;


-- ----- 8d. Test as WORKSHOP_ADMIN -----
USE ROLE WORKSHOP_ADMIN;

-- Everything above works, plus CREATE SCHEMA.
CREATE OR REPLACE SCHEMA lab06_access_control_db.analytics_schema;

-- Verify the new schema exists.
SHOW SCHEMAS IN DATABASE lab06_access_control_db;


-- =====================================================================
-- STEP 9: DEMONSTRATE PRIVILEGE CASCADING THROUGH THE HIERARCHY
-- =====================================================================
-- Because WORKSHOP_ADMIN inherits WORKSHOP_DEVELOPER, which inherits
-- WORKSHOP_ANALYST, which inherits WORKSHOP_READER, a single grant
-- to READER cascades all the way up to ADMIN.

USE ROLE SECURITYADMIN;

-- Grant SELECT on the new "returns" table to READER only.
GRANT SELECT ON TABLE lab06_access_control_db.sales_schema.returns
    TO ROLE WORKSHOP_READER;

-- Now verify that ADMIN can also read it (without a direct grant).
USE ROLE WORKSHOP_ADMIN;
USE WAREHOUSE lab06_wh;
SELECT * FROM lab06_access_control_db.sales_schema.returns;
-- Success!  ADMIN inherited SELECT through the role chain.


-- =====================================================================
-- STEP 10: VERIFY PERMISSIONS WITH SHOW GRANTS
-- =====================================================================

USE ROLE SECURITYADMIN;

-- 10a. What privileges have been granted ON the orders table?
SHOW GRANTS ON TABLE lab06_access_control_db.sales_schema.orders;

-- 10b. What privileges does WORKSHOP_READER hold?
SHOW GRANTS TO ROLE WORKSHOP_READER;

-- 10c. What privileges does WORKSHOP_DEVELOPER hold (direct grants only)?
SHOW GRANTS TO ROLE WORKSHOP_DEVELOPER;

-- 10d. Which roles/users has WORKSHOP_ANALYST been granted to?
SHOW GRANTS OF ROLE WORKSHOP_ANALYST;

-- 10e. What future grants exist on the schema?
SHOW FUTURE GRANTS IN SCHEMA lab06_access_control_db.sales_schema;


-- =====================================================================
-- STEP 11: DEMONSTRATE REVOKE
-- =====================================================================
-- Revoke removes a specific privilege. It does NOT affect privileges
-- granted to other roles in the hierarchy.

USE ROLE SECURITYADMIN;

-- 11a. Revoke CREATE VIEW from WORKSHOP_ANALYST.
REVOKE CREATE VIEW ON SCHEMA lab06_access_control_db.sales_schema
    FROM ROLE WORKSHOP_ANALYST;

-- 11b. Confirm it is gone.
SHOW GRANTS TO ROLE WORKSHOP_ANALYST;

-- 11c. Try creating a view as ANALYST -- this should now FAIL.
USE ROLE WORKSHOP_ANALYST;
USE WAREHOUSE lab06_wh;
-- Uncomment to test; expect "Insufficient privileges":
-- CREATE OR REPLACE VIEW lab06_access_control_db.sales_schema.test_view AS SELECT 1 AS col;

-- 11d. Re-grant it so cleanup is clean.
USE ROLE SECURITYADMIN;
GRANT CREATE VIEW ON SCHEMA lab06_access_control_db.sales_schema
    TO ROLE WORKSHOP_ANALYST;


-- =====================================================================
-- STEP 12: CLEANUP
-- =====================================================================
-- Remove all lab objects so the account is left in its original state.
-- Run this section when you are finished with the lab.

USE ROLE SECURITYADMIN;

-- 12a. Revoke future grants (must be done before dropping the schema).
REVOKE SELECT ON FUTURE TABLES IN SCHEMA lab06_access_control_db.sales_schema
    FROM ROLE WORKSHOP_READER;
REVOKE INSERT, UPDATE, DELETE ON FUTURE TABLES IN SCHEMA lab06_access_control_db.sales_schema
    FROM ROLE WORKSHOP_DEVELOPER;

-- 12b. Drop test users.
DROP USER IF EXISTS lab06_reader;
DROP USER IF EXISTS lab06_analyst;
DROP USER IF EXISTS lab06_developer;
DROP USER IF EXISTS lab06_admin;

-- 12c. Revoke role hierarchy links.
REVOKE ROLE WORKSHOP_ADMIN     FROM ROLE SYSADMIN;
REVOKE ROLE WORKSHOP_DEVELOPER FROM ROLE WORKSHOP_ADMIN;
REVOKE ROLE WORKSHOP_ANALYST   FROM ROLE WORKSHOP_DEVELOPER;
REVOKE ROLE WORKSHOP_READER    FROM ROLE WORKSHOP_ANALYST;

-- 12d. Drop custom roles.
DROP ROLE IF EXISTS WORKSHOP_ADMIN;
DROP ROLE IF EXISTS WORKSHOP_DEVELOPER;
DROP ROLE IF EXISTS WORKSHOP_ANALYST;
DROP ROLE IF EXISTS WORKSHOP_READER;

-- 12e. Drop database (cascades to schemas, tables, views).
USE ROLE SYSADMIN;
DROP DATABASE IF EXISTS lab06_access_control_db;

-- 12f. Drop warehouse.
DROP WAREHOUSE IF EXISTS lab06_wh;

-- Verify cleanup.
SHOW ROLES LIKE 'WORKSHOP_%';   -- Should return 0 rows.
SHOW DATABASES LIKE 'LAB06%';   -- Should return 0 rows.


/***********************************************************************
 *  END OF LAB 06
 *
 *  Key takeaways:
 *    - Privileges are granted to ROLES, not directly to users.
 *    - A parent role inherits all privileges of its child roles.
 *    - Custom roles should roll up to SYSADMIN.
 *    - Use the principle of least privilege: start narrow, widen only
 *      when needed.
 *    - SHOW GRANTS ON / TO / OF is your best friend for auditing.
 *
 *  Next: Lab 07 -- Data Sharing & Marketplace
 ***********************************************************************/
