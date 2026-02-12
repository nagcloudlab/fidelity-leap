/***********************************************************************
  LAB 15: CAPSTONE PROJECT -- E-COMMERCE ANALYTICS PIPELINE
  =========================================================

  Build a complete end-to-end data pipeline combining ALL concepts
  from the Snowflake Workshop (Labs 01-14).

  Workshop Concepts Applied:
    - Lab 01: Virtual Warehouses
    - Lab 02: DDL & DML (databases, schemas, tables)
    - Lab 03: Data Loading (INSERT statements)
    - Lab 04: Querying (joins, subqueries)
    - Lab 05: Functions (aggregations, window functions)
    - Lab 06: Semi-Structured Data (VARIANT, JSON)
    - Lab 07: RBAC (roles, grants)
    - Lab 08: Time Travel & Cloning
    - Lab 09: Streams & Tasks
    - Lab 10: Stored Procedures
    - Lab 11: UDFs
    - Lab 12: Data Sharing (secure views)
    - Lab 13: Dynamic Tables
    - Lab 14: Performance Tuning (clustering)

  Architecture: BRONZE (raw) -> SILVER (clean) -> GOLD (analytics)
  Duration: ~45 minutes
***********************************************************************/


-- =====================================================================
-- SECTION 1: FOUNDATION -- DATABASE, SCHEMAS, AND WAREHOUSE
-- Concepts: Lab 01 (Warehouses), Lab 02 (DDL)
-- =====================================================================

-- Use the SYSADMIN role for creating data objects
USE ROLE SYSADMIN;

-- Create a warehouse for pipeline processing
CREATE OR REPLACE WAREHOUSE ECOMMERCE_WH
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 120
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Warehouse for e-commerce analytics pipeline';

USE WAREHOUSE ECOMMERCE_WH;

-- Create the data warehouse database
CREATE OR REPLACE DATABASE ECOMMERCE_DW
    COMMENT = 'E-commerce data warehouse with Bronze/Silver/Gold architecture';

-- Create schemas for the medallion architecture
-- BRONZE: Raw data exactly as received from source systems
CREATE OR REPLACE SCHEMA ECOMMERCE_DW.BRONZE
    COMMENT = 'Raw data layer - data as received from source systems';

-- SILVER: Cleaned, validated, and conformed data
CREATE OR REPLACE SCHEMA ECOMMERCE_DW.SILVER
    COMMENT = 'Clean data layer - validated, conformed, and deduplicated';

-- GOLD: Aggregated, business-ready analytics
CREATE OR REPLACE SCHEMA ECOMMERCE_DW.GOLD
    COMMENT = 'Analytics layer - aggregated and business-ready data';

-- Verify the structure
SHOW SCHEMAS IN DATABASE ECOMMERCE_DW;


-- =====================================================================
-- SECTION 2: RAW TABLES IN BRONZE
-- Concepts: Lab 02 (DDL), Lab 06 (Semi-Structured Data - VARIANT)
-- =====================================================================

USE SCHEMA ECOMMERCE_DW.BRONZE;

