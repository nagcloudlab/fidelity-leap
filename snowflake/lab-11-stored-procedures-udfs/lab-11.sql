/***********************************************************************
  LAB 11: STORED PROCEDURES & USER-DEFINED FUNCTIONS (UDFs)

  Objective : Learn to create reusable logic with stored procedures
              and UDFs in Snowflake.
  Duration  : 35 minutes
  Database  : WORKSHOP_DB
***********************************************************************/

-- =====================================================================
-- SECTION 0: ENVIRONMENT SETUP
-- =====================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE WORKSHOP_WH;
USE DATABASE WORKSHOP_DB;
USE SCHEMA PUBLIC;

-- Create sample tables for the lab
CREATE OR REPLACE TABLE orders (
    order_id       INT AUTOINCREMENT START 1 INCREMENT 1,
    customer_email VARCHAR(255),
    order_date     DATE,
    amount         NUMBER(10,2),
    status         VARCHAR(20)
);

INSERT INTO orders (customer_email, order_date, amount, status)
VALUES
    ('alice.jones@example.com',   DATEADD(DAY, -10,  CURRENT_DATE()), 250.00,  'completed'),
    ('bob.smith@example.com',     DATEADD(DAY, -45,  CURRENT_DATE()), 125.50,  'completed'),
    ('carol.white@example.com',   DATEADD(DAY, -400, CURRENT_DATE()), 89.99,   'completed'),
    ('dave.brown@example.com',    DATEADD(DAY, -500, CURRENT_DATE()), 340.00,  'completed'),
    ('eve.davis@example.com',     DATEADD(DAY, -5,   CURRENT_DATE()), 475.25,  'pending'),
    ('frank.miller@example.com',  DATEADD(DAY, -200, CURRENT_DATE()), 60.00,   'cancelled'),
    ('grace.wilson@example.com',  DATEADD(DAY, -30,  CURRENT_DATE()), 199.99,  'completed'),
    ('hank.taylor@example.com',   DATEADD(DAY, -700, CURRENT_DATE()), 15.00,   'completed'),
    (NULL,                        DATEADD(DAY, -20,  CURRENT_DATE()), 100.00,  'pending'),
    ('iris.lee@example.com',      DATEADD(DAY, -2,   CURRENT_DATE()), 550.00,  'completed');

