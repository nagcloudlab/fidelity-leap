# Lab 07: Time Travel & Fail-safe

## Objective

Learn how to use Snowflake's **Time Travel** feature to access historical data, recover
accidentally dropped objects, and undo unwanted changes. Understand the role of **Fail-safe**
as a last-resort disaster recovery mechanism and how it differs from Time Travel.

## Duration

30 minutes

## Prerequisites

- A Snowflake account (Trial or paid)
- `WORKSHOP_DB` database created in Lab 03
- Basic SQL knowledge (SELECT, UPDATE, DELETE, DROP)
- Familiarity with Snowflake worksheets

## Key Concepts

### Time Travel

Time Travel allows you to query, clone, or restore data as it existed at any point within
a defined retention period. It works at the table, schema, and database level.

| Feature | Detail |
|---|---|
| **Standard Edition** | Up to 1 day (0 or 1) of Time Travel |
| **Enterprise Edition+** | Up to 90 days of Time Travel |
| **Parameter** | `DATA_RETENTION_TIME_IN_DAYS` controls the retention window |
| **Access Methods** | `AT(TIMESTAMP =>)`, `AT(OFFSET =>)`, `BEFORE(STATEMENT =>)` |
| **Recovery Commands** | `UNDROP TABLE`, `UNDROP SCHEMA`, `UNDROP DATABASE` |

### Fail-safe

Fail-safe is a **non-configurable 7-day period** that begins immediately after the Time Travel
retention period ends. It is a safety net managed entirely by Snowflake -- you cannot query or
restore data from Fail-safe yourself. Only Snowflake Support can recover data during this window,
and only in exceptional circumstances.

## Time Travel vs Fail-safe Comparison

| Aspect | Time Travel | Fail-safe |
|---|---|---|
| **Purpose** | Self-service data recovery and historical queries | Last-resort disaster recovery |
| **Duration** | 0-1 day (Standard) or 0-90 days (Enterprise+) | 7 days (fixed, non-configurable) |
| **Configurable?** | Yes, via `DATA_RETENTION_TIME_IN_DAYS` | No |
| **Who can access?** | Any user with appropriate privileges | Snowflake Support only |
| **Query historical data?** | Yes (`SELECT ... AT/BEFORE`) | No |
| **Restore dropped objects?** | Yes (`UNDROP`) | Contact Snowflake Support |
| **Storage cost?** | Yes, for changed/deleted data | Yes, for changed/deleted data |
| **Applies to** | Permanent tables, schemas, databases | Permanent tables only |
| **Transient/Temporary tables** | 0 or 1 day maximum | No Fail-safe (0 days) |
| **When it starts** | Immediately when data changes or is deleted | After Time Travel period expires |

### Visual Timeline

```
|<--- Active Data --->|<-------- Time Travel -------->|<--- Fail-safe --->|
                      |   (configurable: 0-90 days)   | (fixed: 7 days)  |
                      |   Self-service recovery        | Snowflake Support|
                      |   AT / BEFORE / UNDROP         | only             |
```

## Step-by-Step Instructions

### Step 1 -- Set Up the Demo Table (5 minutes)

1. Open a new worksheet in Snowflake.
2. Set context to `WORKSHOP_DB` and create a schema for this lab.
3. Create a `customer_orders` table with sample data.
4. Verify the data with a SELECT query.

### Step 2 -- Check Time Travel Settings (2 minutes)

1. Use `SHOW TABLES` and inspect the `retention_time` column.
2. Understand what the current retention setting means for your table.

### Step 3 -- Make Changes and Use Time Travel to View History (8 minutes)

1. Note the current timestamp before making changes.
2. Perform an UPDATE to modify some records.
3. Perform a DELETE to remove records.
4. Use `AT(TIMESTAMP => ...)` to see the data as it was before changes.
5. Use `AT(OFFSET => -60*5)` to see the data from 5 minutes ago.
6. Use `BEFORE(STATEMENT => ...)` to see the data before a specific query ran.

### Step 4 -- Recover from "Oops" Moments (5 minutes)

