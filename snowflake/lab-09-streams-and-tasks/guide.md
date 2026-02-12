# Lab 09: Streams & Tasks

## Objective

Learn to build automated data pipelines using **Streams** (change data capture) and **Tasks** (scheduled SQL execution). By the end of this lab you will be able to capture row-level changes on a table, consume those changes in downstream processing, schedule SQL statements to run automatically, and chain tasks together into multi-step pipelines.

## Duration

45 minutes

## Prerequisites

- Completion of Labs 01-08 (or equivalent familiarity with Snowflake basics)
- Access to `WORKSHOP_DB` with the `RAW` and `ANALYTICS` schemas
- A role that can create streams, tasks, and tables (e.g., `SYSADMIN` or a custom workshop role)
- A virtual warehouse (e.g., `WORKSHOP_WH`) for task execution

---

## Key Concepts

### Streams (Change Data Capture)

A **stream** is a Snowflake object that records data manipulation language (DML) changes made to a table -- inserts, updates, and deletes. Think of it as a changelog that sits on top of a table and advances an internal **offset** each time you consume the changes.

#### Stream Types

| Type | Tracks | Best For |
|------|--------|----------|
| **Standard** | INSERT, UPDATE, DELETE | General-purpose CDC; full change tracking |
| **Append-only** | INSERT only | Staging tables where rows are never updated or deleted |
| **Insert-only** | INSERT only (on external tables) | External tables where only new files are added |

#### Metadata Columns

Every stream automatically exposes three metadata columns on each changed row:

| Column | Description |
|--------|-------------|
| `METADATA$ACTION` | `INSERT` or `DELETE` (updates appear as a DELETE + INSERT pair) |
| `METADATA$ISUPDATE` | `TRUE` if the row is part of an UPDATE operation |
| `METADATA$ROW_ID` | A unique, immutable ID for the row across changes |

#### Stream Offset

Streams maintain an internal **offset** that points to a position in the table's change history. When you consume data from a stream inside a DML transaction (for example, `INSERT INTO ... SELECT ... FROM stream`), the offset advances past the consumed changes and the stream appears empty again. If you only query a stream with a SELECT (without a DML wrapper), the offset does **not** advance.

### Tasks (Scheduled SQL Execution)

A **task** is a Snowflake object that executes a single SQL statement on a defined schedule. Tasks can run using a dedicated virtual warehouse or in **serverless** mode (Snowflake manages the compute).

#### Schedule Options

- **CRON expression**: `SCHEDULE = 'USING CRON 0 9 * * * America/New_York'` (runs daily at 9 AM ET)
- **Minutes interval**: `SCHEDULE = '1 MINUTE'` (runs every 1 minute)

#### Task Trees (DAGs)

Tasks can be linked into **Directed Acyclic Graphs (DAGs)** by setting a child task's `AFTER` clause to reference one or more parent tasks. When the parent completes, the child fires automatically.

```
Root Task (scheduled)
    |
    +-- Child Task A (AFTER root)
    |       |
    |       +-- Grandchild Task (AFTER child A)
    |
    +-- Child Task B (AFTER root)
```

Only the **root task** has a schedule. Child tasks inherit their execution timing from their parent.

#### SYSTEM$STREAM_HAS_DATA()

Use this function in a task's `WHEN` clause to skip execution when the stream is empty:

```sql
WHEN SYSTEM$STREAM_HAS_DATA('my_stream')
```

This avoids unnecessary warehouse spin-up and compute costs.

---

## How Streams Work

1. You create a stream on a source table.
2. Any INSERT, UPDATE, or DELETE on the source table is recorded in the stream.
3. The stream presents the net changes since the last time it was consumed.
4. When you run a DML statement that reads from the stream (e.g., `INSERT INTO target SELECT * FROM stream`), the offset advances and the stream resets to empty.
5. New changes after that point start accumulating again.

```
Source Table                Stream                  Target Table
+-----------+           +-------------+           +--------------+
| new rows  |  ------>  | CDC records |  ------>  | processed    |
| updates   |  (auto)   | with action |  (task)   | rows         |
| deletes   |           | metadata    |           |              |
+-----------+           +-------------+           +--------------+
```

## How Tasks Work

