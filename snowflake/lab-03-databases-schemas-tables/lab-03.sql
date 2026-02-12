-- ============================================================
-- LAB 03: Databases, Schemas & Tables
-- ============================================================
-- Objective: Create and manage databases, schemas, tables,
--            and views using DDL operations
-- Duration: 40 minutes
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE WH_DEV;

-- ============================================================
-- STEP 1: Create the workshop database and schemas
-- ============================================================
-- A database is the top-level container for all objects.
-- Schemas organize objects within a database by purpose.

-- Create the workshop database
CREATE OR REPLACE DATABASE WORKSHOP_DB
    COMMENT = 'Workshop database for Snowflake training labs';

-- Verify the database was created
SHOW DATABASES LIKE 'WORKSHOP_DB';

-- Every new database comes with two default schemas:
--   PUBLIC       (default schema for objects)
--   INFORMATION_SCHEMA (read-only metadata views)
SHOW SCHEMAS IN DATABASE WORKSHOP_DB;

-- Create schemas for a typical data pipeline architecture:
--   RAW        -> where raw/ingested data lands
--   STAGING    -> where data is cleaned and transformed
--   ANALYTICS  -> where final, consumption-ready tables live

CREATE OR REPLACE SCHEMA WORKSHOP_DB.RAW
    COMMENT = 'Raw ingested data -- land zone for all data sources';

CREATE OR REPLACE SCHEMA WORKSHOP_DB.STAGING
    COMMENT = 'Staging area -- cleaned and transformed data';

CREATE OR REPLACE SCHEMA WORKSHOP_DB.ANALYTICS
    COMMENT = 'Analytics layer -- curated tables and views for BI tools';

-- Verify all schemas exist
SHOW SCHEMAS IN DATABASE WORKSHOP_DB;

-- Set the working context for the rest of this lab
USE DATABASE WORKSHOP_DB;
USE SCHEMA RAW;

-- ============================================================
-- STEP 2: Explore Snowflake data types
-- ============================================================
-- Snowflake supports structured and semi-structured types.
-- This reference table demonstrates ALL major data types.

CREATE OR REPLACE TABLE WORKSHOP_DB.RAW.DATA_TYPES_REFERENCE (
    -- ---- Numeric Types ----
    id                  INTEGER         NOT NULL,   -- Alias for NUMBER(38,0)
    quantity            NUMBER(10,0),               -- Integer with precision
    price               NUMBER(12,2),               -- Decimal: 12 digits, 2 after decimal
    tax_rate            FLOAT,                      -- Floating-point (approx.)

    -- ---- String Types ----
    name                VARCHAR(100)    NOT NULL,   -- Variable-length string
    description         TEXT,                       -- Alias for VARCHAR(16777216)
    status_code         CHAR(3),                    -- Fixed-length string

    -- ---- Date & Time Types ----
    created_date        DATE,                       -- Date only (no time)
    created_at          TIMESTAMP_NTZ,              -- Timestamp without time zone
    updated_at          TIMESTAMP_LTZ,              -- Timestamp with local time zone
    event_time          TIMESTAMP_TZ,               -- Timestamp with explicit time zone
    duration            TIME,                       -- Time of day only

    -- ---- Boolean ----
    is_active           BOOLEAN         DEFAULT TRUE,

    -- ---- Semi-Structured Types ----
    raw_json            VARIANT,                    -- Any JSON, Avro, ORC, Parquet value
    tags                ARRAY,                      -- Ordered list of values
    metadata            OBJECT,                     -- Key-value pairs (like JSON object)

    -- ---- Binary ----
    file_hash           BINARY(32)                  -- Binary data (e.g., SHA-256 hash)
);

