-- ============================================================================
-- LAB 14: PERFORMANCE TUNING
-- ============================================================================
-- Objective : Learn to analyze and optimize query performance in Snowflake
-- Duration  : 30 minutes
-- Topics    : Query Profile, caching, clustering, optimization tips, monitoring
-- ============================================================================

-- ============================================================================
-- SETUP
-- ============================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE WORKSHOP_DB;
USE SCHEMA PUBLIC;

-- Make sure the warehouse is running so caches are fresh
ALTER WAREHOUSE COMPUTE_WH RESUME IF SUSPENDED;


-- ============================================================================
-- SECTION 1: QUERY PROFILE
-- ============================================================================
-- The Query Profile is the most important debugging tool in Snowflake.
-- After running a query in Snowsight, click the "Query Profile" tab to see
-- a visual DAG of every operation (scan, join, aggregate, sort, etc.).
-- ============================================================================

-- --------------------------------------------------------------------------
-- 1a. Run a complex query so we have something interesting to inspect
-- --------------------------------------------------------------------------
-- This query joins three tables from the TPC-H sample data set, aggregates
-- revenue by nation and year, and sorts the results. After running it,
-- open the Query Profile in the Snowsight UI.

SELECT
    n.n_name                              AS nation,
    YEAR(o.o_orderdate)                   AS order_year,
    COUNT(*)                              AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS gross_revenue,
    AVG(l.l_quantity)                     AS avg_quantity
FROM
    SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS      o
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM  l ON o.o_orderkey = l.l_orderkey
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER   c ON o.o_custkey  = c.c_custkey
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.NATION     n ON c.c_nationkey = n.n_nationkey
WHERE
    o.o_orderdate BETWEEN '1995-01-01' AND '1996-12-31'
GROUP BY
    n.n_name,
    YEAR(o.o_orderdate)
ORDER BY
    nation,
    order_year;

-- >>> WHAT TO LOOK FOR IN THE QUERY PROFILE <<<
-- 1. Click "Query Profile" in the results panel.
-- 2. Find the node with the highest percentage of time (usually a TableScan
--    or Join node).
-- 3. On the right-side Statistics panel, look at:
--      - "Partitions scanned" vs "Partitions total"  (pruning efficiency)
--      - "Bytes scanned"
--      - "Percentage scanned from cache"  (warehouse SSD cache hits)
-- 4. Check for any "Spillage" indicators -- spill to local disk or remote
--    storage means the warehouse ran out of memory for that operation.

-- --------------------------------------------------------------------------
-- 1b. Use EXPLAIN to see the execution plan without actually running the query
-- --------------------------------------------------------------------------
-- EXPLAIN shows the logical plan Snowflake would use. It is fast because
-- no data is processed.

EXPLAIN
SELECT
    n.n_name                              AS nation,
    YEAR(o.o_orderdate)                   AS order_year,
    COUNT(*)                              AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS gross_revenue
FROM
    SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS      o
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM  l ON o.o_orderkey = l.l_orderkey
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER   c ON o.o_custkey  = c.c_custkey
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.NATION     n ON c.c_nationkey = n.n_nationkey
WHERE
    o.o_orderdate BETWEEN '1995-01-01' AND '1996-12-31'
GROUP BY
    n.n_name,
    YEAR(o.o_orderdate)
ORDER BY
    nation,
    order_year;

-- The output shows each operator (GlobalStats, Result, Sort, Aggregate,
-- JoinFilter, etc.) along with estimated row counts and expressions.

-- --------------------------------------------------------------------------
-- 1c. Query INFORMATION_SCHEMA.QUERY_HISTORY to find recent slow queries
-- --------------------------------------------------------------------------
-- This view holds the last 7 days of query history for the current account
-- (up to 10,000 rows). Useful for quickly spotting problem queries.

SELECT
    query_id,
    query_text,
    user_name,
    warehouse_name,
    execution_status,
    total_elapsed_time / 1000   AS elapsed_seconds,
    bytes_scanned,
    rows_produced,
    compilation_time / 1000     AS compile_seconds,
    execution_time / 1000       AS exec_seconds
