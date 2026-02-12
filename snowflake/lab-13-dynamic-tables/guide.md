# Lab 13: Dynamic Tables & Materialized Views

## Objective

Learn how to build **declarative data pipelines** with Dynamic Tables and accelerate repetitive queries with **Materialized Views**. By the end of this lab you will understand how Dynamic Tables automatically transform and refresh data without explicit Streams or Tasks, how Materialized Views pre-compute and cache query results for faster reads, and when to choose one approach over the other.

## Duration

30 minutes

## Prerequisites

- Completion of Labs 01-12 (or equivalent familiarity with Snowflake basics, including Streams & Tasks from Lab 09)
- Access to `WORKSHOP_DB` with the `RAW` and `ANALYTICS` schemas
- A role that can create dynamic tables, materialized views, and regular tables (e.g., `SYSADMIN`)
- A virtual warehouse (e.g., `WORKSHOP_WH`)

---

## Key Concepts

### Dynamic Tables (Declarative Data Pipelines)

A **Dynamic Table** is a table whose contents are defined by a SQL query. Instead of writing procedural ETL code with Streams and Tasks, you declare *what* the table should contain and Snowflake figures out *how* and *when* to refresh it.

#### How They Work

1. You write a `CREATE DYNAMIC TABLE ... AS SELECT ...` statement that defines the transformation.
2. You specify a **TARGET_LAG** -- the maximum amount of time the data in the dynamic table is allowed to fall behind the source.
3. Snowflake's automated refresh system detects changes in the source tables and refreshes the dynamic table to stay within the target lag.

#### TARGET_LAG

| Value | Meaning |
|-------|---------|
| `'1 minute'` | Data must be no more than 1 minute behind the source |
| `'5 minutes'` | Data must be no more than 5 minutes behind the source |
| `'1 hour'` | Data must be no more than 1 hour behind the source |
| `DOWNSTREAM` | Refresh only when a downstream dynamic table needs this data |

A shorter target lag means more frequent refreshes and higher compute cost. A longer lag reduces cost but increases data staleness.

#### Dynamic Table Chains (Medallion Architecture)

Dynamic Tables can reference other Dynamic Tables, forming a **pipeline chain**. This naturally supports the Bronze-Silver-Gold (medallion) pattern:

```
Source Table (raw data)
    |
    v
Dynamic Table: Bronze (cleaned, typed)
    |
    v
Dynamic Table: Silver (deduplicated, enriched)
    |
    v
Dynamic Table: Gold (aggregated, business-ready)
```

Each table in the chain declares its own TARGET_LAG, and Snowflake orchestrates refreshes across the entire pipeline automatically.

### Materialized Views (Query Acceleration)

A **Materialized View** is a pre-computed result set stored as a physical table. Unlike a regular view (which re-runs the query every time), a materialized view returns results from its stored cache, making reads extremely fast.

#### How They Work

1. You write a `CREATE MATERIALIZED VIEW ... AS SELECT ...` statement.
2. Snowflake executes the query and stores the results physically.
3. When the base table changes, Snowflake automatically refreshes the materialized view in the background -- you do not need to schedule anything.
4. When you query the materialized view, Snowflake's optimizer may perform **automatic query rewrite**: even if you query the base table directly, the optimizer can transparently use the materialized view if it satisfies the query.

#### Key Properties

| Property | Detail |
|----------|--------|
| **Auto-refresh** | Snowflake maintains the view automatically when the base table changes |
| **Query rewrite** | The optimizer can redirect base-table queries to the MV transparently |
| **Single-table only** | MVs cannot contain JOINs -- they must query exactly one base table |
| **Supported operations** | SELECT, WHERE, GROUP BY, aggregations on a single table |
| **Clustering** | MVs can be clustered independently from the base table |

### Differences Between Dynamic Tables and Materialized Views

| Feature | Dynamic Table | Materialized View |
|---------|--------------|-------------------|
| **Purpose** | Build data pipelines (ETL/ELT) | Accelerate queries on a single table |
| **Joins** | Supported | Not supported (single table only) |
| **Chaining** | Can reference other dynamic tables | Cannot reference other MVs |
| **Refresh control** | TARGET_LAG (you choose freshness) | Automatic (Snowflake decides) |
| **Query rewrite** | No | Yes (optimizer can use MV transparently) |
| **Best for** | Multi-step transformations | Speeding up expensive aggregations/filters |

---

## When to Use Which

| Scenario | Recommended Approach |
|----------|---------------------|
| Multi-step transformation pipeline with joins | **Dynamic Tables** |
| Accelerate a slow aggregation on a single large table | **Materialized View** |
| Need fine-grained control over refresh timing | **Dynamic Tables** (TARGET_LAG) |
| Need transparent query acceleration without changing app queries | **Materialized View** (query rewrite) |
| Complex CDC logic with custom merge/upsert behavior | **Streams + Tasks** (Lab 09) |
| Need to execute arbitrary procedural SQL on a schedule | **Streams + Tasks** |
| Simple declarative pipeline, want minimal code | **Dynamic Tables** |