-- Insert a sample row showing each data type in action
INSERT INTO WORKSHOP_DB.RAW.DATA_TYPES_REFERENCE VALUES (
    1,                                              -- id (INTEGER)
    25,                                             -- quantity (NUMBER)
    99.95,                                          -- price (NUMBER)
    0.0825,                                         -- tax_rate (FLOAT)
    'Widget Pro',                                   -- name (VARCHAR)
    'A high-quality widget for professionals',      -- description (TEXT)
    'ACT',                                          -- status_code (CHAR)
    '2025-01-15',                                   -- created_date (DATE)
    '2025-01-15 10:30:00',                          -- created_at (TIMESTAMP_NTZ)
    '2025-01-15 10:30:00 -0800',                    -- updated_at (TIMESTAMP_LTZ)
    '2025-01-15 10:30:00 -0800',                    -- event_time (TIMESTAMP_TZ)
    '14:30:00',                                     -- duration (TIME)
    TRUE,                                           -- is_active (BOOLEAN)
    PARSE_JSON('{"source":"api","version":"2.1"}'), -- raw_json (VARIANT)
    ARRAY_CONSTRUCT('electronics','premium','new'),  -- tags (ARRAY)
    OBJECT_CONSTRUCT('color','blue','weight_kg',1.2),-- metadata (OBJECT)
    HEX_DECODE_STRING('ABCDEF1234567890ABCDEF1234567890ABCDEF1234567890ABCDEF1234567890') -- file_hash (BINARY)
);

-- Query the sample row to see how each type is stored
SELECT * FROM WORKSHOP_DB.RAW.DATA_TYPES_REFERENCE;

-- Access semi-structured data with colon notation
SELECT
    name,
    raw_json:source::STRING     AS data_source,
    raw_json:version::STRING    AS api_version,
    tags[0]::STRING             AS first_tag,
    metadata:color::STRING      AS color
FROM WORKSHOP_DB.RAW.DATA_TYPES_REFERENCE;

-- ============================================================
-- STEP 3: Create permanent tables (e-commerce data model)
-- ============================================================
-- We will build four related tables: CUSTOMERS, PRODUCTS,
-- ORDERS, and ORDER_ITEMS. These are permanent tables --
-- data persists until dropped, with full Time Travel and
-- Fail-safe protection.

USE SCHEMA WORKSHOP_DB.ANALYTICS;

-- -----------------------------------------------------------
-- CUSTOMERS table
-- -----------------------------------------------------------
CREATE OR REPLACE TABLE CUSTOMERS (
    customer_id         INTEGER         NOT NULL,
    first_name          VARCHAR(50)     NOT NULL,
    last_name           VARCHAR(50)     NOT NULL,
    email               VARCHAR(200)    NOT NULL,
    phone               VARCHAR(20),
    date_of_birth       DATE,
    address_line1       VARCHAR(200),
    address_line2       VARCHAR(200),
    city                VARCHAR(100),
    state               VARCHAR(50),
    zip_code            VARCHAR(10),
    country             VARCHAR(50)     DEFAULT 'US',
    customer_segment    VARCHAR(20)     DEFAULT 'STANDARD',
    is_active           BOOLEAN         DEFAULT TRUE,
    created_at          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP(),
    updated_at          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP(),

    -- Constraints (informational in Snowflake, except NOT NULL)
    CONSTRAINT pk_customers PRIMARY KEY (customer_id),
    CONSTRAINT uq_customers_email UNIQUE (email)
)
COMMENT = 'Customer master data for the e-commerce platform';

-- -----------------------------------------------------------
-- PRODUCTS table
-- -----------------------------------------------------------
CREATE OR REPLACE TABLE PRODUCTS (
    product_id          INTEGER         NOT NULL,
    product_name        VARCHAR(200)    NOT NULL,
    category            VARCHAR(100)    NOT NULL,
    subcategory         VARCHAR(100),
    brand               VARCHAR(100),
    unit_price          NUMBER(10,2)    NOT NULL,
    cost_price          NUMBER(10,2),
    weight_kg           FLOAT,
    description         TEXT,
    sku                 VARCHAR(50)     NOT NULL,
    inventory_qty       INTEGER         DEFAULT 0,
    is_available        BOOLEAN         DEFAULT TRUE,
    attributes          VARIANT,        -- Semi-structured product attributes (JSON)
    created_at          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP(),
    updated_at          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP(),

    CONSTRAINT pk_products PRIMARY KEY (product_id),
    CONSTRAINT uq_products_sku UNIQUE (sku)
)
COMMENT = 'Product catalog for the e-commerce platform';

-- -----------------------------------------------------------
-- ORDERS table
-- -----------------------------------------------------------
CREATE OR REPLACE TABLE ORDERS (
    order_id            INTEGER         NOT NULL,
    customer_id         INTEGER         NOT NULL,
    order_date          DATE            NOT NULL,
    order_status        VARCHAR(20)     NOT NULL DEFAULT 'PENDING',
    shipping_method     VARCHAR(50),
    shipping_address    VARCHAR(500),
    subtotal            NUMBER(12,2)    NOT NULL,
    tax_amount          NUMBER(12,2)    DEFAULT 0.00,
    shipping_cost       NUMBER(10,2)    DEFAULT 0.00,
    total_amount        NUMBER(12,2)    NOT NULL,
    payment_method      VARCHAR(50),
    notes               TEXT,
    created_at          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP(),
    updated_at          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP(),

    CONSTRAINT pk_orders PRIMARY KEY (order_id),
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id)
        REFERENCES CUSTOMERS (customer_id)
)
COMMENT = 'Customer orders for the e-commerce platform';

