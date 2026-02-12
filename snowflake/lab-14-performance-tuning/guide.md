# Lab 14: Performance Tuning

## Objective

Learn to analyze and optimize query performance in Snowflake. You will explore the
Query Profile, understand how Snowflake stores data in micro-partitions, use clustering
keys to speed up queries, leverage caching layers, and apply practical optimization
techniques to write faster, more cost-effective SQL.

## Duration

30 minutes

## Prerequisites

- Labs 1-13 completed (or comfortable with Snowflake basics)
- Access to SNOWFLAKE_SAMPLE_DATA shared database
- A running warehouse (XS is fine for this lab)

---

## Key Concepts

### 1. Query Profile

The Query Profile is Snowflake's built-in visual tool for understanding how a query
executes. After running any query in the Snowsight UI, click the **Query Profile** tab
to see:

- **Operator tree** -- a directed acyclic graph (DAG) of every step Snowflake took
  (table scans, joins, aggregations, sorts, etc.)
- **Statistics panel** -- wall-clock time, bytes scanned, rows produced, partitions
  scanned vs. total partitions, spillage to local/remote disk
- **Most expensive node** -- highlighted in the graph so you know where time is spent

The Query Profile is the single most important debugging tool for slow queries. Always
start here.

### 2. Micro-Partitions

Snowflake does **not** use traditional indexes. Instead, every table is automatically
divided into **micro-partitions** -- immutable, compressed columnar files of 50-500 MB
each (before compression). Key facts:

| Property | Detail |
|---|---|
| Size | 50-500 MB uncompressed per micro-partition |
| Format | Columnar, compressed, encrypted |
| Creation | Automatic -- Snowflake decides partition boundaries |
| Metadata | Min/max values, distinct count, and null count per column per partition |

When you run a query with a `WHERE` clause, Snowflake checks each micro-partition's
metadata to decide whether that partition could possibly contain matching rows. If not,
the entire partition is **pruned** (skipped). This is called **partition pruning** and it
is the primary mechanism Snowflake uses instead of indexes.

**Example:** If a micro-partition's metadata says its `ORDER_DATE` values range from
`2024-01-01` to `2024-01-15`, and your query filters on `ORDER_DATE = '2024-06-01'`,
Snowflake skips that partition entirely -- zero I/O cost.

### 3. Clustering Keys

Data arrives in Snowflake in whatever order it is loaded. Over time, especially after
many DML operations, the natural ordering of data within micro-partitions can become
suboptimal for your most common filter columns. **Clustering keys** tell Snowflake which
columns matter most for ordering.

- **Define a clustering key:** `ALTER TABLE t CLUSTER BY (col1, col2);`
- **Automatic Clustering:** Once a clustering key is defined, Snowflake's background
  service (Automatic Clustering) transparently re-organizes micro-partitions over time
  so that rows with similar clustering-key values are co-located. You do not run a
  manual `CLUSTER` command.
- **When to use:** Large tables (multi-terabyte) where queries consistently filter or
  join on the same columns.
- **When NOT to use:** Small tables, tables that are mostly appended and rarely filtered.

### 4. Clustering Information Functions

Snowflake provides two system functions for inspecting clustering quality:

| Function | Purpose |
|---|---|
| `SYSTEM$CLUSTERING_INFORMATION('table', '(col)')` | Returns a JSON object with average clustering depth, histogram of overlap, etc. |
| `SYSTEM$CLUSTERING_DEPTH('table', '(col)')` | Returns a single number -- the average overlap depth. Lower is better. |

A clustering depth of **1** means perfect clustering (each partition's value range does
not overlap with any other). Higher numbers mean more overlap and more partitions to
scan.

### 5. The Three Caching Layers

Snowflake uses three layers of caching to avoid redundant work. Understanding them helps
explain why the same query can be fast on the second run.