FROM
    TABLE(INFORMATION_SCHEMA.QUERY_HISTORY(
        DATEADD('HOURS', -1, CURRENT_TIMESTAMP()),
        CURRENT_TIMESTAMP(),
        100
    ))
WHERE
    execution_status = 'SUCCESS'
ORDER BY
    total_elapsed_time DESC
LIMIT 10;


-- ============================================================================
-- SECTION 2: CACHING
-- ============================================================================
-- Snowflake has three cache layers:
--   1. Result Cache   -- exact result set, 24h, free, cloud services layer
--   2. Local Disk Cache (SSD) -- raw micro-partition data on warehouse nodes
--   3. Remote Disk Cache      -- original files in cloud object storage
-- ============================================================================

-- --------------------------------------------------------------------------
-- 2a. Demonstrate the Result Cache
-- --------------------------------------------------------------------------
-- Run this query and note the execution time.

SELECT
    l_returnflag,
    l_linestatus,
    COUNT(*)                                     AS cnt,
    SUM(l_quantity)                              AS sum_qty,
    SUM(l_extendedprice)                         AS sum_base_price,
    SUM(l_extendedprice * (1 - l_discount))      AS sum_disc_price,
    AVG(l_quantity)                              AS avg_qty,
    AVG(l_extendedprice)                         AS avg_price,
    AVG(l_discount)                              AS avg_disc
FROM
    SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM
GROUP BY
    l_returnflag,
    l_linestatus
ORDER BY
    l_returnflag,
    l_linestatus;

-- >>> Now run the EXACT SAME query again (copy-paste or re-execute). <<<
-- The second execution should return almost instantly (often < 100ms)
-- because Snowflake serves the result from the Result Cache.
--
-- In the Query Profile for the second run you will see:
--   "QUERY RESULT REUSE" -- meaning no warehouse compute was needed.

SELECT
    l_returnflag,
    l_linestatus,
    COUNT(*)                                     AS cnt,
    SUM(l_quantity)                              AS sum_qty,
    SUM(l_extendedprice)                         AS sum_base_price,
    SUM(l_extendedprice * (1 - l_discount))      AS sum_disc_price,
    AVG(l_quantity)                              AS avg_qty,
    AVG(l_extendedprice)                         AS avg_price,
    AVG(l_discount)                              AS avg_disc
FROM
    SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM
GROUP BY
    l_returnflag,
    l_linestatus
ORDER BY
    l_returnflag,
    l_linestatus;

-- --------------------------------------------------------------------------
-- 2b. Disable the Result Cache and observe the difference
-- --------------------------------------------------------------------------
-- When USE_CACHED_RESULT is FALSE, Snowflake will NOT serve results from
-- the result cache. The warehouse must do the work again.

ALTER SESSION SET USE_CACHED_RESULT = FALSE;

-- Run the same query a third time. This time it will NOT be instant because
-- the result cache is disabled. However, if the warehouse is still warm
-- (has not been suspended), the Local Disk Cache (SSD) may still speed
-- things up compared to a cold start.

SELECT
    l_returnflag,
    l_linestatus,
    COUNT(*)                                     AS cnt,
    SUM(l_quantity)                              AS sum_qty,
    SUM(l_extendedprice)                         AS sum_base_price,
    SUM(l_extendedprice * (1 - l_discount))      AS sum_disc_price,
    AVG(l_quantity)                              AS avg_qty,
    AVG(l_extendedprice)                         AS avg_price,
    AVG(l_discount)                              AS avg_disc
FROM
    SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM
GROUP BY
    l_returnflag,
    l_linestatus
ORDER BY
    l_returnflag,
    l_linestatus;

-- >>> Compare the execution time of this third run to the first run. <<<
-- If the warehouse was warm, the SSD cache likely helped and this run
-- may still be faster than the very first cold execution.