-- -----------------------------------------------------------
-- ORDER_ITEMS table (line items for each order)
-- -----------------------------------------------------------
CREATE OR REPLACE TABLE ORDER_ITEMS (
    order_item_id       INTEGER         NOT NULL,
    order_id            INTEGER         NOT NULL,
    product_id          INTEGER         NOT NULL,
    quantity            INTEGER         NOT NULL DEFAULT 1,
    unit_price          NUMBER(10,2)    NOT NULL,
    discount_pct        NUMBER(5,2)     DEFAULT 0.00,
    line_total          NUMBER(12,2)    NOT NULL,
    created_at          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP(),

    CONSTRAINT pk_order_items PRIMARY KEY (order_item_id),
    CONSTRAINT fk_order_items_order FOREIGN KEY (order_id)
        REFERENCES ORDERS (order_id),
    CONSTRAINT fk_order_items_product FOREIGN KEY (product_id)
        REFERENCES PRODUCTS (product_id)
)
COMMENT = 'Individual line items within each customer order';

-- Verify all four tables were created
SHOW TABLES IN SCHEMA WORKSHOP_DB.ANALYTICS;

-- ============================================================
-- STEP 4: Create transient and temporary tables
-- ============================================================

-- -----------------------------------------------------------
-- TRANSIENT TABLE
-- -----------------------------------------------------------
-- Transient tables have NO Fail-safe period (saves storage cost).
-- Time Travel is limited to 0 or 1 day.
-- Use for staging data, ETL intermediates, or data you can
-- easily reload from source.

USE SCHEMA WORKSHOP_DB.STAGING;

CREATE OR REPLACE TRANSIENT TABLE STG_CUSTOMER_IMPORT (
    raw_id              INTEGER         NOT NULL,
    raw_first_name      VARCHAR(100),
    raw_last_name       VARCHAR(100),
    raw_email           VARCHAR(200),
    raw_phone           VARCHAR(50),
    raw_address         VARCHAR(500),
    source_system       VARCHAR(50),
    load_timestamp      TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP(),
    is_processed        BOOLEAN         DEFAULT FALSE
)
DATA_RETENTION_TIME_IN_DAYS = 1     -- Max 1 day for transient tables
COMMENT = 'Transient staging table for customer data imports';

CREATE OR REPLACE TRANSIENT TABLE STG_ORDER_IMPORT (
    raw_id              INTEGER         NOT NULL,
    raw_customer_email  VARCHAR(200),
    raw_order_date      VARCHAR(50),
    raw_product_sku     VARCHAR(50),
    raw_quantity        VARCHAR(20),
    raw_price           VARCHAR(20),
    source_file         VARCHAR(200),
    load_timestamp      TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP(),
    is_processed        BOOLEAN         DEFAULT FALSE
)
DATA_RETENTION_TIME_IN_DAYS = 1
COMMENT = 'Transient staging table for order data imports';

-- Verify: notice the "kind" column shows TRANSIENT
SHOW TABLES IN SCHEMA WORKSHOP_DB.STAGING;

-- -----------------------------------------------------------
-- TEMPORARY TABLE
-- -----------------------------------------------------------
-- Temporary tables exist ONLY in the current session.
-- Other users/sessions cannot see them.
-- They are automatically dropped when the session ends.
-- Use for intermediate calculations, scratch work, or temp results.

CREATE OR REPLACE TEMPORARY TABLE TEMP_HIGH_VALUE_ORDERS (
    order_id            INTEGER,
    customer_id         INTEGER,
    total_amount        NUMBER(12,2),
    order_date          DATE
)
COMMENT = 'Temp table: high-value orders for current analysis session';

-- This table is visible in the current session
SHOW TABLES LIKE 'TEMP_%' IN SCHEMA WORKSHOP_DB.STAGING;

-- NOTE: If you open a NEW worksheet or session, this table
-- will NOT be visible. It vanishes when this session ends.

