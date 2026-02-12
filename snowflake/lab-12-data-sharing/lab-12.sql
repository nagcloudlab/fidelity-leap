/***********************************************************************
  LAB 12 : DATA SHARING
  Snowflake Workshop -- Beginner Track
  Duration : ~25 minutes

  This script walks through the provider side of Snowflake Secure Data
  Sharing.  Full end-to-end sharing requires two separate Snowflake
  accounts.  Consumer-side commands are included as commented-out
  examples with explanations.

  IMPORTANT: Some commands (reader accounts, adding consumer accounts)
  require ACCOUNTADMIN and may behave differently depending on your
  Snowflake edition and cloud region.
***********************************************************************/


-- =====================================================================
-- SECTION 0 : ENVIRONMENT SETUP
-- =====================================================================
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE WORKSHOP_DB;
USE SCHEMA PUBLIC;


-- =====================================================================
-- SECTION 1 : CREATE SAMPLE DATA TO SHARE
-- =====================================================================
-- We will simulate a company that wants to share product, order, and
-- customer data with an external partner.

-- 1a. Products table (full catalog -- safe to share entirely)
CREATE OR REPLACE TABLE products (
    product_id      INT,
    product_name    VARCHAR(100),
    category        VARCHAR(50),
    unit_price      DECIMAL(10,2),
    in_stock        BOOLEAN
);

INSERT INTO products VALUES
    (1, 'Wireless Mouse',      'Electronics',   29.99, TRUE),
    (2, 'Mechanical Keyboard', 'Electronics',   89.99, TRUE),
    (3, 'USB-C Hub',           'Accessories',   45.50, TRUE),
    (4, 'Monitor Stand',       'Furniture',     64.00, FALSE),
    (5, 'Webcam HD',           'Electronics',  119.00, TRUE),
    (6, 'Desk Lamp',           'Furniture',     37.25, TRUE),
    (7, 'Noise-Cancel Headset','Electronics',  199.99, TRUE),
    (8, 'Laptop Sleeve',       'Accessories',   22.00, TRUE);

-- 1b. Customers table (contains PII -- we will NOT share this directly)
CREATE OR REPLACE TABLE customers (
    customer_id   INT,
    first_name    VARCHAR(50),
    last_name     VARCHAR(50),
    email         VARCHAR(100),
    region        VARCHAR(30),
    signup_date   DATE
);

INSERT INTO customers VALUES
    (101, 'Alice',   'Martin',   'alice.m@example.com',   'North America', '2024-01-15'),
    (102, 'Bob',     'Chen',     'bob.chen@example.com',  'Asia Pacific',  '2024-03-22'),
    (103, 'Carol',   'Smith',    'carol.s@example.com',   'Europe',        '2024-05-10'),
    (104, 'David',   'Kumar',    'david.k@example.com',   'Asia Pacific',  '2024-06-01'),
    (105, 'Eva',     'Garcia',   'eva.g@example.com',     'North America', '2024-07-19');

-- 1c. Orders table
CREATE OR REPLACE TABLE orders (
    order_id      INT,
    customer_id   INT,
    product_id    INT,
    quantity      INT,
    order_date    DATE,
    total_amount  DECIMAL(10,2)
);

INSERT INTO orders VALUES
    (5001, 101, 1, 2, '2024-08-01',  59.98),
    (5002, 102, 7, 1, '2024-08-03', 199.99),
    (5003, 103, 3, 3, '2024-08-05', 136.50),
    (5004, 101, 5, 1, '2024-08-06', 119.00),
    (5005, 104, 2, 1, '2024-08-10',  89.99),
    (5006, 105, 6, 2, '2024-08-12',  74.50),
    (5007, 102, 8, 4, '2024-08-15',  88.00),
    (5008, 103, 1, 1, '2024-08-18',  29.99),
    (5009, 105, 7, 1, '2024-08-20', 199.99),
    (5010, 104, 4, 1, '2024-08-22',  64.00);

-- Quick sanity check
SELECT 'products' AS tbl, COUNT(*) AS row_count FROM products
UNION ALL
SELECT 'customers',        COUNT(*)              FROM customers
UNION ALL
SELECT 'orders',           COUNT(*)              FROM orders;


-- =====================================================================
-- SECTION 2 : CREATE SECURE VIEWS FOR SHARING
-- =====================================================================
-- Secure views are the recommended way to share data because:
--   1. The view definition (SQL) is HIDDEN from consumers.
--   2. You can filter, mask, or aggregate data before sharing.
--   3. The Snowflake optimizer prevents data leakage through
--      query plan inspection.
--
-- IMPORTANT: A regular view exposes its definition via SHOW VIEWS or
-- GET_DDL(). A SECURE view does not.