-- Re-enable the result cache for the rest of the lab
ALTER SESSION SET USE_CACHED_RESULT = TRUE;

-- --------------------------------------------------------------------------
-- 2c. Understanding Warehouse (SSD) Cache behavior
-- --------------------------------------------------------------------------
-- The local disk cache lives on the SSD drives of the warehouse compute
-- nodes. Key behaviors:
--
--   * Populated automatically when micro-partitions are read from remote
--     storage.
--   * Persists as long as the warehouse is running (not suspended).
--   * Cleared when the warehouse is suspended or resized.
--   * Shared across all queries on that warehouse.
--
-- To demonstrate: if you SUSPEND and then RESUME the warehouse, the SSD
-- cache is cleared. The next query will need to fetch data from remote
-- storage again (Layer 3), which is slower.
--
-- We will NOT suspend the warehouse here to keep the lab flowing, but
-- be aware of this behavior in production. Setting AUTO_SUSPEND too
-- aggressively (e.g., 60 seconds) can hurt performance if queries
-- frequently need the same data.


-- ============================================================================
-- SECTION 3: CLUSTERING
-- ============================================================================
-- Clustering keys tell Snowflake how to organize micro-partitions so that
-- queries filtering on those columns can prune more partitions.
-- ============================================================================

-- --------------------------------------------------------------------------
-- 3a. Create a large table to experiment with
-- --------------------------------------------------------------------------
-- We use the GENERATOR function to create 10 million rows with various
-- columns. This gives us enough data to see meaningful partition counts.

CREATE OR REPLACE TABLE WORKSHOP_DB.PUBLIC.PERF_TEST (
    id              NUMBER,
    category        VARCHAR(20),
    region          VARCHAR(20),
    sale_date       DATE,
    amount          NUMBER(12,2),
    quantity        NUMBER,
    description     VARCHAR(200)
);

INSERT INTO WORKSHOP_DB.PUBLIC.PERF_TEST
SELECT
    SEQ4()                                                          AS id,
    'CAT_' || UNIFORM(1, 50, RANDOM())                             AS category,
    CASE UNIFORM(1, 5, RANDOM())
        WHEN 1 THEN 'NORTH'
        WHEN 2 THEN 'SOUTH'
        WHEN 3 THEN 'EAST'
        WHEN 4 THEN 'WEST'
        ELSE        'CENTRAL'
    END                                                             AS region,
    DATEADD(DAY, UNIFORM(0, 1825, RANDOM()), '2020-01-01')         AS sale_date,
    ROUND(UNIFORM(1, 10000, RANDOM()) + UNIFORM(0, 99, RANDOM()) / 100, 2) AS amount,
    UNIFORM(1, 500, RANDOM())                                      AS quantity,
    'Item description for row ' || SEQ4()                           AS description
FROM
    TABLE(GENERATOR(ROWCOUNT => 10000000));

-- Verify the row count
SELECT COUNT(*) AS row_count FROM WORKSHOP_DB.PUBLIC.PERF_TEST;

-- --------------------------------------------------------------------------
-- 3b. Check clustering information BEFORE adding a clustering key
-- --------------------------------------------------------------------------
-- SYSTEM$CLUSTERING_INFORMATION returns a JSON object describing how well
-- the table is clustered on the specified columns.

SELECT SYSTEM$CLUSTERING_INFORMATION('WORKSHOP_DB.PUBLIC.PERF_TEST', '(sale_date)');

-- Key fields in the output:
--   "average_overlaps"  -- avg number of overlapping partitions per value range
--   "average_depth"     -- avg depth (lower is better; 1 = perfect)
--   "total_partition_count" -- how many micro-partitions the table has

-- Also check the simpler clustering depth function:
SELECT SYSTEM$CLUSTERING_DEPTH('WORKSHOP_DB.PUBLIC.PERF_TEST', '(sale_date)');

-- --------------------------------------------------------------------------
-- 3c. Run a filtered query and note the pruning stats
-- --------------------------------------------------------------------------
-- Before clustering, this query may scan many (or all) partitions because
-- the data was loaded in random order.