-- ============================================================
-- STEP 5: Insert sample data
-- ============================================================
-- Populate the e-commerce tables with realistic data.

USE SCHEMA WORKSHOP_DB.ANALYTICS;

-- -----------------------------------------------------------
-- Insert CUSTOMERS
-- -----------------------------------------------------------
INSERT INTO CUSTOMERS (customer_id, first_name, last_name, email, phone,
    date_of_birth, address_line1, city, state, zip_code, country, customer_segment)
VALUES
    (1001, 'Alice',   'Johnson',  'alice.johnson@example.com',  '555-0101',
     '1985-03-15', '123 Oak Street',     'Seattle',       'WA', '98101', 'US', 'PREMIUM'),
    (1002, 'Bob',     'Smith',    'bob.smith@example.com',      '555-0102',
     '1990-07-22', '456 Pine Avenue',    'Portland',      'OR', '97201', 'US', 'STANDARD'),
    (1003, 'Carol',   'Williams', 'carol.williams@example.com', '555-0103',
     '1978-11-08', '789 Elm Boulevard',  'San Francisco', 'CA', '94102', 'US', 'PREMIUM'),
    (1004, 'David',   'Brown',    'david.brown@example.com',    '555-0104',
     '1995-01-30', '321 Maple Drive',    'Denver',        'CO', '80201', 'US', 'STANDARD'),
    (1005, 'Eva',     'Davis',    'eva.davis@example.com',      '555-0105',
     '1988-06-17', '654 Cedar Lane',     'Austin',        'TX', '73301', 'US', 'PREMIUM'),
    (1006, 'Frank',   'Miller',   'frank.miller@example.com',   '555-0106',
     '1992-09-03', '987 Birch Court',    'Chicago',       'IL', '60601', 'US', 'STANDARD'),
    (1007, 'Grace',   'Wilson',   'grace.wilson@example.com',   '555-0107',
     '1983-12-25', '147 Walnut Way',     'New York',      'NY', '10001', 'US', 'PREMIUM'),
    (1008, 'Henry',   'Taylor',   'henry.taylor@example.com',   '555-0108',
     '1997-04-11', '258 Spruce Street',  'Miami',         'FL', '33101', 'US', 'STANDARD');

-- Verify
SELECT * FROM CUSTOMERS ORDER BY customer_id;

-- -----------------------------------------------------------
-- Insert PRODUCTS
-- -----------------------------------------------------------
INSERT INTO PRODUCTS (product_id, product_name, category, subcategory, brand,
    unit_price, cost_price, weight_kg, description, sku, inventory_qty, attributes)
VALUES
    (2001, 'Wireless Bluetooth Headphones', 'Electronics', 'Audio',       'SoundMax',
     79.99,  35.00, 0.25, 'Over-ear wireless headphones with noise cancellation',
     'ELEC-AUD-001', 150,
     PARSE_JSON('{"color":"black","battery_hours":30,"bluetooth":"5.2","noise_cancel":true}')),

    (2002, 'Organic Cotton T-Shirt',        'Clothing',    'Tops',        'EcoWear',
     29.99,  12.00, 0.20, '100% organic cotton crew neck t-shirt',
     'CLTH-TOP-001', 500,
     PARSE_JSON('{"sizes":["S","M","L","XL"],"colors":["white","black","navy"],"material":"organic_cotton"}')),

    (2003, 'Stainless Steel Water Bottle',  'Home',        'Kitchen',     'HydroLife',
     24.99,  8.50,  0.35, 'Double-wall insulated 750ml water bottle',
     'HOME-KIT-001', 300,
     PARSE_JSON('{"capacity_ml":750,"insulated":true,"material":"stainless_steel","colors":["silver","blue","green"]}')),

    (2004, 'Running Shoes Pro',             'Footwear',    'Athletic',    'SprintFlex',
     129.99, 55.00, 0.65, 'Lightweight running shoes with cushioned sole',
     'FOOT-ATH-001', 200,
     PARSE_JSON('{"sizes":[7,8,9,10,11,12],"colors":["red","blue","black"],"sole_type":"cushion"}')),

    (2005, 'Laptop Backpack',               'Accessories', 'Bags',        'TrekGear',
     59.99,  22.00, 0.90, 'Water-resistant backpack with laptop compartment up to 15.6 inches',
     'ACCS-BAG-001', 250,
     PARSE_JSON('{"laptop_max_inches":15.6,"water_resistant":true,"pockets":6,"color":"charcoal"}')),

    (2006, 'Ceramic Coffee Mug Set',        'Home',        'Kitchen',     'CraftHome',
     34.99,  14.00, 1.20, 'Set of 4 handcrafted ceramic mugs, 350ml each',
     'HOME-KIT-002', 180,
     PARSE_JSON('{"set_count":4,"capacity_ml":350,"dishwasher_safe":true,"material":"ceramic"}')),

    (2007, 'Yoga Mat Premium',              'Sports',      'Fitness',     'ZenFit',
     49.99,  18.00, 1.80, 'Non-slip premium yoga mat, 6mm thick, with carrying strap',
     'SPRT-FIT-001', 120,
     PARSE_JSON('{"thickness_mm":6,"material":"TPE","length_cm":183,"width_cm":61}')),

    (2008, 'Wireless Phone Charger',        'Electronics', 'Accessories', 'ChargePad',
     19.99,  7.00,  0.15, 'Qi-compatible fast wireless charging pad, 15W',
     'ELEC-ACC-001', 400,
     PARSE_JSON('{"wattage":15,"qi_compatible":true,"cable_included":true,"color":"white"}'));

