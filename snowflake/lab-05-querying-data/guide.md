# Lab 05: Querying Data

## Objective
Master Snowflake's advanced SQL querying features including Common Table Expressions (CTEs), window functions, the QUALIFY clause, FLATTEN for semi-structured data, PIVOT/UNPIVOT, sampling, and the MERGE statement. By the end of this lab you will be able to write sophisticated analytical queries that go well beyond standard SQL.

## Duration: 45 minutes

---

## Key Concepts

- **CTE (Common Table Expression)** -- A named temporary result set defined with the WITH clause; makes complex queries readable and supports recursion
- **Window Functions** -- Functions that compute a value across a set of rows related to the current row without collapsing them (ROW_NUMBER, RANK, DENSE_RANK, LAG, LEAD, NTILE)
- **Running Totals & Moving Averages** -- Aggregate window functions (SUM OVER, AVG OVER) with frame clauses to compute cumulative or sliding calculations
- **QUALIFY** -- A Snowflake-specific clause that filters the result of window functions directly, eliminating the need for subqueries
- **FLATTEN** -- Converts semi-structured data (JSON arrays and objects) into relational rows so you can query VARIANT, OBJECT, and ARRAY columns with standard SQL
- **LATERAL FLATTEN** -- Combines LATERAL joins with FLATTEN to explode nested arrays while preserving the parent row context
- **PIVOT / UNPIVOT** -- PIVOT rotates rows into columns; UNPIVOT rotates columns back into rows
- **SAMPLE / TABLESAMPLE** -- Returns a random subset of rows from a table for quick exploration or testing
- **RESULT_SCAN** -- Queries the result set of a previously executed statement using its query ID
- **MERGE** -- Performs upserts (INSERT + UPDATE + DELETE) in a single atomic statement by matching source rows to target rows

---

## Prerequisites

- Labs 01 through 04 completed
- WORKSHOP_DB database created (from Lab 03)
- Access to SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 (available in every Snowflake account)
- SYSADMIN role and a running warehouse

---

## Step-by-Step Instructions

### Step 1: Set Up Your Session
Set the role, warehouse, database, and schema context. The lab uses both WORKSHOP_DB for custom tables and SNOWFLAKE_SAMPLE_DATA.TPCH_SF1 for realistic data.

### Step 2: Simple and Recursive CTEs
Write a simple CTE to compute regional revenue summaries and then chain multiple CTEs together. Next, build a recursive CTE to generate a date sequence -- a common technique for filling calendar gaps.

### Step 3: Window Functions -- ROW_NUMBER, RANK, DENSE_RANK, NTILE
Rank customers by total spending within each market segment. Understand the difference between RANK (gaps after ties) and DENSE_RANK (no gaps). Use NTILE to divide customers into quartiles.

### Step 4: Window Functions -- LAG and LEAD
Use LAG and LEAD to compare each order with the previous and next order for the same customer. This pattern is essential for calculating period-over-period changes.

### Step 5: Running Totals and Moving Averages
Compute running revenue totals and 3-month moving averages using SUM and AVG with ROWS BETWEEN frame clauses.

### Step 6: QUALIFY Clause
Replace the common subquery-wrapping pattern with Snowflake's QUALIFY clause to filter window function results directly. This is one of Snowflake's most useful SQL extensions.

### Step 7: Create Sample JSON Data and Use FLATTEN
Insert JSON documents into a VARIANT column and use FLATTEN to convert nested key-value pairs into rows. This is how you query semi-structured data in Snowflake.

### Step 8: LATERAL FLATTEN for Nested Arrays
Use LATERAL FLATTEN to explode nested arrays (such as order line items) while keeping the parent record columns available.

### Step 9: PIVOT and UNPIVOT
Pivot monthly revenue data so that each month becomes a column. Then reverse the transformation with UNPIVOT.

### Step 10: SAMPLE and TABLESAMPLE
Retrieve random subsets of rows using row-based and block-based sampling. Useful for quick data exploration and performance testing.

### Step 11: RESULT_SCAN
Run a SHOW or query command and then query its output using RESULT_SCAN and LAST_QUERY_ID. This technique is handy for scripting and automation.

### Step 12: MERGE Statement for Upserts
Create a staging table and merge it into a target table, inserting new rows, updating changed rows, and optionally deleting removed rows -- all in one statement.

### Step 13: Clean Up
Drop temporary tables created during the lab to keep your environment tidy.

---

## Best Practices

- **Use CTEs for readability** -- Break large queries into named steps rather than nesting subqueries three levels deep
- **Prefer QUALIFY over subqueries** -- When filtering on window functions, QUALIFY is cleaner and often faster
- **Choose the right ranking function** -- Use ROW_NUMBER when you need exactly one row per group, RANK or DENSE_RANK when ties matter
- **Define explicit window frames** -- Always specify ROWS BETWEEN or RANGE BETWEEN so the frame boundary is clear to anyone reading the query
- **Type-cast VARIANT fields** -- When using FLATTEN, always cast extracted values to the correct data type (e.g., value::STRING, value::NUMBER)
- **Alias FLATTEN output** -- Give the FLATTEN table function a short alias (e.g., f) and reference f.value, f.key, f.index for clarity
- **Sample for exploration, not production** -- SAMPLE is non-deterministic; do not rely on it for repeatable results unless you set a seed
- **Use MERGE instead of DELETE + INSERT** -- MERGE is atomic, simpler to read, and less error-prone than multi-statement upsert logic

---

## Review Questions

1. What is the difference between RANK and DENSE_RANK when there are tied values?
2. How does the QUALIFY clause simplify queries that filter on window function results?
3. What is the purpose of the LATERAL keyword when used with FLATTEN?
4. When would you use a recursive CTE? Give a real-world example.
5. What are the two sampling methods in Snowflake and how do they differ?
6. In a MERGE statement, what happens if a source row matches multiple target rows?
7. How can RESULT_SCAN be combined with LAST_QUERY_ID() for automation?
