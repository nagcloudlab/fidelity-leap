-- ============================================================
-- SNOWFLAKE WORKSHOP: MASTER SETUP SCRIPT
-- ============================================================
-- Run this script FIRST before starting any labs.
-- It creates the workshop database, schemas, tables, and
-- loads sample data used throughout the workshop.
--
-- Role required: SYSADMIN (or ACCOUNTADMIN)
-- Estimated time: 2-3 minutes
-- ============================================================

-- ============================================================
-- STEP 1: Set context
-- ============================================================
USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;

-- ============================================================
-- STEP 2: Create Workshop Database & Schemas
-- ============================================================
CREATE DATABASE IF NOT EXISTS WORKSHOP_DB
    COMMENT = 'Snowflake Hands-On Workshop Database';

USE DATABASE WORKSHOP_DB;

-- Create schemas for different data layers
CREATE SCHEMA IF NOT EXISTS RAW
    COMMENT = 'Raw/landing zone for ingested data';

CREATE SCHEMA IF NOT EXISTS STAGING
    COMMENT = 'Staging area for cleaned/transformed data';

CREATE SCHEMA IF NOT EXISTS ANALYTICS
    COMMENT = 'Analytics-ready tables and views';

-- ============================================================
-- STEP 3: Create tables in RAW schema
-- ============================================================
USE SCHEMA RAW;

-- Customers table
CREATE OR REPLACE TABLE CUSTOMERS (
    CUSTOMER_ID     NUMBER(10,0)    NOT NULL,
    FIRST_NAME      VARCHAR(50)     NOT NULL,
    LAST_NAME       VARCHAR(50)     NOT NULL,
    EMAIL           VARCHAR(100)    NOT NULL,
    PHONE           VARCHAR(20),
    ADDRESS         VARCHAR(200),
    CITY            VARCHAR(50),
    STATE           VARCHAR(2),
    ZIP_CODE        VARCHAR(10),
    COUNTRY         VARCHAR(5)      DEFAULT 'US',
    SIGNUP_DATE     DATE,
    CUSTOMER_SEGMENT VARCHAR(20),
    CONSTRAINT PK_CUSTOMERS PRIMARY KEY (CUSTOMER_ID)
);

-- Products table
CREATE OR REPLACE TABLE PRODUCTS (
    PRODUCT_ID      NUMBER(10,0)    NOT NULL,
    PRODUCT_NAME    VARCHAR(100)    NOT NULL,
    CATEGORY        VARCHAR(50),
    SUB_CATEGORY    VARCHAR(50),
    BRAND           VARCHAR(50),
    PRICE           NUMBER(10,2)    NOT NULL,
    COST            NUMBER(10,2),
    WEIGHT_KG       NUMBER(5,2),
    IS_ACTIVE       BOOLEAN         DEFAULT TRUE,
    CREATED_DATE    DATE,
    CONSTRAINT PK_PRODUCTS PRIMARY KEY (PRODUCT_ID)
);

-- Orders table
CREATE OR REPLACE TABLE ORDERS (
    ORDER_ID        NUMBER(10,0)    NOT NULL,
    CUSTOMER_ID     NUMBER(10,0)    NOT NULL,
    ORDER_DATE      DATE            NOT NULL,
    SHIP_DATE       DATE,
    STATUS          VARCHAR(20)     NOT NULL,
    PAYMENT_METHOD  VARCHAR(30),
    SHIPPING_METHOD VARCHAR(20),
    SUBTOTAL        NUMBER(10,2),
    TAX             NUMBER(10,2),
    SHIPPING_COST   NUMBER(10,2),
    TOTAL_AMOUNT    NUMBER(10,2),
    CONSTRAINT PK_ORDERS PRIMARY KEY (ORDER_ID)
);

-- Order Items table
CREATE OR REPLACE TABLE ORDER_ITEMS (
    ORDER_ITEM_ID   NUMBER(10,0)    NOT NULL AUTOINCREMENT,
    ORDER_ID        NUMBER(10,0)    NOT NULL,
    PRODUCT_ID      NUMBER(10,0)    NOT NULL,
    QUANTITY        NUMBER(5,0)     NOT NULL DEFAULT 1,
    UNIT_PRICE      NUMBER(10,2)    NOT NULL,
    DISCOUNT_PCT    NUMBER(5,2)     DEFAULT 0,
    LINE_TOTAL      NUMBER(10,2),
    CONSTRAINT PK_ORDER_ITEMS PRIMARY KEY (ORDER_ITEM_ID)
);