-- Verify
SELECT product_id, product_name, category, unit_price, sku, inventory_qty
FROM PRODUCTS
ORDER BY product_id;

-- -----------------------------------------------------------
-- Insert ORDERS
-- -----------------------------------------------------------
INSERT INTO ORDERS (order_id, customer_id, order_date, order_status, shipping_method,
    shipping_address, subtotal, tax_amount, shipping_cost, total_amount, payment_method)
VALUES
    (5001, 1001, '2025-01-10', 'DELIVERED',  'EXPRESS',
     '123 Oak Street, Seattle, WA 98101',
     139.98, 11.55, 9.99,  161.52, 'CREDIT_CARD'),

    (5002, 1002, '2025-01-12', 'DELIVERED',  'STANDARD',
     '456 Pine Avenue, Portland, OR 97201',
     29.99,  2.40,  5.99,  38.38,  'PAYPAL'),

    (5003, 1003, '2025-01-15', 'SHIPPED',    'EXPRESS',
     '789 Elm Boulevard, San Francisco, CA 94102',
     214.97, 18.97, 0.00,  233.94, 'CREDIT_CARD'),

    (5004, 1001, '2025-01-18', 'SHIPPED',    'STANDARD',
     '123 Oak Street, Seattle, WA 98101',
     59.99,  4.95,  5.99,  70.93,  'CREDIT_CARD'),

    (5005, 1005, '2025-01-20', 'PROCESSING', 'EXPRESS',
     '654 Cedar Lane, Austin, TX 73301',
     179.98, 14.85, 0.00,  194.83, 'DEBIT_CARD'),

    (5006, 1004, '2025-01-22', 'PENDING',    'STANDARD',
     '321 Maple Drive, Denver, CO 80201',
     49.99,  3.50,  5.99,  59.48,  'PAYPAL'),

    (5007, 1007, '2025-01-25', 'DELIVERED',  'EXPRESS',
     '147 Walnut Way, New York, NY 10001',
     109.98, 9.77,  0.00,  119.75, 'CREDIT_CARD'),

    (5008, 1003, '2025-01-28', 'PROCESSING', 'STANDARD',
     '789 Elm Boulevard, San Francisco, CA 94102',
     84.98,  7.44,  5.99,  98.41,  'CREDIT_CARD'),

    (5009, 1006, '2025-02-01', 'PENDING',    'STANDARD',
     '987 Birch Court, Chicago, IL 60601',
     24.99,  2.19,  5.99,  33.17,  'DEBIT_CARD'),

    (5010, 1008, '2025-02-03', 'PROCESSING', 'EXPRESS',
     '258 Spruce Street, Miami, FL 33101',
     159.98, 11.20, 0.00,  171.18, 'PAYPAL');

-- Verify
SELECT order_id, customer_id, order_date, order_status, total_amount
FROM ORDERS
ORDER BY order_id;