-- Disable result cache so we see real scan behavior every time
ALTER SESSION SET USE_CACHED_RESULT = FALSE;

SELECT
    region,
    COUNT(*)          AS cnt,
    SUM(amount)       AS total_amount,
    AVG(quantity)     AS avg_qty
FROM
    WORKSHOP_DB.PUBLIC.PERF_TEST
WHERE
    sale_date BETWEEN '2023-01-01' AND '2023-03-31'
GROUP BY
    region
ORDER BY
    total_amount DESC;

-- >>> CHECK THE QUERY PROFILE <<<
-- Look at "Partitions scanned" vs "Partitions total" on the TableScan node.
-- With random data, you will likely see most or all partitions scanned.

-- --------------------------------------------------------------------------
-- 3d. Add a clustering key on sale_date
-- --------------------------------------------------------------------------
-- This tells Snowflake's Automatic Clustering service to re-organize the
-- micro-partitions so that rows with similar sale_date values are grouped
-- together.

ALTER TABLE WORKSHOP_DB.PUBLIC.PERF_TEST CLUSTER BY (sale_date);

-- Verify the clustering key was set
SHOW TABLES LIKE 'PERF_TEST' IN SCHEMA WORKSHOP_DB.PUBLIC;

-- --------------------------------------------------------------------------
-- 3e. Check clustering information AFTER defining the key
-- --------------------------------------------------------------------------
-- Note: Automatic Clustering works in the background. For a 10M-row table,
-- it may take a few minutes to fully re-cluster. The depth may not improve
-- immediately. In production, you would check back after some time.

SELECT SYSTEM$CLUSTERING_INFORMATION('WORKSHOP_DB.PUBLIC.PERF_TEST', '(sale_date)');
SELECT SYSTEM$CLUSTERING_DEPTH('WORKSHOP_DB.PUBLIC.PERF_TEST', '(sale_date)');

-- --------------------------------------------------------------------------
-- 3f. Run the same filtered query again to compare pruning
-- --------------------------------------------------------------------------
-- If Automatic Clustering has had time to run, you should see fewer
-- partitions scanned. Even partial re-clustering can reduce the count.

SELECT
    region,
    COUNT(*)          AS cnt,
    SUM(amount)       AS total_amount,
    AVG(quantity)     AS avg_qty
FROM
    WORKSHOP_DB.PUBLIC.PERF_TEST
WHERE
    sale_date BETWEEN '2023-01-01' AND '2023-03-31'
GROUP BY
    region
ORDER BY
    total_amount DESC;

-- >>> CHECK THE QUERY PROFILE AGAIN <<<
-- Compare "Partitions scanned" to the earlier run. If clustering has
-- progressed, you should see a significant reduction.

-- Re-enable result cache
ALTER SESSION SET USE_CACHED_RESULT = TRUE;

-- --------------------------------------------------------------------------
-- 3g. Demonstrate clustering with multiple columns
-- --------------------------------------------------------------------------
-- You can cluster by more than one column. The order matters -- put the
-- most selective (or most frequently filtered) column first.

ALTER TABLE WORKSHOP_DB.PUBLIC.PERF_TEST CLUSTER BY (sale_date, region);

-- Check the clustering info for the composite key
SELECT SYSTEM$CLUSTERING_INFORMATION('WORKSHOP_DB.PUBLIC.PERF_TEST', '(sale_date, region)');

-- Note: Adding more columns to the clustering key increases the cost of
-- Automatic Clustering. Only include columns that are frequently used in
-- WHERE clauses or JOIN conditions.


-- ============================================================================
-- SECTION 4: OPTIMIZATION TIPS
-- ============================================================================
-- Practical tips that make queries faster and cheaper in Snowflake.
-- ============================================================================

-- --------------------------------------------------------------------------
-- 4a. Avoid SELECT * -- select only the columns you need
-- --------------------------------------------------------------------------
-- BAD: Reads every column from every relevant micro-partition
SELECT *
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM
LIMIT 100;