CREATE OR REPLACE TABLE monthly_reports (
    report_month   VARCHAR(7),
    total_orders   INT,
    total_revenue  NUMBER(12,2),
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

CREATE OR REPLACE TABLE json_events (
    event_id   INT AUTOINCREMENT START 1 INCREMENT 1,
    raw_json   VARIANT
);

INSERT INTO json_events (raw_json)
SELECT PARSE_JSON(column1)
FROM VALUES
    ('{"event":"login","user":"alice","timestamp":"2025-01-15T08:30:00Z","details":{"ip":"192.168.1.1","browser":"Chrome"}}'),
    ('{"event":"purchase","user":"bob","timestamp":"2025-01-15T09:15:00Z","details":{"item":"Widget","price":29.99}}'),
    ('{"event":"login","user":"carol","timestamp":"2025-01-15T10:00:00Z","details":{"ip":"10.0.0.5","browser":"Firefox"}}'),
    ('{"event":"logout","user":"alice","timestamp":"2025-01-15T11:45:00Z","details":{}}');

-- Verify setup
SELECT 'orders' AS table_name, COUNT(*) AS row_count FROM orders
UNION ALL
SELECT 'monthly_reports', COUNT(*) FROM monthly_reports
UNION ALL
SELECT 'json_events', COUNT(*) FROM json_events;


-- =====================================================================
-- SECTION 1: SIMPLE SQL STORED PROCEDURE
-- Purpose: Delete orders older than a specified number of days.
-- =====================================================================

-- This procedure uses plain SQL with Snowflake Scripting.
-- EXECUTE AS CALLER means it runs with the caller's privileges.

CREATE OR REPLACE PROCEDURE cleanup_old_orders(days_threshold FLOAT)
    RETURNS VARCHAR
    LANGUAGE SQL
    EXECUTE AS CALLER
    COMMENT = 'Deletes completed orders older than the given number of days'
AS
$$
DECLARE
    rows_deleted INT;
BEGIN
    DELETE FROM orders
    WHERE order_date < DATEADD(DAY, -:days_threshold, CURRENT_DATE())
      AND status = 'completed';

    rows_deleted := SQLROWCOUNT;
    RETURN 'Cleanup complete. Rows deleted: ' || :rows_deleted;
END;
$$;

-- Call the procedure to delete orders older than 365 days
CALL cleanup_old_orders(365);

-- Verify: the very old completed orders should be gone
SELECT * FROM orders ORDER BY order_date;


-- =====================================================================
-- SECTION 2: STORED PROCEDURE WITH INPUT PARAMETERS
-- Purpose: Insert a new order and return the generated order ID.
-- =====================================================================

CREATE OR REPLACE PROCEDURE insert_order(
    p_email    VARCHAR,
    p_amount   FLOAT,
    p_status   VARCHAR
)
    RETURNS VARCHAR
    LANGUAGE SQL
    EXECUTE AS CALLER
    COMMENT = 'Inserts a new order and returns a confirmation message'
AS
$$
BEGIN
    INSERT INTO orders (customer_email, order_date, amount, status)
    VALUES (:p_email, CURRENT_DATE(), :p_amount, :p_status);

    RETURN 'Order inserted for ' || :p_email || ' with amount $' || :p_amount;
END;
$$;

-- Call with parameters
CALL insert_order('new.customer@example.com', 299.99, 'pending');

-- Verify the new row
SELECT * FROM orders WHERE customer_email = 'new.customer@example.com';


-- =====================================================================
-- SECTION 3: SNOWFLAKE SCRIPTING -- VARIABLES, IF/ELSE, FOR LOOPS
-- Purpose: Generate a monthly report using procedural logic.
-- =====================================================================

CREATE OR REPLACE PROCEDURE generate_monthly_report(p_year INT)
    RETURNS VARCHAR
    LANGUAGE SQL
    EXECUTE AS CALLER
    COMMENT = 'Generates monthly order summaries for the given year using Snowflake Scripting'
AS
$$
DECLARE
    v_month        INT DEFAULT 1;
    v_month_str    VARCHAR;
    v_total_orders INT;
    v_total_rev    NUMBER(12,2);
    v_report_count INT DEFAULT 0;
    cur CURSOR FOR
        SELECT COUNT(*)            AS cnt,
               NVL(SUM(amount), 0) AS rev
        FROM orders
        WHERE YEAR(order_date)  = :p_year
          AND MONTH(order_date) = :v_month;
BEGIN
    -- Loop through all 12 months
    FOR v_month IN 1 TO 12 DO
        v_month_str := :p_year || '-' || LPAD(:v_month, 2, '0');

        OPEN cur;
        FETCH cur INTO v_total_orders, v_total_rev;
        CLOSE cur;

        -- Only insert a report row if there were orders that month
        IF (:v_total_orders > 0) THEN
            INSERT INTO monthly_reports (report_month, total_orders, total_revenue)
            VALUES (:v_month_str, :v_total_orders, :v_total_rev);

            v_report_count := :v_report_count + 1;
        END IF;
    END FOR;

    IF (:v_report_count = 0) THEN
        RETURN 'No orders found for year ' || :p_year;
    ELSE
        RETURN 'Generated ' || :v_report_count || ' monthly report(s) for year ' || :p_year;
    END IF;
END;
$$;

-- Generate reports for the current year
CALL generate_monthly_report(2025);

-- View the generated reports
SELECT * FROM monthly_reports ORDER BY report_month;


-- =====================================================================
-- SECTION 4: JAVASCRIPT STORED PROCEDURE
-- Purpose: Process JSON events and return a summary.
-- =====================================================================

CREATE OR REPLACE PROCEDURE process_json_data()
    RETURNS VARIANT
    LANGUAGE JAVASCRIPT
    EXECUTE AS CALLER
    COMMENT = 'Reads json_events table and returns a summary object'
AS
$$
    // Query the json_events table
    var stmt = snowflake.createStatement({
        sqlText: "SELECT raw_json FROM json_events"
    });
    var result = stmt.execute();

    // Build a summary
    var summary = {
        total_events: 0,
        event_types: {},
        users: []
    };
    var userSet = {};

    while (result.next()) {
        var event = JSON.parse(result.getColumnValue(1));
        summary.total_events++;

        // Count event types
        var eventType = event.event || "unknown";
        if (summary.event_types[eventType]) {
            summary.event_types[eventType]++;
        } else {
            summary.event_types[eventType] = 1;
        }

        // Collect unique users
        if (event.user && !userSet[event.user]) {
            userSet[event.user] = true;
            summary.users.push(event.user);
        }
    }

    return summary;
$$;

-- Call the JavaScript procedure
CALL process_json_data();


-- =====================================================================
-- SECTION 5: SCALAR SQL UDF -- Calculate Discount
-- Purpose: Return the discounted price given an original price and
--          a discount percentage.
-- =====================================================================

CREATE OR REPLACE FUNCTION calculate_discount(
    original_price NUMBER(10,2),
    discount_pct   NUMBER(5,2)
)
    RETURNS NUMBER(10,2)
    LANGUAGE SQL
    IMMUTABLE
    COMMENT = 'Returns the price after applying the given discount percentage'
AS
$$
    original_price * (1 - discount_pct / 100)
$$;

-- Use the UDF in a SELECT
SELECT
    order_id,
    amount                              AS original_amount,
    calculate_discount(amount, 10)      AS after_10pct_discount,
    calculate_discount(amount, 25)      AS after_25pct_discount
FROM orders
ORDER BY order_id;


-- =====================================================================
-- SECTION 6: SCALAR SQL UDF -- Email Masking
-- Purpose: Mask an email address for privacy compliance.
--          alice.jones@example.com  -->  ali***@example.com
-- =====================================================================

CREATE OR REPLACE FUNCTION mask_email(email VARCHAR)
    RETURNS VARCHAR
    LANGUAGE SQL
    IMMUTABLE
    COMMENT = 'Masks an email address by hiding characters after the first 3 of the local part'
AS
$$
    CASE
        WHEN email IS NULL THEN NULL
        WHEN POSITION('@' IN email) <= 3 THEN
            REPEAT('*', POSITION('@' IN email) - 1) || SUBSTR(email, POSITION('@' IN email))
        ELSE
            SUBSTR(email, 1, 3) || REPEAT('*', POSITION('@' IN email) - 4) || SUBSTR(email, POSITION('@' IN email))
    END
$$;

-- Test the email masking UDF
SELECT
    customer_email,
    mask_email(customer_email) AS masked_email
FROM orders
ORDER BY order_id;


-- =====================================================================
-- SECTION 7: SCALAR JAVASCRIPT UDF -- Title Case
-- Purpose: Convert a string to Title Case using JavaScript.
-- =====================================================================

CREATE OR REPLACE FUNCTION title_case(input_str VARCHAR)
    RETURNS VARCHAR
    LANGUAGE JAVASCRIPT
    IMMUTABLE
    COMMENT = 'Converts a string to Title Case using JavaScript'
AS
$$
    if (INPUT_STR === null || INPUT_STR === undefined) {
        return null;
    }
    return INPUT_STR
        .toLowerCase()
        .replace(/(?:^|\s)\S/g, function(match) {
            return match.toUpperCase();
        });
$$;

-- Test the JavaScript UDF
SELECT
    title_case('hello world')          AS test1,
    title_case('snowflake DATA cloud') AS test2,
    title_case('alice jones')          AS test3,
    title_case(NULL)                   AS test4;


-- =====================================================================
-- SECTION 8: SQL TABLE UDF (UDTF) -- Generate Date Series
-- Purpose: Return a table of dates between a start and end date.
-- =====================================================================

CREATE OR REPLACE FUNCTION generate_date_series(
    start_date DATE,
    end_date   DATE
)
    RETURNS TABLE(date_value DATE)
    LANGUAGE SQL
    COMMENT = 'Returns one row per day between start_date and end_date (inclusive)'
AS
$$
    SELECT DATEADD(DAY, seq4(), start_date) AS date_value
    FROM TABLE(GENERATOR(ROWCOUNT => 3660))
    WHERE date_value <= end_date
$$;

-- Use the table UDF in a FROM clause
SELECT date_value, DAYNAME(date_value) AS day_of_week
FROM TABLE(generate_date_series('2025-01-01'::DATE, '2025-01-14'::DATE))
ORDER BY date_value;

-- Join the date series with orders to find days with no orders
SELECT
    d.date_value,
    COUNT(o.order_id) AS order_count
FROM TABLE(generate_date_series(
        DATEADD(DAY, -30, CURRENT_DATE()),
        CURRENT_DATE()
    )) d
    LEFT JOIN orders o ON o.order_date = d.date_value
GROUP BY d.date_value
ORDER BY d.date_value;


-- =====================================================================
-- SECTION 9: FUNCTION OVERLOADING
-- Purpose: Create two versions of format_name with different
--          parameter signatures.
-- =====================================================================

-- Version 1: Single full-name parameter
CREATE OR REPLACE FUNCTION format_name(full_name VARCHAR)
    RETURNS VARCHAR
    LANGUAGE SQL
    IMMUTABLE
    COMMENT = 'Trims and upper-cases a full name'
AS
$$
    UPPER(TRIM(full_name))
$$;

-- Version 2: Separate first and last name parameters
CREATE OR REPLACE FUNCTION format_name(first_name VARCHAR, last_name VARCHAR)
    RETURNS VARCHAR
    LANGUAGE SQL
    IMMUTABLE
    COMMENT = 'Combines first and last name into upper-cased full name'
AS
$$
    UPPER(TRIM(first_name) || ' ' || TRIM(last_name))
$$;

-- Snowflake resolves the correct overload based on argument count
SELECT format_name('  alice jones  ')        AS single_arg_result;
SELECT format_name('  alice ', '  jones  ')  AS two_arg_result;


-- =====================================================================
-- SECTION 10: USING UDFs IN REAL QUERIES
-- =====================================================================

-- Combine multiple UDFs in a single query
SELECT
    order_id,
    mask_email(customer_email)          AS masked_email,
    order_date,
    amount                              AS original_price,
    calculate_discount(amount, 15)      AS discounted_price,
    status
FROM orders
WHERE amount > 100
ORDER BY order_date DESC;


-- =====================================================================
-- SECTION 11: PRACTICAL EXAMPLE -- DATA QUALITY CHECK PROCEDURE
-- Purpose: Validate the orders table and return a JSON quality report.
-- =====================================================================

CREATE OR REPLACE PROCEDURE check_data_quality(p_table_name VARCHAR)
    RETURNS VARIANT
    LANGUAGE JAVASCRIPT
    EXECUTE AS CALLER
    COMMENT = 'Runs data quality checks on the orders table and returns a JSON report'
AS
$$
    var report = {
        table: P_TABLE_NAME,
        checked_at: new Date().toISOString(),
        checks: []
    };

    // Check 1: Total row count
    var stmt1 = snowflake.createStatement({
        sqlText: "SELECT COUNT(*) FROM IDENTIFIER(?)",
        binds: [P_TABLE_NAME]
    });
    var res1 = stmt1.execute();
    res1.next();
    var totalRows = res1.getColumnValue(1);
    report.checks.push({
        check: "total_row_count",
        value: totalRows,
        status: totalRows > 0 ? "PASS" : "FAIL"
    });

    // Check 2: NULL emails
    var stmt2 = snowflake.createStatement({
        sqlText: "SELECT COUNT(*) FROM IDENTIFIER(?) WHERE customer_email IS NULL",
        binds: [P_TABLE_NAME]
    });
    var res2 = stmt2.execute();
    res2.next();
    var nullEmails = res2.getColumnValue(1);
    report.checks.push({
        check: "null_email_count",
        value: nullEmails,
        status: nullEmails === 0 ? "PASS" : "WARNING"
    });

    // Check 3: Negative amounts
    var stmt3 = snowflake.createStatement({
        sqlText: "SELECT COUNT(*) FROM IDENTIFIER(?) WHERE amount < 0",
        binds: [P_TABLE_NAME]
    });
    var res3 = stmt3.execute();
    res3.next();
    var negativeAmounts = res3.getColumnValue(1);
    report.checks.push({
        check: "negative_amount_count",
        value: negativeAmounts,
        status: negativeAmounts === 0 ? "PASS" : "FAIL"
    });

    // Check 4: Future-dated orders
    var stmt4 = snowflake.createStatement({
        sqlText: "SELECT COUNT(*) FROM IDENTIFIER(?) WHERE order_date > CURRENT_DATE()",
        binds: [P_TABLE_NAME]
    });
    var res4 = stmt4.execute();
    res4.next();
    var futureOrders = res4.getColumnValue(1);
    report.checks.push({
        check: "future_order_count",
        value: futureOrders,
        status: futureOrders === 0 ? "PASS" : "WARNING"
    });

    // Overall status
    var hasFail = report.checks.some(function(c) { return c.status === "FAIL"; });
    var hasWarn = report.checks.some(function(c) { return c.status === "WARNING"; });
    report.overall_status = hasFail ? "FAIL" : (hasWarn ? "WARNING" : "PASS");

    return report;
$$;

-- Run the data quality check
CALL check_data_quality('orders');


-- =====================================================================
-- SECTION 12: DESCRIBE AND SHOW METADATA
-- =====================================================================

-- List all procedures in the current schema
SHOW PROCEDURES IN SCHEMA WORKSHOP_DB.PUBLIC;

-- List all user-defined functions in the current schema
SHOW USER FUNCTIONS IN SCHEMA WORKSHOP_DB.PUBLIC;

-- Describe a specific procedure (include parameter types in signature)
DESCRIBE PROCEDURE cleanup_old_orders(FLOAT);

-- Describe a specific function
DESCRIBE FUNCTION calculate_discount(NUMBER, NUMBER);

-- Describe the overloaded function (note different signatures)
DESCRIBE FUNCTION format_name(VARCHAR);
DESCRIBE FUNCTION format_name(VARCHAR, VARCHAR);


-- =====================================================================
-- SECTION 13: PRACTICAL EXAMPLE -- DATE UTILITY PROCEDURE
-- Purpose: Snowflake Scripting procedure that returns the number of
--          business days (Mon-Fri) between two dates.
-- =====================================================================

CREATE OR REPLACE FUNCTION business_days_between(
    start_date DATE,
    end_date   DATE
)
    RETURNS INT
    LANGUAGE SQL
    IMMUTABLE
    COMMENT = 'Returns the count of weekdays (Mon-Fri) between two dates, inclusive'
AS
$$
    (SELECT COUNT(*)
     FROM TABLE(generate_date_series(start_date, end_date))
     WHERE DAYOFWEEK(date_value) NOT IN (0, 6)
    )
$$;

-- Test: business days in the first two weeks of January 2025
SELECT business_days_between('2025-01-01'::DATE, '2025-01-14'::DATE) AS biz_days;

-- Use it in a query: how many business days since each order?
SELECT
    order_id,
    order_date,
    business_days_between(order_date, CURRENT_DATE()) AS biz_days_since_order
FROM orders
ORDER BY order_date DESC;


-- =====================================================================
-- SECTION 14: CALLER'S RIGHTS vs OWNER'S RIGHTS DEMONSTRATION
-- =====================================================================

-- Owner's rights (default) -- runs as the role that created it
CREATE OR REPLACE PROCEDURE owner_rights_demo()
    RETURNS VARCHAR
    LANGUAGE SQL
    EXECUTE AS OWNER
AS
$$
BEGIN
    RETURN 'Running as OWNER. Current role: ' || CURRENT_ROLE();
END;
$$;

-- Caller's rights -- runs as the role of the person calling it
CREATE OR REPLACE PROCEDURE caller_rights_demo()
    RETURNS VARCHAR
    LANGUAGE SQL
    EXECUTE AS CALLER
AS
$$
BEGIN
    RETURN 'Running as CALLER. Current role: ' || CURRENT_ROLE();
END;
$$;

CALL owner_rights_demo();
CALL caller_rights_demo();


-- =====================================================================
-- SECTION 15: CLEANUP
-- Drop all objects created during this lab.
-- =====================================================================

-- Drop procedures
DROP PROCEDURE IF EXISTS cleanup_old_orders(FLOAT);
DROP PROCEDURE IF EXISTS insert_order(VARCHAR, FLOAT, VARCHAR);
DROP PROCEDURE IF EXISTS generate_monthly_report(FLOAT);
DROP PROCEDURE IF EXISTS process_json_data();
DROP PROCEDURE IF EXISTS check_data_quality(VARCHAR);
DROP PROCEDURE IF EXISTS owner_rights_demo();
DROP PROCEDURE IF EXISTS caller_rights_demo();

-- Drop functions
DROP FUNCTION IF EXISTS calculate_discount(NUMBER, NUMBER);
DROP FUNCTION IF EXISTS mask_email(VARCHAR);
DROP FUNCTION IF EXISTS title_case(VARCHAR);
DROP FUNCTION IF EXISTS generate_date_series(DATE, DATE);
DROP FUNCTION IF EXISTS format_name(VARCHAR);
DROP FUNCTION IF EXISTS format_name(VARCHAR, VARCHAR);
DROP FUNCTION IF EXISTS business_days_between(DATE, DATE);

-- Drop tables
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS monthly_reports;
DROP TABLE IF EXISTS json_events;

-- Verify cleanup
SHOW PROCEDURES IN SCHEMA WORKSHOP_DB.PUBLIC;
SHOW USER FUNCTIONS IN SCHEMA WORKSHOP_DB.PUBLIC;

/***********************************************************************
  END OF LAB 11

  Summary of what you learned:
  - SQL stored procedures with Snowflake Scripting (LET, IF/ELSE, FOR)
  - JavaScript stored procedures for complex logic
  - Scalar SQL and JavaScript UDFs
  - Table UDFs (UDTFs) for returning multiple rows
  - Function overloading with different parameter signatures
  - Caller's rights vs Owner's rights
  - DESCRIBE, SHOW, and metadata inspection
  - Practical patterns: email masking, data quality checks, date utilities
***********************************************************************/