-- -----------------------------------------------------------
-- Insert ORDER_ITEMS
-- -----------------------------------------------------------
INSERT INTO ORDER_ITEMS (order_item_id, order_id, product_id, quantity, unit_price, discount_pct, line_total)
VALUES
    -- Order 5001: Alice bought headphones + t-shirt
    (9001, 5001, 2001, 1, 79.99, 0.00,  79.99),
    (9002, 5001, 2002, 2, 29.99, 0.00,  59.98),

    -- Order 5002: Bob bought a t-shirt
    (9003, 5002, 2002, 1, 29.99, 0.00,  29.99),

    -- Order 5003: Carol bought running shoes + backpack + water bottle
    (9004, 5003, 2004, 1, 129.99, 0.00, 129.99),
    (9005, 5003, 2005, 1, 59.99,  0.00, 59.99),
    (9006, 5003, 2003, 1, 24.99,  0.00, 24.99),

    -- Order 5004: Alice bought a backpack
    (9007, 5004, 2005, 1, 59.99,  0.00, 59.99),

    -- Order 5005: Eva bought running shoes + yoga mat
    (9008, 5005, 2004, 1, 129.99, 0.00, 129.99),
    (9009, 5005, 2007, 1, 49.99,  0.00, 49.99),

    -- Order 5006: David bought a yoga mat
    (9010, 5006, 2007, 1, 49.99,  0.00, 49.99),

    -- Order 5007: Grace bought headphones + charger + t-shirt
    (9011, 5007, 2001, 1, 79.99,  0.00, 79.99),
    (9012, 5007, 2008, 1, 19.99,  0.00, 19.99),
    (9013, 5007, 2002, 1, 29.99, 20.00, 23.99),   -- 20% discount!

    -- Order 5008: Carol bought mug set + water bottle
    (9014, 5008, 2006, 1, 34.99,  0.00, 34.99),
    (9015, 5008, 2003, 2, 24.99,  0.00, 49.98),

    -- Order 5009: Frank bought a water bottle
    (9016, 5009, 2003, 1, 24.99,  0.00, 24.99),

    -- Order 5010: Henry bought running shoes + charger
    (9017, 5010, 2004, 1, 129.99, 0.00, 129.99),
    (9018, 5010, 2008, 1, 19.99, 0.00,  19.99);

-- Verify: check a few orders
SELECT oi.order_id, p.product_name, oi.quantity, oi.unit_price, oi.discount_pct, oi.line_total
FROM ORDER_ITEMS oi
JOIN PRODUCTS p ON oi.product_id = p.product_id
ORDER BY oi.order_id, oi.order_item_id;

-- -----------------------------------------------------------
-- Insert sample staging data
-- -----------------------------------------------------------
USE SCHEMA WORKSHOP_DB.STAGING;

INSERT INTO STG_CUSTOMER_IMPORT (raw_id, raw_first_name, raw_last_name, raw_email, raw_phone, raw_address, source_system)
VALUES
    (1, 'ian',     'MARTINEZ',  'Ian.Martinez@Example.COM',   '(555) 0109',  '369 Aspen Rd, Boston MA 02101',     'WEBSITE'),
    (2, 'JULIA',   'anderson',  'julia.anderson@example.com', '555.0110',    '741 Hickory Pl, Phoenix AZ 85001',  'MOBILE_APP'),
    (3, 'kevin',   'Thomas',    'KEVIN.THOMAS@EXAMPLE.COM',   '555 0111',    '852 Poplar Ave, Nashville TN 37201','IMPORT_CSV');

-- ============================================================
-- STEP 6: Create views and secure views
-- ============================================================

USE SCHEMA WORKSHOP_DB.ANALYTICS;

-- -----------------------------------------------------------
-- Standard View: Customer Order Summary
-- -----------------------------------------------------------
-- A view is a saved query that acts like a virtual table.
-- It does NOT store data -- it runs the query every time.

CREATE OR REPLACE VIEW V_CUSTOMER_ORDER_SUMMARY AS
SELECT
    c.customer_id,
    c.first_name || ' ' || c.last_name         AS customer_name,
    c.email,
    c.customer_segment,
    COUNT(o.order_id)                           AS total_orders,
    COALESCE(SUM(o.total_amount), 0)            AS lifetime_spend,
    COALESCE(AVG(o.total_amount), 0)            AS avg_order_value,
    MIN(o.order_date)                           AS first_order_date,
    MAX(o.order_date)                           AS last_order_date
FROM CUSTOMERS c
LEFT JOIN ORDERS o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.email, c.customer_segment;

-- Query the view just like a table
SELECT * FROM V_CUSTOMER_ORDER_SUMMARY
ORDER BY lifetime_spend DESC;