1. You create a task with a SQL body and a schedule (or an `AFTER` dependency).
2. The task is created in a **suspended** state. You must explicitly `ALTER TASK ... RESUME` to activate it.
3. On each scheduled interval, Snowflake checks the optional `WHEN` condition. If the condition is true (or absent), the SQL body executes.
4. For task trees, only the root task needs `RESUME`. Child tasks must also be resumed, but they fire based on the parent's completion rather than a clock schedule.
5. Use `EXECUTE TASK <name>` to trigger a task manually outside its schedule.

---

## Step-by-Step Instructions

### Step 1 -- Set Up the Environment

Open the file `lab-09.sql` in a Snowflake worksheet. Run the setup section to create the source table (`RAW.RAW_ORDERS`) and the target table (`ANALYTICS.PROCESSED_ORDERS`).

### Step 2 -- Create a Stream

Create a standard stream on `RAW.RAW_ORDERS`. This stream will track all DML changes on the table.

### Step 3 -- Observe INSERT Changes

Insert several rows into the source table, then query the stream. Notice the `METADATA$ACTION` column shows `INSERT` and `METADATA$ISUPDATE` is `FALSE`.

### Step 4 -- Observe UPDATE Changes

Update a row in the source table, then query the stream. An update appears as two rows: one `DELETE` (the old version) and one `INSERT` (the new version), both with `METADATA$ISUPDATE = TRUE`.

### Step 5 -- Observe DELETE Changes

Delete a row from the source table. The stream shows a `DELETE` action with `METADATA$ISUPDATE = FALSE`.

### Step 6 -- Consume the Stream

Run the `INSERT INTO ... SELECT ... FROM stream` statement to move changes into the target table. After consumption, query the stream again to confirm it is now empty.

### Step 7 -- Create an Automated Task

Create a task that runs every 1 minute. It uses `SYSTEM$STREAM_HAS_DATA()` in the `WHEN` clause so it only processes data when there are pending changes.

### Step 8 -- Build a Task Tree

Create a child task that runs after the parent task completes. The child performs a secondary aggregation step.

### Step 9 -- Resume and Monitor Tasks

Resume all tasks (children first, then root). Insert new data into the source table and watch the tasks pick up the changes automatically. Monitor execution history with `TASK_HISTORY()`.

### Step 10 -- Manual Task Execution

Use `EXECUTE TASK` to trigger the root task on demand rather than waiting for the schedule.

### Step 11 -- Cleanup

Suspend and drop all tasks and streams to leave the environment clean.

---

## Best Practices

1. **Always use `WHEN SYSTEM$STREAM_HAS_DATA()`** on tasks that consume streams. This prevents unnecessary compute when there are no changes to process.

2. **Resume child tasks before the root task.** If you resume the root first, it may fire before the children are ready, and the children will be skipped.

3. **Use append-only streams for insert-heavy staging tables.** They are simpler and slightly more efficient when you know rows will never be updated or deleted.

4. **Keep task SQL focused.** Each task should do one thing. Use task trees to break complex pipelines into discrete steps.

5. **Monitor with TASK_HISTORY().** Check for failures regularly. Set up alerts or error-handling logic for production pipelines.

6. **Be mindful of stream staleness.** If a stream is not consumed within the data retention period of the source table (default 1 day for standard edition, up to 90 days for enterprise), the stream becomes stale and unusable. Consume regularly or extend retention.

7. **Use serverless tasks for lightweight workloads.** They avoid the cold-start overhead of spinning up a virtual warehouse. For heavier workloads, assign a dedicated warehouse.

8. **Test with `EXECUTE TASK` before relying on the schedule.** This lets you verify the SQL logic works correctly without waiting for the cron interval.

---

## Review Questions

1. **What are the three types of streams in Snowflake, and when would you use each one?**

2. **When you UPDATE a row in a table that has a standard stream, how does the stream represent that change?**

3. **What happens to a stream's offset when you SELECT from it versus when you use it in a DML statement like INSERT INTO ... SELECT?**

4. **What is the purpose of `SYSTEM$STREAM_HAS_DATA()` in a task's WHEN clause?**

5. **In a task tree, which task holds the SCHEDULE -- the root task or the child tasks?**

6. **Why should you resume child tasks before resuming the root task?**

7. **What Snowflake function do you use to view the execution history of tasks?**

8. **What happens if a stream is not consumed before the source table's data retention period expires?**

9. **How does a serverless task differ from a warehouse-based task?**

10. **What command do you use to manually trigger a task outside its normal schedule?**