-- Customers table with a VARIANT column for semi-structured address data
-- Real-world systems often send nested JSON for address fields
CREATE OR REPLACE TABLE RAW_CUSTOMERS (
    CUSTOMER_ID     INTEGER,
    FIRST_NAME      VARCHAR(50),
    LAST_NAME       VARCHAR(50),
    EMAIL           VARCHAR(100),
    PHONE           VARCHAR(20),
    ADDRESS         VARIANT,          -- Semi-structured JSON (Lab 06)
    SIGNUP_DATE     DATE,
    IS_ACTIVE       BOOLEAN,
    LOADED_AT       TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Products table with standard relational columns
CREATE OR REPLACE TABLE RAW_PRODUCTS (
    PRODUCT_ID      INTEGER,
    PRODUCT_NAME    VARCHAR(200),
    CATEGORY        VARCHAR(50),
    SUBCATEGORY     VARCHAR(50),
    UNIT_PRICE      NUMBER(10,2),
    STOCK_QUANTITY  INTEGER,
    WEIGHT_KG       NUMBER(6,2),
    IS_AVAILABLE    BOOLEAN,
    LOADED_AT       TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Orders header table
CREATE OR REPLACE TABLE RAW_ORDERS (
    ORDER_ID        INTEGER,
    CUSTOMER_ID     INTEGER,
    ORDER_DATE      DATE,
    ORDER_STATUS    VARCHAR(20),
    SHIPPING_METHOD VARCHAR(30),
    PAYMENT_METHOD  VARCHAR(30),
    NOTES           VARCHAR(500),
    LOADED_AT       TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Order line items (detail-level)
CREATE OR REPLACE TABLE RAW_ORDER_ITEMS (
    ORDER_ITEM_ID   INTEGER,
    ORDER_ID        INTEGER,
    PRODUCT_ID      INTEGER,
    QUANTITY         INTEGER,
    UNIT_PRICE      NUMBER(10,2),
    DISCOUNT_PCT    NUMBER(5,2) DEFAULT 0.00,
    LOADED_AT       TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);


-- =====================================================================
-- SECTION 3: LOAD SAMPLE DATA INTO BRONZE
-- Concepts: Lab 03 (Data Loading), Lab 06 (PARSE_JSON for JSON data)
-- =====================================================================

-- -------------------------------------------------------
-- 3a. Insert 25 customers with JSON address objects
-- -------------------------------------------------------
INSERT INTO RAW_CUSTOMERS (CUSTOMER_ID, FIRST_NAME, LAST_NAME, EMAIL, PHONE, ADDRESS, SIGNUP_DATE, IS_ACTIVE)
VALUES
    (1,  'Alice',    'Johnson',   'alice.johnson@email.com',    '555-0101', PARSE_JSON('{"street":"123 Oak Ave","city":"Denver","state":"CO","zip":"80201"}'),         '2024-01-15', TRUE),
    (2,  'Bob',      'Smith',     'Bob.Smith@Email.COM',        '555-0102', PARSE_JSON('{"street":"456 Pine St","city":"Boulder","state":"CO","zip":"80301"}'),        '2024-01-20', TRUE),
    (3,  'Carol',    'Williams',  'carol.w@email.com',          '555-0103', PARSE_JSON('{"street":"789 Elm Dr","city":"Austin","state":"TX","zip":"73301"}'),          '2024-02-01', TRUE),
    (4,  'David',    'Brown',     'DAVID.BROWN@email.com',      '555-0104', PARSE_JSON('{"street":"321 Maple Ln","city":"Portland","state":"OR","zip":"97201"}'),      '2024-02-10', TRUE),
    (5,  'Emma',     'Davis',     'emma.davis@email.com',        '555-0105', PARSE_JSON('{"street":"654 Cedar Ct","city":"Seattle","state":"WA","zip":"98101"}'),       '2024-02-15', TRUE),
    (6,  'Frank',    'Miller',    'Frank.Miller@email.com',      '555-0106', PARSE_JSON('{"street":"987 Birch Way","city":"San Francisco","state":"CA","zip":"94101"}'),'2024-03-01', TRUE),
    (7,  'Grace',    'Wilson',    'grace.wilson@email.com',      '555-0107', PARSE_JSON('{"street":"147 Spruce Rd","city":"Los Angeles","state":"CA","zip":"90001"}'),  '2024-03-05', TRUE),
    (8,  'Henry',    'Moore',     'henry.moore@email.com',       '555-0108', PARSE_JSON('{"street":"258 Aspen Blvd","city":"Phoenix","state":"AZ","zip":"85001"}'),     '2024-03-10', TRUE),
    (9,  'Iris',     'Taylor',    'IRIS.TAYLOR@email.com',       '555-0109', PARSE_JSON('{"street":"369 Walnut St","city":"Salt Lake City","state":"UT","zip":"84101"}'),'2024-03-15', TRUE),
    (10, 'Jack',     'Anderson',  'jack.anderson@email.com',     '555-0110', PARSE_JSON('{"street":"480 Poplar Ave","city":"Boise","state":"ID","zip":"83701"}'),       '2024-03-20', TRUE),
    (11, 'Karen',    'Thomas',    'karen.thomas@email.com',      '555-0111', PARSE_JSON('{"street":"591 Hickory Ln","city":"Reno","state":"NV","zip":"89501"}'),        '2024-04-01', TRUE),
    (12, 'Leo',      'Jackson',   'Leo.Jackson@Email.com',       '555-0112', PARSE_JSON('{"street":"602 Sycamore Dr","city":"Tucson","state":"AZ","zip":"85701"}'),     '2024-04-05', TRUE),
    (13, 'Mia',      'White',     'mia.white@email.com',         '555-0113', PARSE_JSON('{"street":"713 Cypress St","city":"Albuquerque","state":"NM","zip":"87101"}'),  '2024-04-10', TRUE),
    (14, 'Nathan',   'Harris',    'nathan.harris@email.com',     '555-0114', PARSE_JSON('{"street":"824 Magnolia Ct","city":"Las Vegas","state":"NV","zip":"89101"}'),   '2024-04-15', TRUE),
    (15, 'Olivia',   'Martin',    'OLIVIA.MARTIN@email.com',     '555-0115', PARSE_JSON('{"street":"935 Dogwood Way","city":"Sacramento","state":"CA","zip":"95801"}'),  '2024-04-20', TRUE),
    (16, 'Paul',     'Garcia',    'paul.garcia@email.com',       '555-0116', PARSE_JSON('{"street":"146 Redwood Blvd","city":"Eugene","state":"OR","zip":"97401"}'),     '2024-05-01', TRUE),
    (17, 'Quinn',    'Martinez',  'quinn.martinez@email.com',    '555-0117', PARSE_JSON('{"street":"257 Juniper Rd","city":"Spokane","state":"WA","zip":"99201"}'),      '2024-05-05', TRUE),
    (18, 'Rachel',   'Robinson',  'Rachel.Robinson@email.com',   '555-0118', PARSE_JSON('{"street":"368 Hemlock Ave","city":"Missoula","state":"MT","zip":"59801"}'),    '2024-05-10', TRUE),
    (19, 'Sam',      'Clark',     'sam.clark@email.com',         '555-0119', PARSE_JSON('{"street":"479 Alder St","city":"Flagstaff","state":"AZ","zip":"86001"}'),      '2024-05-15', TRUE),
    (20, 'Tina',     'Rodriguez', 'tina.rodriguez@email.com',    '555-0120', PARSE_JSON('{"street":"580 Willow Ln","city":"Bend","state":"OR","zip":"97701"}'),          '2024-05-20', TRUE),
    (21, 'Uma',      'Lewis',     'uma.lewis@email.com',         '555-0121', PARSE_JSON('{"street":"691 Chestnut Dr","city":"Fort Collins","state":"CO","zip":"80521"}'),'2024-06-01', TRUE),
    (22, 'Victor',   'Lee',       'VICTOR.LEE@email.com',        '555-0122', PARSE_JSON('{"street":"702 Fir Ct","city":"Bozeman","state":"MT","zip":"59715"}'),          '2024-06-05', TRUE),
    (23, 'Wendy',    'Walker',    'wendy.walker@email.com',      '555-0123', PARSE_JSON('{"street":"813 Sequoia Way","city":"Durango","state":"CO","zip":"81301"}'),     '2024-06-10', TRUE),
    (24, 'Xavier',   'Hall',      'xavier.hall@email.com',       '555-0124', PARSE_JSON('{"street":"924 Palm Blvd","city":"Moab","state":"UT","zip":"84532"}'),          '2024-06-15', FALSE),
    (25, 'Yara',     'Allen',     'yara.allen@email.com',        '555-0125', PARSE_JSON('{"street":"135 Olive Rd","city":"Sedona","state":"AZ","zip":"86336"}'),         '2024-06-20', TRUE);

-- Verify customer data and examine JSON structure
SELECT CUSTOMER_ID, FIRST_NAME, LAST_NAME, EMAIL,
       ADDRESS:street::STRING AS street,
       ADDRESS:city::STRING   AS city,
       ADDRESS:state::STRING  AS state,
       ADDRESS:zip::STRING    AS zip
FROM RAW_CUSTOMERS
LIMIT 5;


-- -------------------------------------------------------
-- 3b. Insert 18 products across outdoor categories
-- -------------------------------------------------------
INSERT INTO RAW_PRODUCTS (PRODUCT_ID, PRODUCT_NAME, CATEGORY, SUBCATEGORY, UNIT_PRICE, STOCK_QUANTITY, WEIGHT_KG, IS_AVAILABLE)
VALUES
    (101, 'Trail Blazer Hiking Boots',       'Hiking',        'Footwear',     149.99, 200, 1.20, TRUE),
    (102, 'Summit Pack 45L Backpack',        'Hiking',        'Packs',        129.99, 150, 1.50, TRUE),
    (103, 'PathFinder Trekking Poles',       'Hiking',        'Accessories',   59.99, 300, 0.55, TRUE),
    (104, 'Alpine Glow 3-Season Tent',       'Camping',       'Shelters',     279.99, 100, 2.80, TRUE),
    (105, 'DreamRest Sleeping Bag 20F',      'Camping',       'Sleep Systems', 189.99,  80, 1.60, TRUE),
    (106, 'CampChef Portable Stove',         'Camping',       'Cooking',       89.99, 250, 0.90, TRUE),
    (107, 'LED Lantern Pro 800',             'Camping',       'Lighting',      34.99, 400, 0.30, TRUE),
    (108, 'Vertical Ascent Climbing Harness', 'Climbing',     'Harnesses',    119.99, 120, 0.45, TRUE),
    (109, 'GripMaster Climbing Shoes',       'Climbing',      'Footwear',     159.99,  90, 0.70, TRUE),
    (110, 'DynaRope 60m Climbing Rope',      'Climbing',      'Ropes',        199.99,  60, 3.80, TRUE),
    (111, 'AquaGlide Kayak Paddle',          'Water Sports',  'Paddles',       89.99, 175, 0.85, TRUE),
    (112, 'RiverRunner PFD Life Vest',       'Water Sports',  'Safety',        74.99, 200, 0.60, TRUE),
    (113, 'WaveRider Dry Bag 30L',           'Water Sports',  'Storage',       39.99, 350, 0.25, TRUE),
    (114, 'PowderKing Ski Jacket',           'Winter Sports', 'Apparel',      249.99, 130, 0.80, TRUE),
    (115, 'BlizzardShield Snow Goggles',     'Winter Sports', 'Eyewear',       79.99, 220, 0.20, TRUE),
    (116, 'FrostGuard Insulated Gloves',     'Winter Sports', 'Accessories',   49.99, 280, 0.15, TRUE),
    (117, 'ThermoFlask Water Bottle 32oz',   'Hiking',        'Hydration',     29.99, 500, 0.35, TRUE),
    (118, 'HeadBeam 500 Headlamp',           'Camping',       'Lighting',      44.99, 320, 0.12, TRUE);


-- -------------------------------------------------------
-- 3c. Insert 55 orders spanning multiple months
-- -------------------------------------------------------
INSERT INTO RAW_ORDERS (ORDER_ID, CUSTOMER_ID, ORDER_DATE, ORDER_STATUS, SHIPPING_METHOD, PAYMENT_METHOD, NOTES)
VALUES
    (1001, 1,  '2024-03-01', 'COMPLETED', 'Standard',  'Credit Card', NULL),
    (1002, 2,  '2024-03-03', 'COMPLETED', 'Express',   'PayPal',      NULL),
    (1003, 3,  '2024-03-05', 'COMPLETED', 'Standard',  'Credit Card', NULL),
    (1004, 4,  '2024-03-08', 'COMPLETED', 'Standard',  'Debit Card',  NULL),
    (1005, 5,  '2024-03-10', 'COMPLETED', 'Express',   'Credit Card', 'Gift wrap requested'),
    (1006, 6,  '2024-03-12', 'COMPLETED', 'Standard',  'PayPal',      NULL),
    (1007, 7,  '2024-03-15', 'COMPLETED', 'Overnight', 'Credit Card', NULL),
    (1008, 8,  '2024-03-18', 'COMPLETED', 'Standard',  'Credit Card', NULL),
    (1009, 9,  '2024-03-20', 'COMPLETED', 'Express',   'Debit Card',  NULL),
    (1010, 10, '2024-03-22', 'COMPLETED', 'Standard',  'PayPal',      NULL),
    (1011, 1,  '2024-04-01', 'COMPLETED', 'Express',   'Credit Card', 'Repeat customer'),
    (1012, 11, '2024-04-03', 'COMPLETED', 'Standard',  'Credit Card', NULL),
    (1013, 12, '2024-04-05', 'COMPLETED', 'Standard',  'PayPal',      NULL),
    (1014, 2,  '2024-04-08', 'COMPLETED', 'Standard',  'Credit Card', NULL),
    (1015, 13, '2024-04-10', 'COMPLETED', 'Express',   'Credit Card', NULL),
    (1016, 14, '2024-04-12', 'COMPLETED', 'Standard',  'Debit Card',  NULL),
    (1017, 3,  '2024-04-15', 'COMPLETED', 'Standard',  'Credit Card', NULL),
    (1018, 15, '2024-04-18', 'COMPLETED', 'Express',   'PayPal',      NULL),
    (1019, 5,  '2024-04-20', 'COMPLETED', 'Standard',  'Credit Card', NULL),
    (1020, 16, '2024-04-22', 'COMPLETED', 'Standard',  'Credit Card', NULL),
    (1021, 17, '2024-05-01', 'COMPLETED', 'Express',   'PayPal',      NULL),
    (1022, 1,  '2024-05-03', 'COMPLETED', 'Standard',  'Credit Card', 'Third order'),
    (1023, 18, '2024-05-05', 'COMPLETED', 'Standard',  'Credit Card', NULL),
    (1024, 19, '2024-05-08', 'COMPLETED', 'Overnight', 'Debit Card',  'Rush delivery'),
    (1025, 20, '2024-05-10', 'COMPLETED', 'Standard',  'PayPal',      NULL),
    (1026, 4,  '2024-05-12', 'COMPLETED', 'Express',   'Credit Card', NULL),
    (1027, 6,  '2024-05-15', 'COMPLETED', 'Standard',  'Credit Card', NULL),
    (1028, 21, '2024-05-18', 'COMPLETED', 'Standard',  'PayPal',      NULL),
    (1029, 22, '2024-05-20', 'COMPLETED', 'Express',   'Credit Card', NULL),
    (1030, 7,  '2024-05-22', 'COMPLETED', 'Standard',  'Debit Card',  NULL),
    (1031, 23, '2024-06-01', 'COMPLETED', 'Standard',  'Credit Card', NULL),
    (1032, 8,  '2024-06-03', 'COMPLETED', 'Express',   'Credit Card', NULL),
    (1033, 25, '2024-06-05', 'COMPLETED', 'Standard',  'PayPal',      NULL),
    (1034, 9,  '2024-06-08', 'COMPLETED', 'Standard',  'Credit Card', NULL),
    (1035, 10, '2024-06-10', 'COMPLETED', 'Express',   'Debit Card',  NULL),
    (1036, 2,  '2024-06-12', 'COMPLETED', 'Standard',  'Credit Card', NULL),
    (1037, 11, '2024-06-15', 'COMPLETED', 'Overnight', 'PayPal',      NULL),
    (1038, 3,  '2024-06-18', 'COMPLETED', 'Standard',  'Credit Card', NULL),
    (1039, 12, '2024-06-20', 'COMPLETED', 'Express',   'Credit Card', NULL),
    (1040, 5,  '2024-06-22', 'COMPLETED', 'Standard',  'PayPal',      NULL),
    (1041, 14, '2024-07-01', 'COMPLETED', 'Standard',  'Credit Card', NULL),
    (1042, 15, '2024-07-03', 'COMPLETED', 'Express',   'Credit Card', NULL),
    (1043, 1,  '2024-07-05', 'COMPLETED', 'Standard',  'PayPal',      'Loyal customer'),
    (1044, 16, '2024-07-08', 'COMPLETED', 'Standard',  'Debit Card',  NULL),
    (1045, 17, '2024-07-10', 'SHIPPED',   'Express',   'Credit Card', NULL),
    (1046, 19, '2024-07-12', 'SHIPPED',   'Standard',  'Credit Card', NULL),
    (1047, 20, '2024-07-15', 'SHIPPED',   'Standard',  'PayPal',      NULL),
    (1048, 6,  '2024-07-18', 'PROCESSING','Express',   'Credit Card', NULL),
    (1049, 21, '2024-07-20', 'PROCESSING','Standard',  'Debit Card',  NULL),
    (1050, 22, '2024-07-22', 'PROCESSING','Standard',  'Credit Card', NULL),
    (1051, 7,  '2024-07-25', 'PENDING',   'Overnight', 'PayPal',      NULL),
    (1052, 23, '2024-07-27', 'PENDING',   'Standard',  'Credit Card', NULL),
    (1053, 13, '2024-07-28', 'PENDING',   'Express',   'Credit Card', NULL),
    (1054, 4,  '2024-07-29', 'PENDING',   'Standard',  'Debit Card',  NULL),
    (1055, 25, '2024-07-30', 'PENDING',   'Standard',  'Credit Card', NULL);


-- -------------------------------------------------------
-- 3d. Insert 110+ order line items
-- -------------------------------------------------------
INSERT INTO RAW_ORDER_ITEMS (ORDER_ITEM_ID, ORDER_ID, PRODUCT_ID, QUANTITY, UNIT_PRICE, DISCOUNT_PCT)
VALUES
    -- March orders
    (1, 1001, 101, 1, 149.99, 0.00),
    (2, 1001, 117, 2,  29.99, 0.00),
    (3, 1002, 104, 1, 279.99, 0.00),
    (4, 1002, 105, 1, 189.99, 0.00),
    (5, 1003, 102, 1, 129.99, 5.00),
    (6, 1003, 103, 1,  59.99, 0.00),
    (7, 1004, 108, 1, 119.99, 0.00),
    (8, 1004, 109, 1, 159.99, 0.00),
    (9, 1005, 114, 1, 249.99, 0.00),
    (10, 1005, 115, 1,  79.99, 0.00),
    (11, 1005, 116, 2,  49.99, 10.00),
    (12, 1006, 106, 1,  89.99, 0.00),
    (13, 1006, 107, 2,  34.99, 0.00),
    (14, 1007, 110, 1, 199.99, 0.00),
    (15, 1007, 108, 1, 119.99, 0.00),
    (16, 1008, 111, 1,  89.99, 0.00),
    (17, 1008, 112, 1,  74.99, 0.00),
    (18, 1008, 113, 2,  39.99, 0.00),
    (19, 1009, 101, 1, 149.99, 0.00),
    (20, 1009, 102, 1, 129.99, 0.00),
    (21, 1010, 114, 1, 249.99, 5.00),
    (22, 1010, 116, 1,  49.99, 0.00),

    -- April orders
    (23, 1011, 104, 1, 279.99, 0.00),
    (24, 1011, 106, 1,  89.99, 0.00),
    (25, 1012, 101, 2, 149.99, 0.00),
    (26, 1013, 102, 1, 129.99, 0.00),
    (27, 1013, 118, 1,  44.99, 0.00),
    (28, 1014, 109, 1, 159.99, 0.00),
    (29, 1014, 110, 1, 199.99, 10.00),
    (30, 1015, 111, 2,  89.99, 0.00),
    (31, 1015, 113, 1,  39.99, 0.00),
    (32, 1016, 105, 1, 189.99, 0.00),
    (33, 1016, 107, 1,  34.99, 0.00),
    (34, 1017, 114, 1, 249.99, 0.00),
    (35, 1017, 115, 2,  79.99, 0.00),
    (36, 1018, 101, 1, 149.99, 5.00),
    (37, 1018, 103, 2,  59.99, 0.00),
    (38, 1019, 106, 1,  89.99, 0.00),
    (39, 1019, 118, 2,  44.99, 0.00),
    (40, 1020, 108, 1, 119.99, 0.00),
    (41, 1020, 112, 1,  74.99, 0.00),

    -- May orders
    (42, 1021, 104, 1, 279.99, 0.00),
    (43, 1021, 107, 3,  34.99, 0.00),
    (44, 1022, 117, 3,  29.99, 0.00),
    (45, 1022, 118, 1,  44.99, 0.00),
    (46, 1023, 102, 1, 129.99, 0.00),
    (47, 1023, 101, 1, 149.99, 0.00),
    (48, 1024, 110, 1, 199.99, 0.00),
    (49, 1024, 109, 1, 159.99, 0.00),
    (50, 1025, 114, 1, 249.99, 5.00),
    (51, 1025, 116, 2,  49.99, 0.00),
    (52, 1026, 105, 1, 189.99, 0.00),
    (53, 1026, 106, 1,  89.99, 0.00),
    (54, 1027, 111, 1,  89.99, 0.00),
    (55, 1027, 113, 3,  39.99, 0.00),
    (56, 1028, 101, 1, 149.99, 0.00),
    (57, 1028, 103, 1,  59.99, 0.00),
    (58, 1029, 104, 1, 279.99, 0.00),
    (59, 1029, 118, 2,  44.99, 0.00),
    (60, 1030, 115, 1,  79.99, 0.00),
    (61, 1030, 116, 1,  49.99, 0.00),

    -- June orders
    (62, 1031, 102, 1, 129.99, 0.00),
    (63, 1031, 117, 1,  29.99, 0.00),
    (64, 1032, 112, 2,  74.99, 0.00),
    (65, 1032, 111, 1,  89.99, 0.00),
    (66, 1033, 106, 1,  89.99, 0.00),
    (67, 1033, 107, 1,  34.99, 0.00),
    (68, 1034, 101, 1, 149.99, 0.00),
    (69, 1034, 118, 1,  44.99, 0.00),
    (70, 1035, 108, 1, 119.99, 0.00),
    (71, 1035, 110, 1, 199.99, 0.00),
    (72, 1036, 114, 1, 249.99, 0.00),
    (73, 1036, 115, 1,  79.99, 0.00),
    (74, 1037, 105, 1, 189.99, 0.00),
    (75, 1037, 103, 2,  59.99, 0.00),
    (76, 1038, 104, 1, 279.99, 5.00),
    (77, 1038, 106, 1,  89.99, 0.00),
    (78, 1039, 109, 1, 159.99, 0.00),
    (79, 1039, 113, 2,  39.99, 0.00),
    (80, 1040, 117, 2,  29.99, 0.00),
    (81, 1040, 101, 1, 149.99, 0.00),

    -- July orders
    (82, 1041, 102, 1, 129.99, 0.00),
    (83, 1041, 103, 1,  59.99, 0.00),
    (84, 1042, 110, 1, 199.99, 0.00),
    (85, 1042, 108, 1, 119.99, 0.00),
    (86, 1043, 111, 2,  89.99, 0.00),
    (87, 1043, 112, 1,  74.99, 0.00),
    (88, 1044, 105, 1, 189.99, 10.00),
    (89, 1044, 107, 2,  34.99, 0.00),
    (90, 1045, 114, 1, 249.99, 0.00),
    (91, 1045, 116, 1,  49.99, 0.00),
    (92, 1046, 101, 1, 149.99, 0.00),
    (93, 1046, 117, 1,  29.99, 0.00),
    (94, 1047, 104, 1, 279.99, 0.00),
    (95, 1047, 118, 1,  44.99, 0.00),
    (96, 1048, 102, 1, 129.99, 5.00),
    (97, 1048, 103, 1,  59.99, 0.00),
    (98, 1049, 106, 2,  89.99, 0.00),
    (99, 1049, 113, 1,  39.99, 0.00),
    (100, 1050, 109, 1, 159.99, 0.00),
    (101, 1050, 108, 1, 119.99, 0.00),
    (102, 1051, 114, 1, 249.99, 0.00),
    (103, 1051, 115, 2,  79.99, 0.00),
    (104, 1052, 101, 1, 149.99, 0.00),
    (105, 1052, 102, 1, 129.99, 0.00),
    (106, 1053, 111, 1,  89.99, 0.00),
    (107, 1053, 112, 1,  74.99, 0.00),
    (108, 1053, 113, 1,  39.99, 0.00),
    (109, 1054, 105, 1, 189.99, 0.00),
    (110, 1054, 104, 1, 279.99, 5.00),
    (111, 1055, 117, 2,  29.99, 0.00),
    (112, 1055, 118, 1,  44.99, 0.00);

-- Quick count verification
SELECT 'RAW_CUSTOMERS' AS table_name, COUNT(*) AS row_count FROM RAW_CUSTOMERS
UNION ALL
SELECT 'RAW_PRODUCTS',  COUNT(*) FROM RAW_PRODUCTS
UNION ALL
SELECT 'RAW_ORDERS',    COUNT(*) FROM RAW_ORDERS
UNION ALL
SELECT 'RAW_ORDER_ITEMS', COUNT(*) FROM RAW_ORDER_ITEMS;


-- =====================================================================
-- SECTION 4: CREATE STREAMS FOR CHANGE DATA CAPTURE
-- Concepts: Lab 09 (Streams & Tasks)
-- =====================================================================

USE SCHEMA ECOMMERCE_DW.BRONZE;

-- Streams automatically track INSERTs, UPDATEs, and DELETEs on source tables
CREATE OR REPLACE STREAM CUSTOMER_STREAM ON TABLE RAW_CUSTOMERS
    COMMENT = 'Captures changes to raw customer data';

CREATE OR REPLACE STREAM PRODUCT_STREAM ON TABLE RAW_PRODUCTS
    COMMENT = 'Captures changes to raw product data';

CREATE OR REPLACE STREAM ORDER_STREAM ON TABLE RAW_ORDERS
    COMMENT = 'Captures changes to raw order data';

CREATE OR REPLACE STREAM ORDER_ITEM_STREAM ON TABLE RAW_ORDER_ITEMS
    COMMENT = 'Captures changes to raw order item data';

-- Verify streams were created
SHOW STREAMS IN SCHEMA ECOMMERCE_DW.BRONZE;

-- Note: Streams created AFTER data was inserted will not capture existing rows.
-- We will handle the initial load via direct INSERT in the stored procedures.


-- =====================================================================
-- SECTION 5: CREATE SILVER TABLES (CLEANED AND TRANSFORMED)
-- Concepts: Lab 02 (DDL), Lab 04 (Querying)
-- =====================================================================

USE SCHEMA ECOMMERCE_DW.SILVER;

-- Customers dimension: JSON address fields extracted into proper columns
CREATE OR REPLACE TABLE DIM_CUSTOMERS (
    CUSTOMER_KEY    INTEGER AUTOINCREMENT,
    CUSTOMER_ID     INTEGER,
    FIRST_NAME      VARCHAR(50),
    LAST_NAME       VARCHAR(50),
    FULL_NAME       VARCHAR(101),
    EMAIL           VARCHAR(100),
    PHONE           VARCHAR(20),
    STREET          VARCHAR(200),
    CITY            VARCHAR(100),
    STATE           VARCHAR(2),
    ZIP_CODE        VARCHAR(10),
    SIGNUP_DATE     DATE,
    IS_ACTIVE       BOOLEAN,
    PROCESSED_AT    TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (CUSTOMER_KEY)
);

-- Products dimension: cleaned and standardized
CREATE OR REPLACE TABLE DIM_PRODUCTS (
    PRODUCT_KEY     INTEGER AUTOINCREMENT,
    PRODUCT_ID      INTEGER,
    PRODUCT_NAME    VARCHAR(200),
    CATEGORY        VARCHAR(50),
    SUBCATEGORY     VARCHAR(50),
    UNIT_PRICE      NUMBER(10,2),
    WEIGHT_KG       NUMBER(6,2),
    IS_AVAILABLE    BOOLEAN,
    PROCESSED_AT    TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (PRODUCT_KEY)
);

-- Orders fact table: denormalized with computed line totals
CREATE OR REPLACE TABLE FACT_ORDERS (
    ORDER_FACT_KEY  INTEGER AUTOINCREMENT,
    ORDER_ID        INTEGER,
    ORDER_ITEM_ID   INTEGER,
    CUSTOMER_ID     INTEGER,
    PRODUCT_ID      INTEGER,
    ORDER_DATE      DATE,
    ORDER_STATUS    VARCHAR(20),
    SHIPPING_METHOD VARCHAR(30),
    PAYMENT_METHOD  VARCHAR(30),
    QUANTITY        INTEGER,
    UNIT_PRICE      NUMBER(10,2),
    DISCOUNT_PCT    NUMBER(5,2),
    DISCOUNT_AMOUNT NUMBER(10,2),
    LINE_TOTAL      NUMBER(12,2),
    PROCESSED_AT    TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (ORDER_FACT_KEY)
);


-- =====================================================================
-- SECTION 6: CREATE A UDF FOR BUSINESS LOGIC
-- Concepts: Lab 11 (UDFs)
-- =====================================================================

USE SCHEMA ECOMMERCE_DW.SILVER;

-- UDF to categorize customers by total spend into loyalty tiers
CREATE OR REPLACE FUNCTION CATEGORIZE_CUSTOMER(TOTAL_SPEND NUMBER(12,2))
    RETURNS VARCHAR(20)
    LANGUAGE SQL
    AS
    $$
        CASE
            WHEN TOTAL_SPEND >= 1000 THEN 'Platinum'
            WHEN TOTAL_SPEND >= 500  THEN 'Gold'
            WHEN TOTAL_SPEND >= 100  THEN 'Silver'
            ELSE 'Bronze'
        END
    $$;

-- Quick test of the UDF
SELECT
    SILVER.CATEGORIZE_CUSTOMER(1500.00)  AS tier_platinum,
    SILVER.CATEGORIZE_CUSTOMER(750.00)   AS tier_gold,
    SILVER.CATEGORIZE_CUSTOMER(250.00)   AS tier_silver,
    SILVER.CATEGORIZE_CUSTOMER(50.00)    AS tier_bronze;


-- =====================================================================
-- SECTION 7: STORED PROCEDURES FOR TRANSFORMATION LOGIC
-- Concepts: Lab 10 (Stored Procedures), Lab 06 (JSON extraction)
-- =====================================================================

USE SCHEMA ECOMMERCE_DW.SILVER;

-- -----------------------------------------------------------
-- 7a. SP_PROCESS_CUSTOMERS
-- Reads from RAW_CUSTOMERS, extracts JSON address fields,
-- standardizes email to lowercase, inserts into DIM_CUSTOMERS.
-- On initial run (empty DIM_CUSTOMERS), loads directly from
-- the raw table. On subsequent runs, reads from the stream.
-- -----------------------------------------------------------
CREATE OR REPLACE PROCEDURE SP_PROCESS_CUSTOMERS()
    RETURNS VARCHAR
    LANGUAGE SQL
    AS
$$
DECLARE
    rows_processed INTEGER DEFAULT 0;
    dim_count INTEGER DEFAULT 0;
BEGIN
    -- Check if DIM_CUSTOMERS is empty (initial load)
    SELECT COUNT(*) INTO dim_count FROM ECOMMERCE_DW.SILVER.DIM_CUSTOMERS;

    IF (dim_count = 0) THEN
        -- Initial load: read directly from the raw table
        INSERT INTO ECOMMERCE_DW.SILVER.DIM_CUSTOMERS (
            CUSTOMER_ID, FIRST_NAME, LAST_NAME, FULL_NAME,
            EMAIL, PHONE, STREET, CITY, STATE, ZIP_CODE,
            SIGNUP_DATE, IS_ACTIVE
        )
        SELECT
            CUSTOMER_ID,
            INITCAP(TRIM(FIRST_NAME)),
            INITCAP(TRIM(LAST_NAME)),
            INITCAP(TRIM(FIRST_NAME)) || ' ' || INITCAP(TRIM(LAST_NAME)),
            LOWER(TRIM(EMAIL)),
            PHONE,
            ADDRESS:street::VARCHAR,
            ADDRESS:city::VARCHAR,
            ADDRESS:state::VARCHAR,
            ADDRESS:zip::VARCHAR,
            SIGNUP_DATE,
            IS_ACTIVE
        FROM ECOMMERCE_DW.BRONZE.RAW_CUSTOMERS;

        rows_processed := SQLROWCOUNT;
        RETURN 'Initial load complete. Rows processed: ' || rows_processed::VARCHAR;
    ELSE
        -- Incremental load: read from stream
        INSERT INTO ECOMMERCE_DW.SILVER.DIM_CUSTOMERS (
            CUSTOMER_ID, FIRST_NAME, LAST_NAME, FULL_NAME,
            EMAIL, PHONE, STREET, CITY, STATE, ZIP_CODE,
            SIGNUP_DATE, IS_ACTIVE
        )
        SELECT
            CUSTOMER_ID,
            INITCAP(TRIM(FIRST_NAME)),
            INITCAP(TRIM(LAST_NAME)),
            INITCAP(TRIM(FIRST_NAME)) || ' ' || INITCAP(TRIM(LAST_NAME)),
            LOWER(TRIM(EMAIL)),
            PHONE,
            ADDRESS:street::VARCHAR,
            ADDRESS:city::VARCHAR,
            ADDRESS:state::VARCHAR,
            ADDRESS:zip::VARCHAR,
            SIGNUP_DATE,
            IS_ACTIVE
        FROM ECOMMERCE_DW.BRONZE.CUSTOMER_STREAM
        WHERE METADATA$ACTION = 'INSERT';

        rows_processed := SQLROWCOUNT;
        RETURN 'Incremental load complete. Rows processed: ' || rows_processed::VARCHAR;
    END IF;
END;
$$;


-- -----------------------------------------------------------
-- 7b. SP_PROCESS_PRODUCTS
-- Reads from RAW_PRODUCTS and loads into DIM_PRODUCTS.
-- -----------------------------------------------------------
CREATE OR REPLACE PROCEDURE SP_PROCESS_PRODUCTS()
    RETURNS VARCHAR
    LANGUAGE SQL
    AS
$$
DECLARE
    rows_processed INTEGER DEFAULT 0;
    dim_count INTEGER DEFAULT 0;
BEGIN
    SELECT COUNT(*) INTO dim_count FROM ECOMMERCE_DW.SILVER.DIM_PRODUCTS;

    IF (dim_count = 0) THEN
        INSERT INTO ECOMMERCE_DW.SILVER.DIM_PRODUCTS (
            PRODUCT_ID, PRODUCT_NAME, CATEGORY, SUBCATEGORY,
            UNIT_PRICE, WEIGHT_KG, IS_AVAILABLE
        )
        SELECT
            PRODUCT_ID,
            TRIM(PRODUCT_NAME),
            INITCAP(TRIM(CATEGORY)),
            INITCAP(TRIM(SUBCATEGORY)),
            UNIT_PRICE,
            WEIGHT_KG,
            IS_AVAILABLE
        FROM ECOMMERCE_DW.BRONZE.RAW_PRODUCTS;

        rows_processed := SQLROWCOUNT;
        RETURN 'Initial load complete. Rows processed: ' || rows_processed::VARCHAR;
    ELSE
        INSERT INTO ECOMMERCE_DW.SILVER.DIM_PRODUCTS (
            PRODUCT_ID, PRODUCT_NAME, CATEGORY, SUBCATEGORY,
            UNIT_PRICE, WEIGHT_KG, IS_AVAILABLE
        )
        SELECT
            PRODUCT_ID,
            TRIM(PRODUCT_NAME),
            INITCAP(TRIM(CATEGORY)),
            INITCAP(TRIM(SUBCATEGORY)),
            UNIT_PRICE,
            WEIGHT_KG,
            IS_AVAILABLE
        FROM ECOMMERCE_DW.BRONZE.PRODUCT_STREAM
        WHERE METADATA$ACTION = 'INSERT';

        rows_processed := SQLROWCOUNT;
        RETURN 'Incremental load complete. Rows processed: ' || rows_processed::VARCHAR;
    END IF;
END;
$$;


-- -----------------------------------------------------------
-- 7c. SP_PROCESS_ORDERS
-- Joins RAW_ORDERS and RAW_ORDER_ITEMS, computes discount
-- amount and line total, inserts into FACT_ORDERS.
-- -----------------------------------------------------------
CREATE OR REPLACE PROCEDURE SP_PROCESS_ORDERS()
    RETURNS VARCHAR
    LANGUAGE SQL
    AS
$$
DECLARE
    rows_processed INTEGER DEFAULT 0;
    fact_count INTEGER DEFAULT 0;
BEGIN
    SELECT COUNT(*) INTO fact_count FROM ECOMMERCE_DW.SILVER.FACT_ORDERS;

    IF (fact_count = 0) THEN
        -- Initial load: join raw tables directly
        INSERT INTO ECOMMERCE_DW.SILVER.FACT_ORDERS (
            ORDER_ID, ORDER_ITEM_ID, CUSTOMER_ID, PRODUCT_ID,
            ORDER_DATE, ORDER_STATUS, SHIPPING_METHOD, PAYMENT_METHOD,
            QUANTITY, UNIT_PRICE, DISCOUNT_PCT, DISCOUNT_AMOUNT, LINE_TOTAL
        )
        SELECT
            o.ORDER_ID,
            oi.ORDER_ITEM_ID,
            o.CUSTOMER_ID,
            oi.PRODUCT_ID,
            o.ORDER_DATE,
            UPPER(TRIM(o.ORDER_STATUS)),
            INITCAP(TRIM(o.SHIPPING_METHOD)),
            INITCAP(TRIM(o.PAYMENT_METHOD)),
            oi.QUANTITY,
            oi.UNIT_PRICE,
            oi.DISCOUNT_PCT,
            ROUND(oi.QUANTITY * oi.UNIT_PRICE * (oi.DISCOUNT_PCT / 100), 2),
            ROUND(oi.QUANTITY * oi.UNIT_PRICE * (1 - oi.DISCOUNT_PCT / 100), 2)
        FROM ECOMMERCE_DW.BRONZE.RAW_ORDERS o
        JOIN ECOMMERCE_DW.BRONZE.RAW_ORDER_ITEMS oi
            ON o.ORDER_ID = oi.ORDER_ID;

        rows_processed := SQLROWCOUNT;
        RETURN 'Initial load complete. Rows processed: ' || rows_processed::VARCHAR;
    ELSE
        -- Incremental load: use streams for new data
        INSERT INTO ECOMMERCE_DW.SILVER.FACT_ORDERS (
            ORDER_ID, ORDER_ITEM_ID, CUSTOMER_ID, PRODUCT_ID,
            ORDER_DATE, ORDER_STATUS, SHIPPING_METHOD, PAYMENT_METHOD,
            QUANTITY, UNIT_PRICE, DISCOUNT_PCT, DISCOUNT_AMOUNT, LINE_TOTAL
        )
        SELECT
            o.ORDER_ID,
            oi.ORDER_ITEM_ID,
            o.CUSTOMER_ID,
            oi.PRODUCT_ID,
            o.ORDER_DATE,
            UPPER(TRIM(o.ORDER_STATUS)),
            INITCAP(TRIM(o.SHIPPING_METHOD)),
            INITCAP(TRIM(o.PAYMENT_METHOD)),
            oi.QUANTITY,
            oi.UNIT_PRICE,
            oi.DISCOUNT_PCT,
            ROUND(oi.QUANTITY * oi.UNIT_PRICE * (oi.DISCOUNT_PCT / 100), 2),
            ROUND(oi.QUANTITY * oi.UNIT_PRICE * (1 - oi.DISCOUNT_PCT / 100), 2)
        FROM ECOMMERCE_DW.BRONZE.ORDER_STREAM o
        JOIN ECOMMERCE_DW.BRONZE.ORDER_ITEM_STREAM oi
            ON o.ORDER_ID = oi.ORDER_ID
        WHERE o.METADATA$ACTION = 'INSERT'
          AND oi.METADATA$ACTION = 'INSERT';

        rows_processed := SQLROWCOUNT;
        RETURN 'Incremental load complete. Rows processed: ' || rows_processed::VARCHAR;
    END IF;
END;
$$;


-- -----------------------------------------------------------
-- Execute the stored procedures for the initial load
-- -----------------------------------------------------------
CALL SILVER.SP_PROCESS_CUSTOMERS();
CALL SILVER.SP_PROCESS_PRODUCTS();
CALL SILVER.SP_PROCESS_ORDERS();

-- Verify SILVER layer loaded correctly
SELECT 'DIM_CUSTOMERS' AS table_name, COUNT(*) AS row_count FROM SILVER.DIM_CUSTOMERS
UNION ALL
SELECT 'DIM_PRODUCTS',  COUNT(*) FROM SILVER.DIM_PRODUCTS
UNION ALL
SELECT 'FACT_ORDERS',   COUNT(*) FROM SILVER.FACT_ORDERS;

-- Preview the cleaned customer data (notice: lowercase emails, extracted address)
SELECT CUSTOMER_KEY, CUSTOMER_ID, FULL_NAME, EMAIL, STREET, CITY, STATE, ZIP_CODE
FROM SILVER.DIM_CUSTOMERS
LIMIT 5;


-- =====================================================================
-- SECTION 8: DYNAMIC TABLES IN GOLD (AUTO-REFRESHING AGGREGATIONS)
-- Concepts: Lab 13 (Dynamic Tables), Lab 05 (Aggregate/Window Functions)
-- =====================================================================

USE SCHEMA ECOMMERCE_DW.GOLD;

-- -----------------------------------------------------------
-- 8a. DAILY_SALES_SUMMARY
-- Aggregates daily revenue, order count, and avg order value
-- -----------------------------------------------------------
CREATE OR REPLACE DYNAMIC TABLE DAILY_SALES_SUMMARY
    TARGET_LAG = '1 minute'
    WAREHOUSE = ECOMMERCE_WH
    AS
    SELECT
        fo.ORDER_DATE,
        fo.ORDER_STATUS,
        COUNT(DISTINCT fo.ORDER_ID)         AS ORDER_COUNT,
        SUM(fo.LINE_TOTAL)                  AS TOTAL_REVENUE,
        ROUND(AVG(fo.LINE_TOTAL), 2)        AS AVG_LINE_AMOUNT,
        SUM(fo.QUANTITY)                    AS TOTAL_UNITS_SOLD,
        SUM(fo.DISCOUNT_AMOUNT)             AS TOTAL_DISCOUNTS,
        ROUND(
            SUM(fo.LINE_TOTAL) / NULLIF(COUNT(DISTINCT fo.ORDER_ID), 0), 2
        )                                   AS AVG_ORDER_VALUE
    FROM ECOMMERCE_DW.SILVER.FACT_ORDERS fo
    GROUP BY fo.ORDER_DATE, fo.ORDER_STATUS;


-- -----------------------------------------------------------
-- 8b. CUSTOMER_LIFETIME_VALUE
-- Total spend, order count, loyalty tier per customer
-- -----------------------------------------------------------
CREATE OR REPLACE DYNAMIC TABLE CUSTOMER_LIFETIME_VALUE
    TARGET_LAG = '1 minute'
    WAREHOUSE = ECOMMERCE_WH
    AS
    SELECT
        dc.CUSTOMER_ID,
        dc.FULL_NAME,
        dc.EMAIL,
        dc.CITY,
        dc.STATE,
        COUNT(DISTINCT fo.ORDER_ID)         AS TOTAL_ORDERS,
        SUM(fo.LINE_TOTAL)                  AS TOTAL_SPEND,
        ROUND(
            SUM(fo.LINE_TOTAL) / NULLIF(COUNT(DISTINCT fo.ORDER_ID), 0), 2
        )                                   AS AVG_ORDER_VALUE,
        MIN(fo.ORDER_DATE)                  AS FIRST_ORDER_DATE,
        MAX(fo.ORDER_DATE)                  AS LAST_ORDER_DATE,
        DATEDIFF('day', MIN(fo.ORDER_DATE), MAX(fo.ORDER_DATE))
                                            AS CUSTOMER_TENURE_DAYS,
        ECOMMERCE_DW.SILVER.CATEGORIZE_CUSTOMER(SUM(fo.LINE_TOTAL))
                                            AS LOYALTY_TIER
    FROM ECOMMERCE_DW.SILVER.DIM_CUSTOMERS dc
    LEFT JOIN ECOMMERCE_DW.SILVER.FACT_ORDERS fo
        ON dc.CUSTOMER_ID = fo.CUSTOMER_ID
    GROUP BY dc.CUSTOMER_ID, dc.FULL_NAME, dc.EMAIL, dc.CITY, dc.STATE;


-- -----------------------------------------------------------
-- 8c. PRODUCT_PERFORMANCE
-- Units sold, revenue, and ranking per product within category
-- -----------------------------------------------------------
CREATE OR REPLACE DYNAMIC TABLE PRODUCT_PERFORMANCE
    TARGET_LAG = '1 minute'
    WAREHOUSE = ECOMMERCE_WH
    AS
    SELECT
        dp.PRODUCT_ID,
        dp.PRODUCT_NAME,
        dp.CATEGORY,
        dp.SUBCATEGORY,
        dp.UNIT_PRICE                       AS CURRENT_PRICE,
        COALESCE(SUM(fo.QUANTITY), 0)       AS TOTAL_UNITS_SOLD,
        COALESCE(SUM(fo.LINE_TOTAL), 0)     AS TOTAL_REVENUE,
        COALESCE(COUNT(DISTINCT fo.ORDER_ID), 0)
                                            AS ORDER_APPEARANCES,
        RANK() OVER (
            PARTITION BY dp.CATEGORY
            ORDER BY COALESCE(SUM(fo.LINE_TOTAL), 0) DESC
        )                                   AS CATEGORY_REVENUE_RANK
    FROM ECOMMERCE_DW.SILVER.DIM_PRODUCTS dp
    LEFT JOIN ECOMMERCE_DW.SILVER.FACT_ORDERS fo
        ON dp.PRODUCT_ID = fo.PRODUCT_ID
    GROUP BY dp.PRODUCT_ID, dp.PRODUCT_NAME, dp.CATEGORY,
             dp.SUBCATEGORY, dp.UNIT_PRICE;


-- Preview the GOLD layer (allow a moment for dynamic tables to refresh)
SELECT * FROM GOLD.DAILY_SALES_SUMMARY ORDER BY ORDER_DATE DESC LIMIT 10;
SELECT * FROM GOLD.CUSTOMER_LIFETIME_VALUE ORDER BY TOTAL_SPEND DESC LIMIT 10;
SELECT * FROM GOLD.PRODUCT_PERFORMANCE ORDER BY TOTAL_REVENUE DESC LIMIT 10;


-- =====================================================================
-- SECTION 9: TASKS FOR AUTOMATED PIPELINE EXECUTION
-- Concepts: Lab 09 (Streams & Tasks)
-- =====================================================================

USE SCHEMA ECOMMERCE_DW.BRONZE;

-- Root task: processes customers when stream has data
-- Runs every 5 minutes but only executes when there is new data
CREATE OR REPLACE TASK TASK_PROCESS_CUSTOMERS
    WAREHOUSE = ECOMMERCE_WH
    SCHEDULE  = '5 MINUTE'
    WHEN SYSTEM$STREAM_HAS_DATA('ECOMMERCE_DW.BRONZE.CUSTOMER_STREAM')
    AS
    CALL ECOMMERCE_DW.SILVER.SP_PROCESS_CUSTOMERS();

-- Child task: processes orders after customers are done
-- This ensures dimensional data is available before fact data loads
CREATE OR REPLACE TASK TASK_PROCESS_ORDERS
    WAREHOUSE = ECOMMERCE_WH
    AFTER ECOMMERCE_DW.BRONZE.TASK_PROCESS_CUSTOMERS
    AS
    CALL ECOMMERCE_DW.SILVER.SP_PROCESS_ORDERS();

-- Standalone task for products (independent of orders/customers)
CREATE OR REPLACE TASK TASK_PROCESS_PRODUCTS
    WAREHOUSE = ECOMMERCE_WH
    SCHEDULE  = '5 MINUTE'
    WHEN SYSTEM$STREAM_HAS_DATA('ECOMMERCE_DW.BRONZE.PRODUCT_STREAM')
    AS
    CALL ECOMMERCE_DW.SILVER.SP_PROCESS_PRODUCTS();

-- Tasks are created in SUSPENDED state by default. Resume them to activate.
-- NOTE: You must resume child tasks BEFORE parent tasks.
ALTER TASK TASK_PROCESS_ORDERS RESUME;
ALTER TASK TASK_PROCESS_CUSTOMERS RESUME;
ALTER TASK TASK_PROCESS_PRODUCTS RESUME;

-- Verify tasks are running
SHOW TASKS IN SCHEMA ECOMMERCE_DW.BRONZE;


-- =====================================================================
-- SECTION 10: CUSTOM ROLES AND ACCESS CONTROL
-- Concepts: Lab 07 (RBAC)
-- =====================================================================

-- Switch to SECURITYADMIN for role/grant management
USE ROLE SECURITYADMIN;

-- Create an analyst role (read-only on GOLD layer)
CREATE OR REPLACE ROLE ECOMMERCE_ANALYST
    COMMENT = 'Read-only access to GOLD analytics layer';

-- Create an admin role (full access to all schemas)
CREATE OR REPLACE ROLE ECOMMERCE_ADMIN
    COMMENT = 'Full access to all e-commerce data warehouse schemas';

-- Build role hierarchy (follows Snowflake best practices)
-- ECOMMERCE_ANALYST -> ECOMMERCE_ADMIN -> SYSADMIN
GRANT ROLE ECOMMERCE_ANALYST TO ROLE ECOMMERCE_ADMIN;
GRANT ROLE ECOMMERCE_ADMIN   TO ROLE SYSADMIN;

-- Grant warehouse usage to both roles
GRANT USAGE ON WAREHOUSE ECOMMERCE_WH TO ROLE ECOMMERCE_ANALYST;
GRANT USAGE ON WAREHOUSE ECOMMERCE_WH TO ROLE ECOMMERCE_ADMIN;

-- Grant database usage to both roles
GRANT USAGE ON DATABASE ECOMMERCE_DW TO ROLE ECOMMERCE_ANALYST;
GRANT USAGE ON DATABASE ECOMMERCE_DW TO ROLE ECOMMERCE_ADMIN;

-- ANALYST: read-only on GOLD schema only
GRANT USAGE ON SCHEMA ECOMMERCE_DW.GOLD TO ROLE ECOMMERCE_ANALYST;
GRANT SELECT ON ALL TABLES IN SCHEMA ECOMMERCE_DW.GOLD TO ROLE ECOMMERCE_ANALYST;
GRANT SELECT ON ALL DYNAMIC TABLES IN SCHEMA ECOMMERCE_DW.GOLD TO ROLE ECOMMERCE_ANALYST;
GRANT SELECT ON ALL VIEWS IN SCHEMA ECOMMERCE_DW.GOLD TO ROLE ECOMMERCE_ANALYST;

-- Future grants so new GOLD objects are automatically accessible
GRANT SELECT ON FUTURE TABLES IN SCHEMA ECOMMERCE_DW.GOLD TO ROLE ECOMMERCE_ANALYST;
GRANT SELECT ON FUTURE DYNAMIC TABLES IN SCHEMA ECOMMERCE_DW.GOLD TO ROLE ECOMMERCE_ANALYST;
GRANT SELECT ON FUTURE VIEWS IN SCHEMA ECOMMERCE_DW.GOLD TO ROLE ECOMMERCE_ANALYST;

-- ADMIN: full access to all schemas
GRANT USAGE ON SCHEMA ECOMMERCE_DW.BRONZE TO ROLE ECOMMERCE_ADMIN;
GRANT USAGE ON SCHEMA ECOMMERCE_DW.SILVER TO ROLE ECOMMERCE_ADMIN;
GRANT USAGE ON SCHEMA ECOMMERCE_DW.GOLD   TO ROLE ECOMMERCE_ADMIN;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA ECOMMERCE_DW.BRONZE TO ROLE ECOMMERCE_ADMIN;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA ECOMMERCE_DW.SILVER TO ROLE ECOMMERCE_ADMIN;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA ECOMMERCE_DW.GOLD   TO ROLE ECOMMERCE_ADMIN;

GRANT ALL PRIVILEGES ON FUTURE TABLES IN SCHEMA ECOMMERCE_DW.BRONZE TO ROLE ECOMMERCE_ADMIN;
GRANT ALL PRIVILEGES ON FUTURE TABLES IN SCHEMA ECOMMERCE_DW.SILVER TO ROLE ECOMMERCE_ADMIN;
GRANT ALL PRIVILEGES ON FUTURE TABLES IN SCHEMA ECOMMERCE_DW.GOLD   TO ROLE ECOMMERCE_ADMIN;

-- Verify role setup
SHOW GRANTS TO ROLE ECOMMERCE_ANALYST;
SHOW GRANTS TO ROLE ECOMMERCE_ADMIN;

-- Switch back to SYSADMIN for data operations
USE ROLE SYSADMIN;
USE WAREHOUSE ECOMMERCE_WH;


-- =====================================================================
-- SECTION 11: SECURE VIEWS FOR DATA SHARING
-- Concepts: Lab 12 (Data Sharing - Secure Views)
-- =====================================================================

USE SCHEMA ECOMMERCE_DW.GOLD;

-- Secure view for a sales dashboard (hides underlying table structure)
CREATE OR REPLACE SECURE VIEW SECURE_SALES_DASHBOARD AS
SELECT
    ORDER_DATE,
    ORDER_STATUS,
    ORDER_COUNT,
    TOTAL_REVENUE,
    AVG_ORDER_VALUE,
    TOTAL_UNITS_SOLD,
    TOTAL_DISCOUNTS
FROM ECOMMERCE_DW.GOLD.DAILY_SALES_SUMMARY
WHERE ORDER_STATUS = 'COMPLETED';

-- Secure view for customer insights (masks PII)
CREATE OR REPLACE SECURE VIEW SECURE_CUSTOMER_INSIGHTS AS
SELECT
    CUSTOMER_ID,
    -- Mask email: show only domain
    CONCAT('***@', SPLIT_PART(EMAIL, '@', 2))   AS MASKED_EMAIL,
    CITY,
    STATE,
    TOTAL_ORDERS,
    TOTAL_SPEND,
    AVG_ORDER_VALUE,
    LOYALTY_TIER,
    FIRST_ORDER_DATE,
    LAST_ORDER_DATE,
    CUSTOMER_TENURE_DAYS
FROM ECOMMERCE_DW.GOLD.CUSTOMER_LIFETIME_VALUE;

-- Grant secure views to analyst role
USE ROLE SECURITYADMIN;
GRANT SELECT ON VIEW ECOMMERCE_DW.GOLD.SECURE_SALES_DASHBOARD    TO ROLE ECOMMERCE_ANALYST;
GRANT SELECT ON VIEW ECOMMERCE_DW.GOLD.SECURE_CUSTOMER_INSIGHTS  TO ROLE ECOMMERCE_ANALYST;

USE ROLE SYSADMIN;
USE WAREHOUSE ECOMMERCE_WH;

-- Preview secure views
SELECT * FROM GOLD.SECURE_SALES_DASHBOARD ORDER BY ORDER_DATE DESC LIMIT 5;
SELECT * FROM GOLD.SECURE_CUSTOMER_INSIGHTS ORDER BY TOTAL_SPEND DESC LIMIT 5;


-- =====================================================================
-- SECTION 12: PERFORMANCE OPTIMIZATION
-- Concepts: Lab 14 (Performance Tuning - Clustering Keys)
-- =====================================================================

USE SCHEMA ECOMMERCE_DW.SILVER;

-- Add clustering key on FACT_ORDERS by ORDER_DATE
-- Most analytics queries filter or group by date, so this improves pruning
ALTER TABLE FACT_ORDERS CLUSTER BY (ORDER_DATE);

-- Verify clustering information
SELECT SYSTEM$CLUSTERING_INFORMATION('ECOMMERCE_DW.SILVER.FACT_ORDERS');

-- Review: For larger datasets, you would also consider:
-- 1. Search optimization service for point lookups:
--    ALTER TABLE FACT_ORDERS ADD SEARCH OPTIMIZATION;
-- 2. Materialized views for frequently run expensive queries
-- 3. Warehouse auto-scaling for concurrent workloads:
--    ALTER WAREHOUSE ECOMMERCE_WH SET
--        MIN_CLUSTER_COUNT = 1
--        MAX_CLUSTER_COUNT = 3
--        SCALING_POLICY = 'STANDARD';


-- =====================================================================
-- SECTION 13: ZERO-COPY CLONE FOR DEV/TEST
-- Concepts: Lab 08 (Time Travel & Cloning)
-- =====================================================================

-- Clone the entire database instantly for development/testing
-- This creates a full copy with zero additional storage cost
CREATE OR REPLACE DATABASE ECOMMERCE_DW_DEV CLONE ECOMMERCE_DW
    COMMENT = 'Development clone of e-commerce data warehouse';

-- Verify the clone has all schemas and tables
SHOW SCHEMAS IN DATABASE ECOMMERCE_DW_DEV;

SELECT 'DEV DIM_CUSTOMERS' AS table_name, COUNT(*) AS row_count
    FROM ECOMMERCE_DW_DEV.SILVER.DIM_CUSTOMERS
UNION ALL
SELECT 'DEV FACT_ORDERS', COUNT(*)
    FROM ECOMMERCE_DW_DEV.SILVER.FACT_ORDERS;


-- =====================================================================
-- SECTION 14: DEMONSTRATE THE FULL PIPELINE (END-TO-END TEST)
-- =====================================================================

-- Let's prove the entire pipeline works by inserting new data and
-- watching it flow from BRONZE -> SILVER -> GOLD.

USE DATABASE ECOMMERCE_DW;

-- -----------------------------------------------------------
-- 14a. Insert new raw data into BRONZE
-- -----------------------------------------------------------
USE SCHEMA BRONZE;

-- Add two new customers
INSERT INTO RAW_CUSTOMERS (CUSTOMER_ID, FIRST_NAME, LAST_NAME, EMAIL, PHONE, ADDRESS, SIGNUP_DATE, IS_ACTIVE)
VALUES
    (26, 'Zoe',    'Campbell', 'ZOE.CAMPBELL@email.com', '555-0126',
     PARSE_JSON('{"street":"246 Oakwood Dr","city":"Jackson Hole","state":"WY","zip":"83001"}'),
     '2024-07-25', TRUE),
    (27, 'Aaron',  'Wright',   'aaron.wright@email.com', '555-0127',
     PARSE_JSON('{"street":"357 Pineview Ct","city":"Telluride","state":"CO","zip":"81435"}'),
     '2024-07-28', TRUE);

-- Add new orders for the new customers and an existing customer
INSERT INTO RAW_ORDERS (ORDER_ID, CUSTOMER_ID, ORDER_DATE, ORDER_STATUS, SHIPPING_METHOD, PAYMENT_METHOD, NOTES)
VALUES
    (1056, 26, '2024-08-01', 'COMPLETED', 'Express',  'Credit Card', 'New customer - first order'),
    (1057, 27, '2024-08-02', 'COMPLETED', 'Standard', 'PayPal',      'New customer - first order'),
    (1058, 1,  '2024-08-03', 'PENDING',   'Overnight','Credit Card', 'VIP customer - fifth order');

-- Add order line items for the new orders
INSERT INTO RAW_ORDER_ITEMS (ORDER_ITEM_ID, ORDER_ID, PRODUCT_ID, QUANTITY, UNIT_PRICE, DISCOUNT_PCT)
VALUES
    (113, 1056, 101, 1, 149.99, 0.00),    -- Zoe: Hiking boots
    (114, 1056, 102, 1, 129.99, 0.00),    -- Zoe: Backpack
    (115, 1056, 117, 2,  29.99, 0.00),    -- Zoe: Water bottles
    (116, 1057, 104, 1, 279.99, 0.00),    -- Aaron: Tent
    (117, 1057, 105, 1, 189.99, 10.00),   -- Aaron: Sleeping bag (10% off!)
    (118, 1058, 114, 1, 249.99, 5.00),    -- Alice: Ski jacket (5% off)
    (119, 1058, 115, 1,  79.99, 0.00),    -- Alice: Goggles
    (120, 1058, 116, 1,  49.99, 0.00);    -- Alice: Gloves

-- -----------------------------------------------------------
-- 14b. Verify streams captured the changes
-- -----------------------------------------------------------
SELECT 'CUSTOMER_STREAM'   AS stream_name, COUNT(*) AS pending_rows FROM BRONZE.CUSTOMER_STREAM
UNION ALL
SELECT 'ORDER_STREAM',     COUNT(*) FROM BRONZE.ORDER_STREAM
UNION ALL
SELECT 'ORDER_ITEM_STREAM', COUNT(*) FROM BRONZE.ORDER_ITEM_STREAM;

-- -----------------------------------------------------------
-- 14c. Manually execute the pipeline
-- (In production, the tasks would fire automatically)
-- -----------------------------------------------------------

-- Process customers first (dimension before facts)
CALL SILVER.SP_PROCESS_CUSTOMERS();

-- Process products (in case any new products were added)
CALL SILVER.SP_PROCESS_PRODUCTS();

-- Process orders
CALL SILVER.SP_PROCESS_ORDERS();

-- -----------------------------------------------------------
-- 14d. Verify data flowed to SILVER
-- -----------------------------------------------------------
-- Check the new customers appeared with cleaned data
SELECT CUSTOMER_KEY, CUSTOMER_ID, FULL_NAME, EMAIL, CITY, STATE
FROM SILVER.DIM_CUSTOMERS
WHERE CUSTOMER_ID IN (26, 27)
ORDER BY CUSTOMER_ID;

-- Check the new orders appeared with computed line totals
SELECT ORDER_FACT_KEY, ORDER_ID, CUSTOMER_ID, PRODUCT_ID,
       QUANTITY, UNIT_PRICE, DISCOUNT_PCT, DISCOUNT_AMOUNT, LINE_TOTAL
FROM SILVER.FACT_ORDERS
WHERE ORDER_ID IN (1056, 1057, 1058)
ORDER BY ORDER_ID, ORDER_ITEM_ID;

-- -----------------------------------------------------------
-- 14e. Query the GOLD layer (dynamic tables auto-refresh)
-- Allow up to 1 minute for dynamic tables to catch up
-- -----------------------------------------------------------

-- Check August sales appeared in the daily summary
SELECT * FROM GOLD.DAILY_SALES_SUMMARY
WHERE ORDER_DATE >= '2024-08-01'
ORDER BY ORDER_DATE;

-- Check lifetime value for the new customers
SELECT CUSTOMER_ID, FULL_NAME, TOTAL_ORDERS, TOTAL_SPEND, LOYALTY_TIER
FROM GOLD.CUSTOMER_LIFETIME_VALUE
WHERE CUSTOMER_ID IN (1, 26, 27)
ORDER BY TOTAL_SPEND DESC;

-- Check product performance rankings
SELECT PRODUCT_NAME, CATEGORY, TOTAL_UNITS_SOLD, TOTAL_REVENUE, CATEGORY_REVENUE_RANK
FROM GOLD.PRODUCT_PERFORMANCE
WHERE CATEGORY = 'Hiking'
ORDER BY CATEGORY_REVENUE_RANK;

-- -----------------------------------------------------------
-- 14f. Query the secure views
-- -----------------------------------------------------------
SELECT * FROM GOLD.SECURE_SALES_DASHBOARD WHERE ORDER_DATE >= '2024-08-01';
SELECT * FROM GOLD.SECURE_CUSTOMER_INSIGHTS WHERE CUSTOMER_ID IN (1, 26, 27) ORDER BY TOTAL_SPEND DESC;


-- =====================================================================
-- SECTION 15: FINAL VERIFICATION -- COMPLETE PIPELINE HEALTH CHECK
-- =====================================================================

-- -----------------------------------------------------------
-- 15a. Row counts at every layer
-- -----------------------------------------------------------
SELECT '1. BRONZE' AS layer, 'RAW_CUSTOMERS'   AS object_name, COUNT(*) AS row_count FROM BRONZE.RAW_CUSTOMERS
UNION ALL SELECT '1. BRONZE', 'RAW_PRODUCTS',    COUNT(*) FROM BRONZE.RAW_PRODUCTS
UNION ALL SELECT '1. BRONZE', 'RAW_ORDERS',      COUNT(*) FROM BRONZE.RAW_ORDERS
UNION ALL SELECT '1. BRONZE', 'RAW_ORDER_ITEMS',  COUNT(*) FROM BRONZE.RAW_ORDER_ITEMS
UNION ALL SELECT '2. SILVER', 'DIM_CUSTOMERS',    COUNT(*) FROM SILVER.DIM_CUSTOMERS
UNION ALL SELECT '2. SILVER', 'DIM_PRODUCTS',     COUNT(*) FROM SILVER.DIM_PRODUCTS
UNION ALL SELECT '2. SILVER', 'FACT_ORDERS',      COUNT(*) FROM SILVER.FACT_ORDERS
UNION ALL SELECT '3. GOLD',   'DAILY_SALES_SUMMARY',       COUNT(*) FROM GOLD.DAILY_SALES_SUMMARY
UNION ALL SELECT '3. GOLD',   'CUSTOMER_LIFETIME_VALUE',   COUNT(*) FROM GOLD.CUSTOMER_LIFETIME_VALUE
UNION ALL SELECT '3. GOLD',   'PRODUCT_PERFORMANCE',       COUNT(*) FROM GOLD.PRODUCT_PERFORMANCE
ORDER BY layer, object_name;

-- -----------------------------------------------------------
-- 15b. Pipeline object inventory
-- -----------------------------------------------------------
SELECT 'Stream' AS object_type, STREAM_NAME AS object_name, STALE AS status
FROM TABLE(INFORMATION_SCHEMA.STREAMS())
WHERE STREAM_CATALOG = 'ECOMMERCE_DW';

SELECT 'Task' AS object_type, NAME AS object_name, STATE AS status
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(
    SCHEDULED_TIME_RANGE_START => DATEADD('hour', -1, CURRENT_TIMESTAMP())
))
WHERE DATABASE_NAME = 'ECOMMERCE_DW'
LIMIT 10;

SHOW DYNAMIC TABLES IN DATABASE ECOMMERCE_DW;

-- -----------------------------------------------------------
-- 15c. End-to-end lineage for Customer #1 (Alice Johnson)
-- Trace data from BRONZE through SILVER to GOLD
-- -----------------------------------------------------------
SELECT '1. BRONZE (raw)' AS layer,
       CUSTOMER_ID, FIRST_NAME, LAST_NAME, EMAIL,
       ADDRESS:city::VARCHAR AS city_or_metric
FROM BRONZE.RAW_CUSTOMERS WHERE CUSTOMER_ID = 1;

SELECT '2. SILVER (clean)' AS layer,
       CUSTOMER_ID, FULL_NAME, EMAIL, CITY AS city_or_metric
FROM SILVER.DIM_CUSTOMERS WHERE CUSTOMER_ID = 1;

SELECT '3. GOLD (analytics)' AS layer,
       CUSTOMER_ID, FULL_NAME,
       TOTAL_ORDERS::VARCHAR || ' orders, $' || TOTAL_SPEND::VARCHAR || ' total' AS city_or_metric,
       LOYALTY_TIER
FROM GOLD.CUSTOMER_LIFETIME_VALUE WHERE CUSTOMER_ID = 1;

-- -----------------------------------------------------------
-- 15d. Business summary
-- -----------------------------------------------------------
SELECT
    (SELECT COUNT(DISTINCT CUSTOMER_ID) FROM SILVER.DIM_CUSTOMERS)   AS total_customers,
    (SELECT COUNT(DISTINCT PRODUCT_ID) FROM SILVER.DIM_PRODUCTS)     AS total_products,
    (SELECT COUNT(DISTINCT ORDER_ID) FROM SILVER.FACT_ORDERS)        AS total_orders,
    (SELECT SUM(LINE_TOTAL) FROM SILVER.FACT_ORDERS)                 AS total_revenue,
    (SELECT ROUND(AVG(LINE_TOTAL), 2) FROM SILVER.FACT_ORDERS)       AS avg_line_amount,
    (SELECT MIN(ORDER_DATE) FROM SILVER.FACT_ORDERS)                 AS earliest_order,
    (SELECT MAX(ORDER_DATE) FROM SILVER.FACT_ORDERS)                 AS latest_order;


-- =====================================================================
-- SECTION 16: CLEANUP (OPTIONAL)
-- WARNING: This will permanently drop all objects created in this lab.
-- Only run this if you are completely finished and want to clean up.
-- =====================================================================

/*
-- Suspend tasks before dropping (avoids errors)
USE DATABASE ECOMMERCE_DW;
ALTER TASK BRONZE.TASK_PROCESS_CUSTOMERS SUSPEND;
ALTER TASK BRONZE.TASK_PROCESS_ORDERS SUSPEND;
ALTER TASK BRONZE.TASK_PROCESS_PRODUCTS SUSPEND;

-- Drop databases
DROP DATABASE IF EXISTS ECOMMERCE_DW;
DROP DATABASE IF EXISTS ECOMMERCE_DW_DEV;

-- Drop custom roles
USE ROLE SECURITYADMIN;
DROP ROLE IF EXISTS ECOMMERCE_ANALYST;
DROP ROLE IF EXISTS ECOMMERCE_ADMIN;

-- Drop warehouse
USE ROLE SYSADMIN;
DROP WAREHOUSE IF EXISTS ECOMMERCE_WH;
*/

-- =====================================================================
-- CONGRATULATIONS!
-- You have built a complete end-to-end data pipeline in Snowflake.
--
-- What this pipeline includes:
--   [Lab 01] Virtual warehouse for compute
--   [Lab 02] Database with Bronze/Silver/Gold schemas
--   [Lab 03] Sample data loading
--   [Lab 04] Join-based transformations
--   [Lab 05] Aggregate and window functions
--   [Lab 06] Semi-structured JSON processing
--   [Lab 07] Role-based access control
--   [Lab 08] Zero-copy cloning for dev/test
--   [Lab 09] Streams for CDC + Tasks for automation
--   [Lab 10] Stored procedures for transformation
--   [Lab 11] UDFs for reusable business logic
--   [Lab 12] Secure views for data sharing
--   [Lab 13] Dynamic tables for auto-refreshing aggregations
--   [Lab 14] Clustering keys for performance optimization
-- =====================================================================