-- GOOD: Reads only three columns -- Snowflake's columnar format skips the rest
SELECT
    l_orderkey,
    l_extendedprice,
    l_discount
FROM
    SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM
LIMIT 100;

-- Why this matters: Snowflake stores data in columnar format. When you
-- SELECT *, it must read ALL columns from disk. Selecting only the columns
-- you need means less I/O, less memory, and faster results.

-- --------------------------------------------------------------------------
-- 4b. Use filters early (predicate pushdown)
-- --------------------------------------------------------------------------
-- Snowflake automatically pushes predicates down to the scan level, but
-- writing clear, early filters helps the optimizer and makes queries
-- easier to read.

-- GOOD: Filter in the WHERE clause directly on the base table
SELECT
    o.o_orderkey,
    o.o_totalprice,
    c.c_name
FROM
    SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS   o
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER c ON o.o_custkey = c.c_custkey
WHERE
    o.o_orderdate >= '1997-01-01'
    AND o.o_orderdate <  '1997-04-01'
    AND c.c_mktsegment = 'AUTOMOBILE'
LIMIT 50;

-- LESS EFFICIENT: Filtering after aggregation when it could have been done earlier
-- (This is a pattern to watch for in complex CTEs and subqueries)

-- --------------------------------------------------------------------------
-- 4c. Use LIMIT during development
-- --------------------------------------------------------------------------
-- When exploring data or debugging, always add LIMIT to avoid scanning
-- the entire table unnecessarily.

-- During development:
SELECT
    l_orderkey,
    l_partkey,
    l_extendedprice
FROM
    SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM
WHERE
    l_shipdate >= '1998-01-01'
LIMIT 20;

-- --------------------------------------------------------------------------
-- 4d. Proper JOIN strategies
-- --------------------------------------------------------------------------
-- Tip 1: Filter each table BEFORE joining to reduce the data in the join.
-- Tip 2: Join on columns with appropriate data types (avoid implicit casting).
-- Tip 3: For very large joins, ensure the smaller table is on the build side.

-- GOOD: Filters applied before the join reduces rows entering the join
SELECT
    o.o_orderkey,
    o.o_totalprice,
    l.l_extendedprice,
    l.l_quantity
FROM
    SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS o
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM l ON o.o_orderkey = l.l_orderkey
WHERE
    o.o_orderdate BETWEEN '1998-01-01' AND '1998-01-31'    -- Prunes ORDERS partitions
    AND l.l_quantity > 40                                    -- Reduces LINEITEM rows
LIMIT 100;

-- --------------------------------------------------------------------------
-- 4e. Avoid unnecessary ORDER BY
-- --------------------------------------------------------------------------
-- ORDER BY forces a global sort, which can be expensive on large result sets
-- and may cause spilling to disk.

-- BAD (if you do not actually need sorted output):
-- SELECT ... FROM large_table ORDER BY some_column;

-- GOOD: Only sort when the consumer (report, application) truly needs it
-- If you need "top N" results, combine ORDER BY with LIMIT:
SELECT
    l_orderkey,
    l_extendedprice
FROM
    SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM
ORDER BY
    l_extendedprice DESC
LIMIT 10;


-- ============================================================================
-- SECTION 5: MONITORING
-- ============================================================================
-- Use ACCOUNT_USAGE views for deeper performance analysis. These views have
-- up to 45-minute latency but retain 365 days of history.
-- ============================================================================

-- --------------------------------------------------------------------------
-- 5a. Find the most expensive queries by execution time (last 24 hours)
-- --------------------------------------------------------------------------

SELECT
    query_id,
    SUBSTR(query_text, 1, 100)           AS query_preview,
    user_name,
    warehouse_name,
    execution_time / 1000                AS exec_seconds,
    compilation_time / 1000              AS compile_seconds,
    total_elapsed_time / 1000            AS total_seconds,
    bytes_scanned / (1024*1024)          AS mb_scanned,
    rows_produced