-- 2a. Secure view: Product catalog (share everything)
CREATE OR REPLACE SECURE VIEW sv_product_catalog AS
SELECT
    product_id,
    product_name,
    category,
    unit_price,
    in_stock
FROM products;

-- 2b. Secure view: Order summary (join orders with products but
--     exclude customer PII -- only expose the customer's region)
CREATE OR REPLACE SECURE VIEW sv_order_summary AS
SELECT
    o.order_id,
    o.order_date,
    c.region          AS customer_region,   -- no name or email
    p.product_name,
    p.category,
    o.quantity,
    o.total_amount
FROM orders   o
JOIN customers c ON o.customer_id = c.customer_id
JOIN products  p ON o.product_id  = p.product_id;

-- 2c. Secure view: Aggregated sales by region (fully anonymised)
CREATE OR REPLACE SECURE VIEW sv_sales_by_region AS
SELECT
    c.region,
    p.category,
    COUNT(*)          AS order_count,
    SUM(o.quantity)   AS units_sold,
    SUM(o.total_amount) AS total_revenue
FROM orders    o
JOIN customers c ON o.customer_id = c.customer_id
JOIN products  p ON o.product_id  = p.product_id
GROUP BY c.region, p.category;

-- Test the secure views
SELECT * FROM sv_product_catalog;
SELECT * FROM sv_order_summary ORDER BY order_date;
SELECT * FROM sv_sales_by_region ORDER BY total_revenue DESC;

-- Verify that the view definition is hidden:
-- For a SECURE view the TEXT column will show NULL or be inaccessible
-- to any role that does not own the view.
SHOW VIEWS LIKE 'SV_%' IN SCHEMA WORKSHOP_DB.PUBLIC;


-- =====================================================================
-- SECTION 3 : CREATE A SECURE UDF FOR SHARING
-- =====================================================================
-- Secure UDFs hide the function body from consumers.  This is useful
-- for sharing computed or derived values without revealing formulas.

-- 3a. Secure UDF: Calculate a volume discount percentage
CREATE OR REPLACE SECURE FUNCTION fn_volume_discount(qty INT)
RETURNS DECIMAL(5,2)
LANGUAGE SQL
AS
$$
    CASE
        WHEN qty >= 10 THEN 15.00
        WHEN qty >= 5  THEN 10.00
        WHEN qty >= 3  THEN  5.00
        ELSE 0.00
    END
$$;

-- Test the UDF
SELECT
    product_name,
    quantity,
    total_amount,
    fn_volume_discount(quantity) AS discount_pct
FROM orders o
JOIN products p ON o.product_id = p.product_id
ORDER BY quantity DESC;


-- =====================================================================
-- SECTION 4 : CREATE A SHARE AND GRANT OBJECTS
-- =====================================================================
-- A share is the container that holds grants on the objects you want
-- to expose to consumers.

-- 4a. Create the share
CREATE OR REPLACE SHARE partner_analytics_share
    COMMENT = 'Product catalog, order summaries, and regional analytics for partner access';

-- 4b. Grant USAGE on the database to the share
--     (consumers need this to "see" the database)
GRANT USAGE ON DATABASE WORKSHOP_DB
    TO SHARE partner_analytics_share;

-- 4c. Grant USAGE on the schema to the share
--     (consumers need this to "see" the schema)
GRANT USAGE ON SCHEMA WORKSHOP_DB.PUBLIC
    TO SHARE partner_analytics_share;

-- 4d. Grant SELECT on the secure views to the share
--     NOTE: We share secure VIEWS, not the underlying raw tables.
GRANT SELECT ON VIEW WORKSHOP_DB.PUBLIC.sv_product_catalog
    TO SHARE partner_analytics_share;

GRANT SELECT ON VIEW WORKSHOP_DB.PUBLIC.sv_order_summary
    TO SHARE partner_analytics_share;

GRANT SELECT ON VIEW WORKSHOP_DB.PUBLIC.sv_sales_by_region
    TO SHARE partner_analytics_share;

-- 4e. Grant USAGE on the secure UDF to the share
GRANT USAGE ON FUNCTION WORKSHOP_DB.PUBLIC.fn_volume_discount(INT)
    TO SHARE partner_analytics_share;

-- 4f. Inspect the share
DESCRIBE SHARE partner_analytics_share;

-- 4g. List all outbound shares from this account
SHOW SHARES;

-- You should see partner_analytics_share listed with kind = OUTBOUND.


-- =====================================================================
-- SECTION 5 : ADD CONSUMER ACCOUNTS TO THE SHARE
-- =====================================================================
-- To actually share data with another Snowflake account you must add
-- that account's locator to the share.  Replace the placeholder below
-- with a real account locator to test end-to-end.

-- Syntax:
-- ALTER SHARE partner_analytics_share ADD ACCOUNTS = <account_locator>;
--
-- Example (uncomment and replace):
-- ALTER SHARE partner_analytics_share ADD ACCOUNTS = AB12345;

-- You can also add multiple accounts at once:
-- ALTER SHARE partner_analytics_share ADD ACCOUNTS = AB12345, CD67890;

-- To see which accounts have access:
DESCRIBE SHARE partner_analytics_share;

-- To remove a consumer's access:
-- ALTER SHARE partner_analytics_share REMOVE ACCOUNTS = AB12345;

-- NOTE: Provider and consumer must be in the same cloud region for
-- direct sharing.  Cross-region / cross-cloud sharing requires
-- replication or listings.


-- =====================================================================
-- SECTION 6 : READER ACCOUNTS (MANAGED ACCOUNTS)
-- =====================================================================
-- If your consumer does NOT have a Snowflake account, you can create a
-- "reader account" (also called a managed account) for them.
--
-- Key points about reader accounts:
--   - The PROVIDER pays for storage and compute.
--   - The reader account can ONLY query data shared with it.
--   - Reader accounts have limited functionality (no loading, no shares
--     of their own, etc.).
--   - Requires ACCOUNTADMIN role.

-- 6a. Create a reader account (may require specific account permissions)
-- Uncomment the block below to try it.  If your account does not
-- support managed accounts you will receive an error.

/*
CREATE MANAGED ACCOUNT partner_reader_acct
    ADMIN_NAME     = 'partner_admin',
    ADMIN_PASSWORD = 'TempP@ssw0rd!2024',
    TYPE           = READER,
    COMMENT        = 'Reader account for external partner without Snowflake';
*/

-- 6b. After creation, Snowflake returns the reader account locator.
--     You must then add it to the share just like any other consumer:

-- ALTER SHARE partner_analytics_share ADD ACCOUNTS = <reader_account_locator>;

-- 6c. List all managed accounts
SHOW MANAGED ACCOUNTS;

-- 6d. To drop a reader account when no longer needed:
-- DROP MANAGED ACCOUNT partner_reader_acct;


-- =====================================================================
-- SECTION 7 : CONSUMER SIDE (CONCEPTUAL -- REQUIRES A SECOND ACCOUNT)
-- =====================================================================
-- The commands below show what a CONSUMER would run in their own
-- Snowflake account after the provider has added them to the share.
-- They are commented out because they must be executed in the
-- consumer's account, not the provider's account.

/*
-- 7a. See inbound shares available to this account
SHOW SHARES;

-- 7b. Create a database from the share
--     Replace <provider_account> with the provider's account locator.
CREATE DATABASE partner_data FROM SHARE <provider_account>.partner_analytics_share;

-- 7c. Grant access to roles in the consumer account
GRANT IMPORTED PRIVILEGES ON DATABASE partner_data TO ROLE SYSADMIN;

-- 7d. Explore the shared database
USE DATABASE partner_data;
SHOW SCHEMAS;
SHOW VIEWS IN SCHEMA PUBLIC;

-- 7e. Query the shared data (read-only -- inserts/updates will fail)
SELECT * FROM partner_data.public.sv_product_catalog;
SELECT * FROM partner_data.public.sv_order_summary;
SELECT * FROM partner_data.public.sv_sales_by_region;

-- 7f. Use the shared UDF
SELECT
    product_name,
    quantity,
    partner_data.public.fn_volume_discount(quantity) AS discount_pct
FROM partner_data.public.sv_order_summary;

-- 7g. Attempting to write will fail:
-- INSERT INTO partner_data.public.sv_product_catalog VALUES (...);
-- ERROR: "Cannot perform INSERT.  The database is a share."
*/


-- =====================================================================
-- SECTION 8 : SNOWFLAKE MARKETPLACE AND LISTINGS (CONCEPTUAL)
-- =====================================================================
-- The Snowflake Marketplace is a catalog where data providers publish
-- "listings" that any Snowflake customer can discover, request access
-- to, and consume -- all through the Snowsight UI.
--
-- TYPES OF LISTINGS:
-- +-----------------------+------------------------------------------+
-- | Listing Type          | Description                              |
-- +-----------------------+------------------------------------------+
-- | Free                  | Anyone can attach instantly               |
-- | Personalized          | Consumer requests access; provider        |
-- |                       | approves and may customize                |
-- | Paid                  | Commercial data products with pricing     |
-- +-----------------------+------------------------------------------+
--
-- HOW IT WORKS:
-- 1. Provider navigates to Snowsight > Data > Provider Studio.
-- 2. Provider creates a new listing, selects the share, adds metadata
--    (title, description, sample queries, documentation).
-- 3. Provider chooses visibility: specific accounts, entire Snowflake
--    Marketplace, or a private exchange.
-- 4. Consumer discovers the listing in the Marketplace, clicks "Get",
--    and Snowflake creates a read-only database automatically.
--
-- BENEFITS OVER MANUAL SHARES:
-- - Built-in discovery and search for consumers.
-- - Usage analytics for providers (who is querying, how often).
-- - Automatic fulfillment: no manual ALTER SHARE ADD ACCOUNTS.
-- - Support for cross-region and cross-cloud delivery via replication.
--
-- You can explore the Marketplace right now:
--   Snowsight > Data Products > Marketplace
--
-- Popular free data sets to try:
--   - Snowflake Usage Insights (by Snowflake)
--   - COVID-19 Epidemiological Data (by Starschema)
--   - Knoema Economy Data Atlas

-- LISTING MANAGEMENT via SQL (Snowflake 2024+):
-- Listings can also be managed programmatically.  Below is illustrative
-- syntax (your account must be enrolled as a provider to execute these).

/*
-- Create a listing from an existing share
CREATE LISTING partner_analytics_listing
    FOR SHARE partner_analytics_share
    AS
    $$
    title: "Partner Analytics Data"
    description: "Product catalog, anonymised order summaries, and regional sales analytics."
    terms_of_service:
      type: "OFFLINE"
      link: "https://example.com/tos"
    $$;

-- Publish the listing to specific accounts
ALTER LISTING partner_analytics_listing
    SET ACCOUNTS = AB12345, CD67890;

-- Publish the listing to the Snowflake Marketplace
ALTER LISTING partner_analytics_listing PUBLISH;

-- View your listings
SHOW LISTINGS;

-- Remove the listing
DROP LISTING partner_analytics_listing;
*/


-- =====================================================================
-- SECTION 9 : REVOKE ACCESS AND CLEANUP
-- =====================================================================

-- 9a. Revoke individual object grants from the share
REVOKE SELECT ON VIEW WORKSHOP_DB.PUBLIC.sv_product_catalog
    FROM SHARE partner_analytics_share;

REVOKE SELECT ON VIEW WORKSHOP_DB.PUBLIC.sv_order_summary
    FROM SHARE partner_analytics_share;

REVOKE SELECT ON VIEW WORKSHOP_DB.PUBLIC.sv_sales_by_region
    FROM SHARE partner_analytics_share;

REVOKE USAGE ON FUNCTION WORKSHOP_DB.PUBLIC.fn_volume_discount(INT)
    FROM SHARE partner_analytics_share;

REVOKE USAGE ON SCHEMA WORKSHOP_DB.PUBLIC
    FROM SHARE partner_analytics_share;

REVOKE USAGE ON DATABASE WORKSHOP_DB
    FROM SHARE partner_analytics_share;

-- 9b. Drop the share itself
DROP SHARE IF EXISTS partner_analytics_share;

-- 9c. Drop the reader account (if you created one)
-- DROP MANAGED ACCOUNT IF EXISTS partner_reader_acct;

-- 9d. Drop lab objects
DROP FUNCTION IF EXISTS WORKSHOP_DB.PUBLIC.fn_volume_discount(INT);
DROP VIEW IF EXISTS WORKSHOP_DB.PUBLIC.sv_sales_by_region;
DROP VIEW IF EXISTS WORKSHOP_DB.PUBLIC.sv_order_summary;
DROP VIEW IF EXISTS WORKSHOP_DB.PUBLIC.sv_product_catalog;
DROP TABLE IF EXISTS WORKSHOP_DB.PUBLIC.orders;
DROP TABLE IF EXISTS WORKSHOP_DB.PUBLIC.customers;
DROP TABLE IF EXISTS WORKSHOP_DB.PUBLIC.products;

-- Verify cleanup
SHOW SHARES LIKE 'PARTNER%';
SHOW VIEWS LIKE 'SV_%' IN SCHEMA WORKSHOP_DB.PUBLIC;
SHOW TABLES LIKE '%' IN SCHEMA WORKSHOP_DB.PUBLIC;


/***********************************************************************
  END OF LAB 12

  WHAT YOU LEARNED:
  -----------------------------------------------------------------
  1. Secure views hide their SQL definition from consumers, making
     them the right choice for sharing filtered or masked data.
  2. A share is a named container of GRANT statements, not a copy
     of data.
  3. Three levels of GRANT are required: database, schema, and the
     individual object (table / view / function).
  4. Reader (managed) accounts let you share data with organizations
     that do not have their own Snowflake account.
  5. The Snowflake Marketplace provides discovery, fulfillment, and
     usage analytics for broader data distribution.
  6. Consumers always see real-time data with zero data movement.
  7. Revoking access is instantaneous -- remove the account from the
     share and the consumer loses access immediately.
***********************************************************************/