**Rule of thumb:** If your goal is to *transform and pipeline* data, use Dynamic Tables. If your goal is to *speed up reads* on a single table, use Materialized Views. If you need procedural control or complex CDC, use Streams and Tasks.

---

## Step-by-Step Instructions

### Step 1 -- Set Up the Environment

Open `lab-13.sql` in a Snowflake worksheet. Run the setup section to configure the database, schemas, and warehouse context.

### Step 2 -- Create a Raw Source Table

Create a source table (`RAW.RAW_SENSOR_READINGS`) and insert sample IoT sensor data. This table simulates raw data arriving from devices.

### Step 3 -- Create Your First Dynamic Table

Create a Dynamic Table with `TARGET_LAG = '1 minute'` that cleans and transforms the raw sensor data -- casting types, filtering invalid readings, and adding computed columns.

### Step 4 -- Build a Dynamic Table Chain (Bronze -> Silver -> Gold)

Create a chain of three Dynamic Tables following the medallion architecture:
- **Bronze**: Raw data cleaned and typed
- **Silver**: Deduplicated, with derived metrics
- **Gold**: Aggregated summaries ready for dashboards

### Step 5 -- Observe Automatic Refresh

Insert new rows into the source table, then query each dynamic table in the chain to see how Snowflake propagates changes automatically.

### Step 6 -- Manage Dynamic Tables

Use `ALTER DYNAMIC TABLE` to change the target lag. Use `DESCRIBE DYNAMIC TABLE` and the `DYNAMIC_TABLE_REFRESH_HISTORY()` function to inspect metadata and refresh history.

### Step 7 -- Create a Regular View for Comparison

Create a standard view that performs an aggregation on a large data set. Query it and note that it re-executes the full query every time.

### Step 8 -- Create a Materialized View

Create a Materialized View with the same aggregation logic. Query it and compare the performance to the regular view.

### Step 9 -- Observe MV Auto-Refresh

Insert new rows into the base table and query the materialized view again to see that Snowflake has automatically incorporated the new data.

### Step 10 -- Explore MV Metadata

Use `DESCRIBE MATERIALIZED VIEW` and `SHOW MATERIALIZED VIEWS` to inspect the MV's definition and state.

### Step 11 -- Understand MV Limitations

Attempt to create a Materialized View with a JOIN to observe the error. This reinforces the single-table-only restriction.

### Step 12 -- Cleanup

Drop all dynamic tables, materialized views, views, and tables created during this lab.

---

## Best Practices

1. **Choose TARGET_LAG based on business need, not instinct.** A 5-minute or 1-hour lag is perfectly fine for most analytics. Shorter lags cost more compute.

2. **Use `DOWNSTREAM` for intermediate dynamic tables.** If a dynamic table is only consumed by another dynamic table (not queried directly), set its lag to `DOWNSTREAM` to let Snowflake optimize refresh timing.

3. **Keep dynamic table chains shallow.** Aim for 3-4 levels at most. Deep chains increase refresh latency and make debugging harder.

4. **Use Materialized Views for hot queries.** If a dashboard runs the same expensive aggregation every few seconds, an MV can eliminate redundant compute.

5. **Remember MVs are single-table only.** If you need joins, use a Dynamic Table or a regular view instead.

6. **Monitor refresh costs.** Check `DYNAMIC_TABLE_REFRESH_HISTORY()` and the Account Usage views to understand how much compute your pipelines consume.

7. **Do not over-materialize.** Creating an MV for every query is counterproductive. Focus on the highest-impact queries -- those that are expensive and run frequently.

8. **Prefer Dynamic Tables over Streams + Tasks for simple pipelines.** Dynamic Tables require less code, handle orchestration automatically, and are easier to maintain. Reserve Streams + Tasks for scenarios that need procedural logic.

---

## Review Questions

1. **What is a Dynamic Table, and how does it differ from a regular table or view?**

2. **What does TARGET_LAG control, and what is the trade-off between a short lag and a long lag?**

3. **What does `TARGET_LAG = DOWNSTREAM` mean, and when should you use it?**

4. **Describe the Bronze-Silver-Gold pattern using Dynamic Tables. Why is chaining useful?**

5. **What is a Materialized View, and how does it differ from a regular view?**

6. **What is "automatic query rewrite" in the context of Materialized Views?**

7. **Why can a Materialized View not contain JOINs?**

8. **When would you choose a Dynamic Table over a Materialized View?**

9. **When would you choose Streams + Tasks over Dynamic Tables?**

10. **How do you monitor the refresh history of a Dynamic Table?**