FROM
    SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE
    start_time >= DATEADD('DAY', -1, CURRENT_TIMESTAMP())
    AND execution_status = 'SUCCESS'
    AND query_type = 'SELECT'
ORDER BY
    execution_time DESC
LIMIT 15;

-- --------------------------------------------------------------------------
-- 5b. Find queries with high compilation time
-- --------------------------------------------------------------------------
-- High compilation time can indicate overly complex SQL, too many CTEs,
-- or very wide tables. Compilation happens in the cloud services layer.

SELECT
    query_id,
    SUBSTR(query_text, 1, 100)           AS query_preview,
    user_name,
    compilation_time / 1000              AS compile_seconds,
    execution_time / 1000                AS exec_seconds,
    total_elapsed_time / 1000            AS total_seconds
FROM
    SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE
    start_time >= DATEADD('DAY', -1, CURRENT_TIMESTAMP())
    AND execution_status = 'SUCCESS'
    AND compilation_time > 1000   -- more than 1 second to compile
ORDER BY
    compilation_time DESC
LIMIT 10;

-- --------------------------------------------------------------------------
-- 5c. Identify queries doing full table scans (poor pruning)
-- --------------------------------------------------------------------------
-- If partitions_scanned is close to partitions_total, the query is scanning
-- nearly the entire table. This is a candidate for clustering or better
-- filter predicates.

SELECT
    query_id,
    SUBSTR(query_text, 1, 100)           AS query_preview,
    user_name,
    partitions_scanned,
    partitions_total,
    ROUND(partitions_scanned / NULLIF(partitions_total, 0) * 100, 1) AS pct_scanned,
    bytes_scanned / (1024*1024)          AS mb_scanned,
    total_elapsed_time / 1000            AS total_seconds
FROM
    SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE
    start_time >= DATEADD('DAY', -1, CURRENT_TIMESTAMP())
    AND execution_status = 'SUCCESS'
    AND partitions_total > 0
    AND partitions_scanned = partitions_total   -- full scan
ORDER BY
    partitions_total DESC
LIMIT 15;

-- --------------------------------------------------------------------------
-- 5d. Summary: warehouse credit usage over the last 7 days
-- --------------------------------------------------------------------------
-- This helps you understand cost and whether warehouses are right-sized.

SELECT
    warehouse_name,
    SUM(credits_used)                    AS total_credits,
    COUNT(*)                             AS metering_intervals,
    AVG(credits_used)                    AS avg_credits_per_interval
FROM
    SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE
    start_time >= DATEADD('DAY', -7, CURRENT_TIMESTAMP())
GROUP BY
    warehouse_name
ORDER BY
    total_credits DESC;


-- ============================================================================
-- SECTION 6: CLEANUP
-- ============================================================================
-- Remove the objects created during this lab.
-- ============================================================================

-- Drop the clustering key (optional -- dropping the table removes it too)
ALTER TABLE WORKSHOP_DB.PUBLIC.PERF_TEST DROP CLUSTERING KEY;

-- Drop the performance test table
DROP TABLE IF EXISTS WORKSHOP_DB.PUBLIC.PERF_TEST;

-- Reset session parameter to default
ALTER SESSION SET USE_CACHED_RESULT = TRUE;

-- Verify cleanup
SHOW TABLES LIKE 'PERF_TEST' IN SCHEMA WORKSHOP_DB.PUBLIC;

-- ============================================================================
-- LAB 14 COMPLETE
-- ============================================================================
-- You have learned how to:
--   * Read the Query Profile to identify performance bottlenecks
--   * Understand and leverage Snowflake's three caching layers
--   * Use SYSTEM$CLUSTERING_INFORMATION and SYSTEM$CLUSTERING_DEPTH
--   * Apply clustering keys to improve partition pruning
--   * Write optimized SQL (column selection, early filters, LIMIT, JOINs)
--   * Monitor query performance with ACCOUNT_USAGE views
-- ============================================================================