```
 Layer 1: Result Cache          (Cloud Services layer -- free, 24 hours)
       |
       v  (miss)
 Layer 2: Local Disk Cache      (SSD on warehouse nodes -- per warehouse)
       |
       v  (miss)
 Layer 3: Remote Disk Cache     (S3 / Azure Blob / GCS -- shared storage)
```

#### Layer 1 -- Result Cache (Metadata Cache)

- **Where:** Cloud Services layer (no warehouse needed)
- **What:** The exact result set of a previously executed query
- **Lifetime:** 24 hours (resets if underlying data changes)
- **Cost:** Free -- the warehouse does not need to be running
- **Hit condition:** Same query text, same role, same database/schema context, data
  unchanged

If the result cache hits, Snowflake returns the answer in milliseconds without resuming
a warehouse. This is why re-running the same SELECT is almost instant.

#### Layer 2 -- Local Disk Cache (SSD Cache)

- **Where:** SSD drives attached to each warehouse compute node
- **What:** Raw micro-partition data fetched from remote storage
- **Lifetime:** As long as the warehouse is running (cleared on suspend)
- **Cost:** Included in warehouse runtime -- no extra charge
- **Hit condition:** Same micro-partitions accessed again while warehouse is active

This is why a warehouse that has been running queries against the same table will feel
faster than a freshly resumed warehouse -- the data is already on local SSD.

#### Layer 3 -- Remote Disk Cache (Cloud Storage)

- **Where:** The cloud provider's object store (S3, Azure Blob, GCS)
- **What:** The original micro-partition files
- **Lifetime:** Permanent (until data is dropped or purged)
- **Cost:** Storage charges only; I/O charges when reading

This is the "source of truth." If data is not in the local SSD cache, Snowflake fetches
it from remote storage.

### 6. Pruning

Pruning is the process of skipping micro-partitions that cannot contain relevant data.
There are two flavors:

- **Partition pruning** -- uses min/max metadata to skip entire partitions
- **Column pruning** -- because data is stored in columnar format, Snowflake reads only
  the columns referenced in your query, not the entire row

Both happen automatically. You do not need to create indexes or hints. The best thing
you can do to maximize pruning is to:

1. Filter on clustered columns
2. Select only the columns you need (avoid `SELECT *`)
3. Use appropriate data types (e.g., DATE instead of VARCHAR for dates)

### 7. Warehouse Sizing

| Size | Servers | Credits/Hour | Use Case |
|---|---|---|---|
| X-Small | 1 | 1 | Development, light queries |
| Small | 2 | 2 | Small-medium workloads |
| Medium | 4 | 4 | Medium production workloads |
| Large | 8 | 8 | Large data processing |
| X-Large | 16 | 16 | Heavy analytical workloads |
| 2X-Large | 32 | 32 | Very large data processing |
| ... | ... | ... | Up to 6X-Large |

**Key insight:** Doubling warehouse size doubles cost but also doubles compute. For
queries limited by scan throughput, a larger warehouse can cut wall-clock time in half.
For queries limited by a single-threaded operation (e.g., a massive `ORDER BY`), a
bigger warehouse may not help. Use the Query Profile to determine the bottleneck before
scaling up.

---

## Step-by-Step Instructions

### Step 1 -- Setup (2 min)

Open a new worksheet in Snowsight. Run the setup commands at the top of `lab-14.sql` to
select the workshop database, schema, and warehouse.

### Step 2 -- Explore the Query Profile (5 min)

1. Run the complex multi-join query provided in the script.
2. In Snowsight, click the **Query Profile** tab.
3. Identify the most expensive operator node.
4. Check the **Statistics** panel on the right for:
   - Partitions scanned vs. partitions total
   - Bytes scanned
   - Percentage of data scanned from cache
5. Run the `EXPLAIN` command to see the execution plan as text output.
6. Query `QUERY_HISTORY` to find your recent slow queries.

### Step 3 -- Observe Caching Behavior (5 min)

1. Run the aggregation query the **first** time -- note the execution time.
2. Run the **exact same query** again -- it should return almost instantly because the
   result cache serves it.