-- -----------------------------------------------------------
-- Standard View: Product Sales Performance
-- -----------------------------------------------------------
CREATE OR REPLACE VIEW V_PRODUCT_SALES AS
SELECT
    p.product_id,
    p.product_name,
    p.category,
    p.subcategory,
    p.unit_price                                AS current_price,
    p.cost_price,
    COUNT(DISTINCT oi.order_id)                 AS times_ordered,
    SUM(oi.quantity)                             AS total_units_sold,
    SUM(oi.line_total)                          AS total_revenue,
    SUM(oi.line_total) - (SUM(oi.quantity) * p.cost_price) AS estimated_profit,
    p.inventory_qty                             AS current_stock
FROM PRODUCTS p
LEFT JOIN ORDER_ITEMS oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, p.category, p.subcategory,
         p.unit_price, p.cost_price, p.inventory_qty;

SELECT * FROM V_PRODUCT_SALES ORDER BY total_revenue DESC;

-- -----------------------------------------------------------
-- Standard View: Order Details (flattened)
-- -----------------------------------------------------------
CREATE OR REPLACE VIEW V_ORDER_DETAILS AS
SELECT
    o.order_id,
    o.order_date,
    o.order_status,
    c.first_name || ' ' || c.last_name     AS customer_name,
    c.email                                 AS customer_email,
    p.product_name,
    p.category                              AS product_category,
    oi.quantity,
    oi.unit_price,
    oi.discount_pct,
    oi.line_total,
    o.shipping_method,
    o.total_amount                          AS order_total
FROM ORDERS o
JOIN CUSTOMERS c    ON o.customer_id = c.customer_id
JOIN ORDER_ITEMS oi ON o.order_id = oi.order_id
JOIN PRODUCTS p     ON oi.product_id = p.product_id;

SELECT * FROM V_ORDER_DETAILS ORDER BY order_id, product_name;

-- -----------------------------------------------------------
-- Secure View: Customer PII (Personally Identifiable Info)
-- -----------------------------------------------------------
-- A SECURE view hides its SQL definition from unauthorized users.
-- This is critical when:
--   1. The view filters rows (row-level security)
--   2. The view exposes sensitive data
--   3. You are sharing data across accounts

CREATE OR REPLACE SECURE VIEW V_SECURE_CUSTOMER_DIRECTORY AS
SELECT
    customer_id,
    first_name,
    SUBSTR(last_name, 1, 1) || '***'       AS last_name_masked,
    REGEXP_REPLACE(email, '(.{2}).*(@.*)', '\\1***\\2')  AS email_masked,
    city,
    state,
    customer_segment,
    is_active
FROM CUSTOMERS;

-- The secure view masks sensitive data
SELECT * FROM V_SECURE_CUSTOMER_DIRECTORY ORDER BY customer_id;

-- Compare: you can see the definition of a standard view...
SHOW VIEWS LIKE 'V_CUSTOMER_ORDER_SUMMARY' IN SCHEMA WORKSHOP_DB.ANALYTICS;

-- ...but a secure view's definition is hidden from non-owners
SHOW VIEWS LIKE 'V_SECURE_%' IN SCHEMA WORKSHOP_DB.ANALYTICS;

-- ============================================================
-- STEP 7: Use DESCRIBE and SHOW commands
-- ============================================================
-- These metadata commands help you explore your objects.

-- -----------------------------------------------------------
-- SHOW commands: list objects
-- -----------------------------------------------------------

-- Show all databases you have access to
SHOW DATABASES LIKE 'WORKSHOP%';

-- Show schemas within a specific database
SHOW SCHEMAS IN DATABASE WORKSHOP_DB;

-- Show all tables in a schema
SHOW TABLES IN SCHEMA WORKSHOP_DB.ANALYTICS;

-- Show all views in a schema
SHOW VIEWS IN SCHEMA WORKSHOP_DB.ANALYTICS;

-- Show tables across ALL schemas in the database
SHOW TABLES IN DATABASE WORKSHOP_DB;

-- Filter with LIKE pattern matching
SHOW TABLES LIKE 'ORDER%' IN SCHEMA WORKSHOP_DB.ANALYTICS;

-- -----------------------------------------------------------
-- DESCRIBE commands: inspect structure
-- -----------------------------------------------------------

-- Describe a table's columns, types, and constraints
DESCRIBE TABLE WORKSHOP_DB.ANALYTICS.CUSTOMERS;