1. Simulate an accidental `DELETE` of all rows.
2. Use Time Travel to create a recovery table from the pre-delete state.
3. Swap or rename tables to restore the data.

### Step 5 -- UNDROP Objects (5 minutes)

1. Drop a table, then recover it with `UNDROP TABLE`.
2. Drop a schema, then recover it with `UNDROP SCHEMA`.
3. Drop a database, then recover it with `UNDROP DATABASE`.

### Step 6 -- Configure Retention Period (3 minutes)

1. Change `DATA_RETENTION_TIME_IN_DAYS` on a table.
2. Understand the cost and edition implications of longer retention.

### Step 7 -- Understand Fail-safe (2 minutes)

1. Review the conceptual explanation of Fail-safe in the SQL script.
2. Understand when to contact Snowflake Support.

### Step 8 -- Cleanup

1. Drop the lab schema.
2. Verify cleanup is complete.

## Best Practices

1. **Set appropriate retention periods.** Use shorter retention (1 day) for staging or
   transient data. Use longer retention (up to 90 days) for critical production tables.

2. **Use transient tables for non-critical data.** Transient tables have a maximum of 1 day
   Time Travel and no Fail-safe, which reduces storage costs.

3. **Record query IDs for important operations.** After running a critical UPDATE or DELETE,
   note the query ID so you can use `BEFORE(STATEMENT => ...)` if you need to undo it.

4. **Test Time Travel in development first.** Practice recovery scenarios before you need them
   in production.

5. **Monitor Time Travel storage.** Use `TABLE_STORAGE_METRICS` in the `INFORMATION_SCHEMA`
   or `ACCOUNT_USAGE.TABLE_STORAGE_METRICS` to track how much storage Time Travel is consuming.

6. **Act quickly.** Once the retention period expires, data moves to Fail-safe and is no longer
   self-service recoverable. Do not wait to restore if you discover an issue.

7. **Understand edition limits.** Standard edition accounts are limited to 1 day of Time Travel.
   If you need more, consider upgrading to Enterprise.

8. **Use UNDROP before recreating.** If you accidentally drop a table and then create a new table
   with the same name, the original table's Time Travel history is lost. Always try UNDROP first.

## Review Questions

1. What is the maximum Time Travel retention period on a Snowflake Enterprise edition account?

2. What SQL parameter controls how long Time Travel data is retained?

3. Name the three AT/BEFORE clause types you can use to query historical data.

4. You accidentally ran `DELETE FROM important_table WHERE 1=1`. How would you recover the data
   using Time Travel?

5. What is the difference between Time Travel and Fail-safe?

6. Can you query data that is in the Fail-safe period? Why or why not?

7. What happens to Time Travel and Fail-safe for transient tables?

8. You dropped a schema by mistake 10 minutes ago. What command would you run to recover it?

9. Why is it important to act quickly when you need to recover data via Time Travel?

10. How can you check how much storage Time Travel is consuming for your tables?

## Answers

1. 90 days.
2. `DATA_RETENTION_TIME_IN_DAYS`.
3. `AT(TIMESTAMP => ...)`, `AT(OFFSET => ...)`, `BEFORE(STATEMENT => ...)`.
4. Use `CREATE TABLE recovered_table AS SELECT * FROM important_table BEFORE(STATEMENT => 'delete_query_id')`,
   then drop the damaged table and rename the recovered one.
5. Time Travel is self-service (you can query and restore data yourself) and configurable.
   Fail-safe is managed by Snowflake Support only, lasts exactly 7 days, and begins after
   Time Travel expires.
6. No. Fail-safe data is only accessible by Snowflake Support for disaster recovery purposes.
7. Transient tables support a maximum of 1 day of Time Travel and have no Fail-safe period.
8. `UNDROP SCHEMA schema_name;`
9. Once the Time Travel retention period expires, data moves into Fail-safe and can no longer
   be recovered by the user. Only Snowflake Support can help at that point.
10. Query `SNOWFLAKE.ACCOUNT_USAGE.TABLE_STORAGE_METRICS` or
    `INFORMATION_SCHEMA.TABLE_STORAGE_METRICS` to see Time Travel and Fail-safe bytes.