3. Disable the result cache with `ALTER SESSION SET USE_CACHED_RESULT = FALSE;` and run
   the query a third time. This time the warehouse does the work, but local SSD cache
   may help if the warehouse was already warm.
4. Re-enable the result cache when done.

### Step 4 -- Inspect and Apply Clustering (10 min)

1. Create (or use) a large table with several million rows.
2. Run `SYSTEM$CLUSTERING_INFORMATION()` to see the current clustering quality.
3. Run a filtered query and note partitions scanned.
4. Apply a clustering key with `ALTER TABLE ... CLUSTER BY (...)`.
5. Check `SYSTEM$CLUSTERING_DEPTH()` to confirm.
6. Understand that Automatic Clustering will improve the table over time in the
   background. For this lab, we observe the commands and metadata -- full
   re-clustering of a large table can take minutes to hours in production.

### Step 5 -- Apply Optimization Tips (5 min)

Walk through each optimization tip in the SQL script:

- Replace `SELECT *` with explicit columns
- Push filters as early as possible
- Use `LIMIT` during development
- Choose the right join strategy
- Avoid unnecessary `ORDER BY`

### Step 6 -- Monitor with ACCOUNT_USAGE (3 min)

Run the monitoring queries to find:

- The most expensive queries by execution time
- Queries with poor pruning ratios (full table scans)
- Compilation-heavy queries

---

## Best Practices for Performance

1. **Always check the Query Profile first.** It tells you exactly where time is spent.
2. **Select only the columns you need.** Column pruning reduces I/O significantly.
3. **Filter early.** Place WHERE clauses that reduce data volume as close to the base
   tables as possible.
4. **Leverage result caching.** If your dashboards run the same queries repeatedly,
   let the result cache serve them for free.
5. **Right-size your warehouse.** Start small, scale up only when the Query Profile
   shows I/O or processing bottlenecks.
6. **Use clustering keys on large tables** where queries consistently filter on the same
   columns. Do not cluster small tables.
7. **Avoid SELECT DISTINCT and ORDER BY unless required.** Both are expensive operations
   that may cause spilling.
8. **Use transient/temporary tables for staging data** to avoid unnecessary Time Travel
   storage and micro-partition overhead.
9. **Monitor regularly.** Use `ACCOUNT_USAGE.QUERY_HISTORY` and the
   `ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY` views to spot trends.
10. **Suspend idle warehouses.** Set `AUTO_SUSPEND` to 60-300 seconds to avoid paying
    for idle compute.

---

## Review Questions

1. **What are the three caching layers in Snowflake, and where does each one live?**

2. **What is a micro-partition, and how does Snowflake use micro-partition metadata to
   speed up queries?**

3. **You run the same SELECT query twice. The second run returns in 50 milliseconds.
   Which cache layer most likely served the result? What would happen if the underlying
   table had been updated between the two runs?**

4. **A query scans 1,000 out of 10,000 partitions. After adding a clustering key on the
   filter column and waiting for Automatic Clustering to finish, the same query scans
   50 partitions. Explain why.**

5. **Your Query Profile shows a single TableScan node consuming 90% of the time and
   scanning all partitions. The query filters on a VARCHAR column that holds dates in
   'YYYY-MM-DD' format. What two changes could dramatically reduce scan time?**

6. **Why might increasing warehouse size from Small to Large NOT improve a query that
   sorts 500 million rows on a single column?**

7. **Explain why `SELECT *` is discouraged in Snowflake even though there are no
   traditional indexes.**

---

## Summary

In this lab you learned how to:

- Read the Query Profile to identify bottlenecks
- Understand Snowflake's three caching layers and how each one reduces cost and latency
- Use micro-partition metadata and clustering keys to maximize pruning
- Apply practical SQL optimization techniques
- Monitor query performance using ACCOUNT_USAGE views

Performance tuning in Snowflake is less about manual index management and more about
understanding how the engine stores, caches, and prunes data -- then writing queries
that take advantage of these automatic mechanisms.