-- Describe a view (shows the output columns)
DESCRIBE VIEW WORKSHOP_DB.ANALYTICS.V_CUSTOMER_ORDER_SUMMARY;

-- Shorthand: DESC works the same as DESCRIBE
DESC TABLE WORKSHOP_DB.ANALYTICS.ORDERS;

-- -----------------------------------------------------------
-- Fully qualified names: DATABASE.SCHEMA.OBJECT
-- -----------------------------------------------------------

-- You can always reference any object with its full path
SELECT COUNT(*) AS total_customers FROM WORKSHOP_DB.ANALYTICS.CUSTOMERS;
SELECT COUNT(*) AS total_products  FROM WORKSHOP_DB.ANALYTICS.PRODUCTS;
SELECT COUNT(*) AS total_orders    FROM WORKSHOP_DB.ANALYTICS.ORDERS;
SELECT COUNT(*) AS total_items     FROM WORKSHOP_DB.ANALYTICS.ORDER_ITEMS;

-- ============================================================
-- STEP 8: Alter tables and clean up
-- ============================================================

USE SCHEMA WORKSHOP_DB.ANALYTICS;

-- -----------------------------------------------------------
-- ALTER TABLE: Add columns
-- -----------------------------------------------------------

-- Add a loyalty_points column to CUSTOMERS
ALTER TABLE CUSTOMERS ADD COLUMN loyalty_points INTEGER DEFAULT 0;

-- Add a rating column to PRODUCTS
ALTER TABLE PRODUCTS ADD COLUMN avg_rating NUMBER(3,2);

-- Verify the new columns exist
DESC TABLE CUSTOMERS;
DESC TABLE PRODUCTS;

-- Update the new columns with some data
UPDATE CUSTOMERS SET loyalty_points = total_amount * 10
FROM (
    SELECT customer_id AS cid, SUM(total_amount) AS total_amount
    FROM ORDERS
    GROUP BY customer_id
) sub
WHERE CUSTOMERS.customer_id = sub.cid;

UPDATE PRODUCTS SET avg_rating = rating
FROM (
    SELECT product_id AS pid, ROUND(3.5 + RANDOM() / POWER(10, 18) * 1.5, 2) AS rating
    FROM PRODUCTS
) sub
WHERE PRODUCTS.product_id = sub.pid;

SELECT customer_id, first_name, last_name, loyalty_points FROM CUSTOMERS ORDER BY loyalty_points DESC;
SELECT product_id, product_name, avg_rating FROM PRODUCTS ORDER BY avg_rating DESC;

-- -----------------------------------------------------------
-- ALTER TABLE: Rename a column
-- -----------------------------------------------------------

-- Rename shipping_method to delivery_method in ORDERS
ALTER TABLE ORDERS RENAME COLUMN shipping_method TO delivery_method;

-- Verify
DESC TABLE ORDERS;

-- -----------------------------------------------------------
-- ALTER TABLE: Drop a column
-- -----------------------------------------------------------

-- Suppose we no longer need the notes column on ORDERS
ALTER TABLE ORDERS DROP COLUMN notes;

-- Verify it is gone
DESC TABLE ORDERS;

-- -----------------------------------------------------------
-- ALTER TABLE: Rename a table
-- -----------------------------------------------------------

-- Rename for clarity (then rename back)
ALTER TABLE PRODUCTS RENAME TO PRODUCT_CATALOG;

-- Verify
SHOW TABLES LIKE 'PRODUCT%' IN SCHEMA WORKSHOP_DB.ANALYTICS;

-- Rename back to original
ALTER TABLE PRODUCT_CATALOG RENAME TO PRODUCTS;

-- -----------------------------------------------------------
-- Clean up: Drop the data types reference table
-- -----------------------------------------------------------
DROP TABLE IF EXISTS WORKSHOP_DB.RAW.DATA_TYPES_REFERENCE;

-- Verify it is gone
SHOW TABLES IN SCHEMA WORKSHOP_DB.RAW;

-- NOTE: We keep WORKSHOP_DB and its tables for future labs.
-- The temporary table (TEMP_HIGH_VALUE_ORDERS) will vanish
-- automatically when your session ends.

-- ============================================================
-- CONGRATULATIONS! You have completed Lab 03!
-- You now know how to create and manage databases, schemas,
-- tables (permanent, transient, temporary), and views.
-- Move on to Lab 04: Loading Data
-- ============================================================