-- Events table (semi-structured JSON data)
CREATE OR REPLACE TABLE EVENTS (
    EVENT_RAW       VARIANT NOT NULL,
    LOADED_AT       TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ============================================================
-- STEP 4: Load sample data into tables
-- ============================================================

-- Load Customers
INSERT INTO CUSTOMERS VALUES
(1001,'John','Smith','john.smith@email.com','555-0101','123 Main St','New York','NY','10001','US','2023-01-15','Premium'),
(1002,'Sarah','Johnson','sarah.j@email.com','555-0102','456 Oak Ave','Los Angeles','CA','90001','US','2023-02-20','Standard'),
(1003,'Michael','Williams','m.williams@email.com','555-0103','789 Pine Rd','Chicago','IL','60601','US','2023-03-10','Premium'),
(1004,'Emily','Brown','emily.b@email.com','555-0104','321 Elm St','Houston','TX','77001','US','2023-04-05','Basic'),
(1005,'David','Jones','d.jones@email.com','555-0105','654 Maple Dr','Phoenix','AZ','85001','US','2023-04-18','Standard'),
(1006,'Jessica','Davis','jess.davis@email.com','555-0106','987 Cedar Ln','Philadelphia','PA','19101','US','2023-05-22','Premium'),
(1007,'Robert','Miller','r.miller@email.com','555-0107','147 Birch Way','San Antonio','TX','78201','US','2023-06-01','Basic'),
(1008,'Amanda','Wilson','a.wilson@email.com','555-0108','258 Walnut St','San Diego','CA','92101','US','2023-06-15','Standard'),
(1009,'James','Moore','j.moore@email.com','555-0109','369 Spruce Ave','Dallas','TX','75201','US','2023-07-03','Premium'),
(1010,'Lisa','Taylor','l.taylor@email.com','555-0110','741 Ash Blvd','San Jose','CA','95101','US','2023-07-20','Standard'),
(1011,'Daniel','Anderson','d.anderson@email.com','555-0111','852 Poplar Ct','Austin','TX','73301','US','2023-08-11','Basic'),
(1012,'Jennifer','Thomas','j.thomas@email.com','555-0112','963 Willow Rd','Jacksonville','FL','32099','US','2023-08-25','Premium'),
(1013,'Christopher','Jackson','c.jackson@email.com','555-0113','159 Hickory Ln','San Francisco','CA','94101','US','2023-09-05','Standard'),
(1014,'Michelle','White','m.white@email.com','555-0114','267 Magnolia Dr','Columbus','OH','43085','US','2023-09-19','Basic'),
(1015,'Kevin','Harris','k.harris@email.com','555-0115','378 Cypress St','Charlotte','NC','28201','US','2023-10-02','Premium'),
(1016,'Rachel','Martin','r.martin@email.com','555-0116','489 Redwood Ave','Indianapolis','IN','46201','US','2023-10-14','Standard'),
(1017,'Andrew','Garcia','a.garcia@email.com','555-0117','591 Sequoia Blvd','Seattle','WA','98101','US','2023-11-01','Basic'),
(1018,'Stephanie','Martinez','s.martinez@email.com','555-0118','612 Sycamore Way','Denver','CO','80201','US','2023-11-18','Premium'),
(1019,'Brian','Robinson','b.robinson@email.com','555-0119','723 Chestnut Rd','Boston','MA','02101','US','2023-12-05','Standard'),
(1020,'Nicole','Clark','n.clark@email.com','555-0120','834 Juniper Ct','Nashville','TN','37201','US','2023-12-22','Premium');

-- Load Products
INSERT INTO PRODUCTS VALUES
(2001,'Wireless Mouse','Electronics','Accessories','TechPro',29.99,12.50,0.15,TRUE,'2023-01-01'),
(2002,'Mechanical Keyboard','Electronics','Accessories','TechPro',89.99,35.00,0.85,TRUE,'2023-01-01'),
(2003,'USB-C Hub','Electronics','Accessories','ConnectPlus',49.99,20.00,0.20,TRUE,'2023-01-15'),
(2004,'27 inch Monitor','Electronics','Displays','ViewMax',349.99,180.00,5.50,TRUE,'2023-02-01'),
(2005,'Laptop Stand','Electronics','Accessories','ErgoDesk',39.99,15.00,1.20,TRUE,'2023-02-15'),
(2006,'Running Shoes','Sports','Footwear','SpeedRun',119.99,45.00,0.65,TRUE,'2023-01-01'),
(2007,'Yoga Mat','Sports','Fitness','FlexFit',34.99,10.00,1.50,TRUE,'2023-01-01'),
(2008,'Water Bottle','Sports','Accessories','HydroMax',24.99,8.00,0.30,TRUE,'2023-03-01'),
(2009,'Bluetooth Headphones','Electronics','Audio','SoundWave',79.99,30.00,0.25,TRUE,'2023-01-15'),
(2010,'Desk Lamp','Home','Lighting','BrightLife',44.99,18.00,1.10,TRUE,'2023-04-01'),
(2011,'Coffee Maker','Home','Kitchen','BrewMaster',69.99,28.00,3.20,TRUE,'2023-01-01'),
(2012,'Backpack','Sports','Bags','TrailBlaze',59.99,22.00,0.90,TRUE,'2023-05-01'),
(2013,'Webcam HD','Electronics','Accessories','TechPro',54.99,20.00,0.18,TRUE,'2023-03-15'),
(2014,'Fitness Tracker','Electronics','Wearables','FitTech',129.99,50.00,0.05,TRUE,'2023-02-01'),
(2015,'Portable Charger','Electronics','Accessories','PowerUp',39.99,14.00,0.35,TRUE,'2023-06-01');

-- Load Orders
INSERT INTO ORDERS VALUES
(3001,1001,'2024-01-05','2024-01-08','Delivered','Credit Card','Standard',119.98,9.60,5.99,135.57),
(3002,1003,'2024-01-07','2024-01-09','Delivered','PayPal','Express',349.99,28.00,12.99,390.98),
(3003,1002,'2024-01-10','2024-01-13','Delivered','Credit Card','Standard',64.98,5.20,5.99,76.17),
(3004,1005,'2024-01-12','2024-01-15','Delivered','Debit Card','Standard',89.99,7.20,5.99,103.18),
(3005,1001,'2024-01-18','2024-01-20','Delivered','Credit Card','Express',79.99,6.40,12.99,99.38),
(3006,1008,'2024-01-22','2024-01-25','Delivered','PayPal','Standard',154.98,12.40,5.99,173.37),
(3007,1010,'2024-01-25','2024-01-28','Delivered','Credit Card','Standard',34.99,2.80,5.99,43.78),
(3008,1006,'2024-02-01','2024-02-04','Delivered','Credit Card','Express',209.98,16.80,12.99,239.77),
(3009,1012,'2024-02-05','2024-02-07','Delivered','Debit Card','Standard',129.99,10.40,5.99,146.38),
(3010,1004,'2024-02-08','2024-02-11','Delivered','PayPal','Standard',44.99,3.60,5.99,54.58),
(3011,1015,'2024-02-14','2024-02-16','Delivered','Credit Card','Express',249.98,20.00,12.99,282.97),
(3012,1009,'2024-02-18','2024-02-21','Delivered','Credit Card','Standard',59.99,4.80,5.99,70.78),
(3013,1003,'2024-02-22','2024-02-25','Delivered','PayPal','Standard',94.98,7.60,5.99,108.57),
(3014,1007,'2024-03-01','2024-03-04','Delivered','Debit Card','Standard',29.99,2.40,5.99,38.38),
(3015,1018,'2024-03-05','2024-03-07','Delivered','Credit Card','Express',179.98,14.40,12.99,207.37),
(3016,1020,'2024-03-10','2024-03-13','Delivered','Credit Card','Standard',69.99,5.60,5.99,81.58),
(3017,1001,'2024-03-15','2024-03-18','Delivered','PayPal','Standard',139.98,11.20,5.99,157.17),
(3018,1013,'2024-03-20','2024-03-22','Delivered','Credit Card','Express',54.99,4.40,12.99,72.38),
(3019,1011,'2024-03-25','2024-03-28','Delivered','Debit Card','Standard',89.99,7.20,5.99,103.18),
(3020,1006,'2024-04-01','2024-04-04','Delivered','Credit Card','Standard',319.98,25.60,5.99,351.57),
(3021,1002,'2024-04-05','2024-04-08','Delivered','PayPal','Express',74.98,6.00,12.99,93.97),
(3022,1016,'2024-04-10','2024-04-13','Delivered','Credit Card','Standard',109.98,8.80,5.99,124.77),
(3023,1019,'2024-04-15','2024-04-18','Delivered','Debit Card','Standard',39.99,3.20,5.99,49.18),
(3024,1005,'2024-04-20','2024-04-23','Shipped','Credit Card','Standard',164.98,13.20,5.99,184.17),
(3025,1014,'2024-04-25',NULL,'Processing','PayPal','Express',224.98,18.00,12.99,255.97),
(3026,1020,'2024-04-28',NULL,'Processing','Credit Card','Standard',49.99,4.00,5.99,59.98),
(3027,1009,'2024-05-01',NULL,'Pending','Debit Card','Standard',299.98,24.00,5.99,329.97),
(3028,1012,'2024-05-03',NULL,'Pending','Credit Card','Express',84.98,6.80,12.99,104.77),
(3029,1001,'2024-05-05',NULL,'Pending','PayPal','Standard',59.99,4.80,5.99,70.78),
(3030,1017,'2024-05-08',NULL,'Pending','Credit Card','Standard',119.99,9.60,5.99,135.58);

-- Load Order Items
INSERT INTO ORDER_ITEMS (ORDER_ID, PRODUCT_ID, QUANTITY, UNIT_PRICE, DISCOUNT_PCT, LINE_TOTAL) VALUES
(3001,2001,1,29.99,0,29.99),(3001,2002,1,89.99,0,89.99),
(3002,2004,1,349.99,0,349.99),
(3003,2007,1,34.99,0,34.99),(3003,2001,1,29.99,0,29.99),
(3004,2002,1,89.99,0,89.99),
(3005,2009,1,79.99,0,79.99),
(3006,2010,1,44.99,0,44.99),(3006,2011,1,69.99,0,69.99),(3006,2015,1,39.99,0,39.99),
(3007,2007,1,34.99,0,34.99),
(3008,2006,1,119.99,0,119.99),(3008,2002,1,89.99,0,89.99),
(3009,2014,1,129.99,0,129.99),
(3010,2010,1,44.99,0,44.99),
(3011,2004,1,349.99,15,297.49),(3011,2003,1,49.99,0,49.99),
(3012,2012,1,59.99,0,59.99),
(3013,2005,1,39.99,0,39.99),(3013,2013,1,54.99,0,54.99),
(3014,2001,1,29.99,0,29.99),
(3015,2009,1,79.99,0,79.99),(3015,2006,1,119.99,10,107.99),
(3016,2011,1,69.99,0,69.99),
(3017,2002,1,89.99,0,89.99),(3017,2003,1,49.99,0,49.99),
(3018,2013,1,54.99,0,54.99),
(3019,2002,1,89.99,0,89.99),
(3020,2004,1,349.99,10,314.99),(3020,2005,1,39.99,0,39.99),
(3021,2007,1,34.99,0,34.99),(3021,2015,1,39.99,0,39.99),
(3022,2006,1,119.99,10,107.99),(3022,2001,1,29.99,0,29.99),
(3023,2015,1,39.99,0,39.99),
(3024,2009,1,79.99,0,79.99),(3024,2002,1,89.99,5,85.49),
(3025,2014,1,129.99,0,129.99),(3025,2006,1,119.99,5,113.99),
(3026,2003,1,49.99,0,49.99),
(3027,2004,1,349.99,10,314.99),
(3028,2009,1,79.99,0,79.99),(3028,2001,1,29.99,10,26.99),
(3029,2012,1,59.99,0,59.99),
(3030,2006,1,119.99,0,119.99);

-- Load Events (JSON data)
INSERT INTO EVENTS (EVENT_RAW)
SELECT PARSE_JSON(column1) FROM VALUES
('{"event_id":"evt-001","customer_id":1001,"event_type":"page_view","page":"/products/electronics","timestamp":"2024-01-05T10:23:45Z","device":{"type":"desktop","browser":"Chrome","os":"Windows"},"session_id":"sess-a1b2c3"}'),
('{"event_id":"evt-002","customer_id":1001,"event_type":"add_to_cart","page":"/products/2001","timestamp":"2024-01-05T10:25:12Z","device":{"type":"desktop","browser":"Chrome","os":"Windows"},"session_id":"sess-a1b2c3","product_id":2001}'),
('{"event_id":"evt-003","customer_id":1001,"event_type":"add_to_cart","page":"/products/2002","timestamp":"2024-01-05T10:26:30Z","device":{"type":"desktop","browser":"Chrome","os":"Windows"},"session_id":"sess-a1b2c3","product_id":2002}'),
('{"event_id":"evt-004","customer_id":1001,"event_type":"checkout","page":"/checkout","timestamp":"2024-01-05T10:30:00Z","device":{"type":"desktop","browser":"Chrome","os":"Windows"},"session_id":"sess-a1b2c3","order_id":3001}'),
('{"event_id":"evt-005","customer_id":1003,"event_type":"page_view","page":"/products/displays","timestamp":"2024-01-07T14:10:00Z","device":{"type":"mobile","browser":"Safari","os":"iOS"},"session_id":"sess-d4e5f6"}'),
('{"event_id":"evt-006","customer_id":1003,"event_type":"add_to_cart","page":"/products/2004","timestamp":"2024-01-07T14:15:22Z","device":{"type":"mobile","browser":"Safari","os":"iOS"},"session_id":"sess-d4e5f6","product_id":2004}'),
('{"event_id":"evt-007","customer_id":1003,"event_type":"checkout","page":"/checkout","timestamp":"2024-01-07T14:20:45Z","device":{"type":"mobile","browser":"Safari","os":"iOS"},"session_id":"sess-d4e5f6","order_id":3002}'),
('{"event_id":"evt-008","customer_id":1002,"event_type":"page_view","page":"/products/sports","timestamp":"2024-01-10T09:05:00Z","device":{"type":"desktop","browser":"Firefox","os":"MacOS"},"session_id":"sess-g7h8i9"}'),
('{"event_id":"evt-009","customer_id":1002,"event_type":"search","page":"/search?q=yoga+mat","timestamp":"2024-01-10T09:07:30Z","device":{"type":"desktop","browser":"Firefox","os":"MacOS"},"session_id":"sess-g7h8i9","search_query":"yoga mat"}'),
('{"event_id":"evt-010","customer_id":1002,"event_type":"add_to_cart","page":"/products/2007","timestamp":"2024-01-10T09:08:45Z","device":{"type":"desktop","browser":"Firefox","os":"MacOS"},"session_id":"sess-g7h8i9","product_id":2007}');

-- ============================================================
-- STEP 5: Create views in ANALYTICS schema
-- ============================================================
USE SCHEMA ANALYTICS;

-- Customer Order Summary view
CREATE OR REPLACE VIEW V_CUSTOMER_ORDER_SUMMARY AS
SELECT
    c.CUSTOMER_ID,
    c.FIRST_NAME || ' ' || c.LAST_NAME AS CUSTOMER_NAME,
    c.EMAIL,
    c.CUSTOMER_SEGMENT,
    COUNT(DISTINCT o.ORDER_ID) AS TOTAL_ORDERS,
    SUM(o.TOTAL_AMOUNT) AS TOTAL_SPENT,
    AVG(o.TOTAL_AMOUNT) AS AVG_ORDER_VALUE,
    MIN(o.ORDER_DATE) AS FIRST_ORDER_DATE,
    MAX(o.ORDER_DATE) AS LAST_ORDER_DATE
FROM RAW.CUSTOMERS c
LEFT JOIN RAW.ORDERS o ON c.CUSTOMER_ID = o.CUSTOMER_ID
GROUP BY c.CUSTOMER_ID, c.FIRST_NAME, c.LAST_NAME, c.EMAIL, c.CUSTOMER_SEGMENT;

-- Product Sales Summary view
CREATE OR REPLACE VIEW V_PRODUCT_SALES_SUMMARY AS
SELECT
    p.PRODUCT_ID,
    p.PRODUCT_NAME,
    p.CATEGORY,
    p.BRAND,
    p.PRICE,
    p.COST,
    COUNT(DISTINCT oi.ORDER_ID) AS TIMES_ORDERED,
    SUM(oi.QUANTITY) AS TOTAL_UNITS_SOLD,
    SUM(oi.LINE_TOTAL) AS TOTAL_REVENUE,
    SUM(oi.LINE_TOTAL) - (SUM(oi.QUANTITY) * p.COST) AS GROSS_PROFIT
FROM RAW.PRODUCTS p
LEFT JOIN RAW.ORDER_ITEMS oi ON p.PRODUCT_ID = oi.PRODUCT_ID
GROUP BY p.PRODUCT_ID, p.PRODUCT_NAME, p.CATEGORY, p.BRAND, p.PRICE, p.COST;

-- ============================================================
-- STEP 6: Verify setup
-- ============================================================
USE SCHEMA RAW;

SELECT 'CUSTOMERS' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM CUSTOMERS
UNION ALL
SELECT 'PRODUCTS', COUNT(*) FROM PRODUCTS
UNION ALL
SELECT 'ORDERS', COUNT(*) FROM ORDERS
UNION ALL
SELECT 'ORDER_ITEMS', COUNT(*) FROM ORDER_ITEMS
UNION ALL
SELECT 'EVENTS', COUNT(*) FROM EVENTS;

-- ============================================================
-- SETUP COMPLETE!
-- You should see:
--   CUSTOMERS:   20 rows
--   PRODUCTS:    15 rows
--   ORDERS:      30 rows
--   ORDER_ITEMS: 40 rows
--   EVENTS:      10 rows
--
-- You are ready to start the workshop labs!
-- ============================================================
