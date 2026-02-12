# Lab 10: Snowpipe — Continuous, Automated Data Loading

## Objective

Learn how to use Snowflake's **Snowpipe** service to continuously and automatically load data as soon as new files arrive in a stage. By the end of this lab you will understand how to create pipes, monitor their status, handle errors, and apply best practices for production-grade streaming ingestion.

## Duration

Approximately **30 minutes**.

## Prerequisites

- A Snowflake account (any edition; Snowpipe is available on all editions).
- `WORKSHOP_DB` database created in earlier labs.
- Basic familiarity with stages, file formats, and the `COPY INTO` command (Labs 7-9).
- A SQL worksheet open in Snowsight or a connected client such as SnowSQL.

---

## Key Concepts

| Concept | Description |
|---|---|
| **Snowpipe** | A serverless, event-driven service that loads data continuously as new files land in a stage. |
| **CREATE PIPE** | DDL statement that defines a pipe object containing a `COPY INTO` statement. |
| **AUTO_INGEST** | Property that, when set to `TRUE`, tells Snowpipe to listen for cloud event notifications and load files automatically. |
| **COPY INTO (in pipes)** | The embedded `COPY INTO` statement inside a pipe definition that specifies source stage, target table, file format, and any transformations. |
| **SYSTEM$PIPE_STATUS()** | System function that returns the current execution state of a pipe (e.g., running files, pending files, last ingested timestamp). |
| **SYSTEM$PIPE_FORCE_RESUME()** | System function that force-resumes a pipe that has entered a stalled state. |
| **ALTER PIPE ... REFRESH** | Command to manually trigger Snowpipe to scan the stage and load any new files it has not yet processed. |
| **REST API (insertFiles)** | An alternative to `AUTO_INGEST` where your application calls the Snowpipe REST API to notify Snowpipe about new files. |
| **Event Notifications** | Cloud-native notifications (AWS SQS, Azure Event Grid, GCP Pub/Sub) that tell Snowpipe a new file has arrived. |

---

## How Snowpipe Works

```
                          Cloud Storage / Internal Stage
                          ┌──────────────────────────────┐
   Application / ETL ---> │  new_file_001.csv lands here │
                          └──────────┬───────────────────┘
                                     │
                          ┌──────────▼───────────────────┐
                          │  Event Notification fires    │
                          │  (S3 SQS / Azure Event Grid  │
                          │   / GCS Pub/Sub)             │
                          └──────────┬───────────────────┘
                                     │
                          ┌──────────▼───────────────────┐
                          │  Snowpipe (serverless)       │
                          │  • Picks up notification     │
                          │  • Runs COPY INTO internally │
                          │  • Loads file into table     │
                          └──────────┬───────────────────┘
                                     │
                          ┌──────────▼───────────────────┐
                          │  Target Table                │
                          │  (data available in seconds  │
                          │   to minutes)                │
                          └──────────────────────────────┘
```

### Two Trigger Modes

1. **AUTO_INGEST = TRUE** — Snowpipe listens for cloud event notifications. Fully automated; no application code needed once configured.
2. **REST API (insertFiles)** — Your application calls the Snowpipe REST endpoint after uploading files. Useful when you cannot set up cloud event notifications.

In this lab we focus on **manual refresh** (`ALTER PIPE ... REFRESH`) because full auto-ingest requires cloud event notification infrastructure (S3 bucket policies, SQS queues, etc.). The SQL patterns and monitoring techniques are identical regardless of trigger mode.

---

## Snowpipe vs Traditional COPY INTO

| Aspect | Traditional COPY INTO | Snowpipe |
|---|---|---|
| **Trigger** | User or scheduled task runs the command manually | Automatic (event notification) or REST API call |
| **Compute** | Uses a user-managed virtual warehouse | Serverless compute managed by Snowflake |
| **Latency** | Depends on schedule (minutes to hours) | Near real-time (seconds to minutes) |
| **Cost model** | Warehouse credit consumption while running | Per-second serverless compute charges + file overhead |
| **Idempotency** | Must manage `FORCE` / metadata yourself | Built-in deduplication — each file loaded exactly once within 14 days |
| **Concurrency** | One COPY command at a time per session | Multiple files loaded in parallel automatically |
| **Best for** | Large scheduled batch loads | Continuous micro-batch / streaming ingestion |
| **Warehouse required** | Yes | No (serverless) |
| **Load history** | `LOAD_HISTORY` / `COPY_HISTORY` | Same views + `PIPE_USAGE_HISTORY` for cost tracking |

---

## Step-by-Step Instructions

### Step 1 — Set Up the Environment

Open `lab-10.sql` in your worksheet. Run the first section to select the `WORKSHOP_DB` database, create a schema called `SNOWPIPE_LAB`, and set the context.

### Step 2 — Create Source Tables and File Format

Run the section that creates:

- `RAW_SENSOR_READINGS` — the target table that Snowpipe will load data into.
- `CSV_PIPE_FORMAT` — a CSV file format matching the expected file layout.

### Step 3 — Create an Internal Stage

Run the `CREATE STAGE` statement to build `SENSOR_STAGE`. This internal stage will hold the CSV files that Snowpipe processes.

### Step 4 — Create a Pipe

Run the `CREATE PIPE` statement. Examine how the pipe wraps a `COPY INTO` command. Note the optional `AUTO_INGEST` parameter (set to `FALSE` for this lab).

### Step 5 — Inspect the Pipe

Run `DESCRIBE PIPE` and `SHOW PIPES` to view pipe metadata, the embedded SQL definition, and the notification channel (relevant for auto-ingest).

### Step 6 — Check Pipe Status

Run `SELECT SYSTEM$PIPE_STATUS('sensor_pipe')` to see the JSON status output. Understand the fields: `executionState`, `pendingFileCount`, `lastIngestedTimestamp`, etc.

### Step 7 — Stage Sample Files and Refresh

Run the provided script that generates sample CSV data, stages it, and then executes `ALTER PIPE sensor_pipe REFRESH`. This simulates the event notification that would normally trigger Snowpipe.

### Step 8 — Verify Loaded Data

Query the target table to confirm that rows arrived. Also query the `COPY_HISTORY` table function to see detailed load metadata.

### Step 9 — Pause and Resume the Pipe

Run `ALTER PIPE sensor_pipe SET PIPE_EXECUTION_PAUSED = TRUE` and observe the status change. Then resume and confirm it returns to `RUNNING`.

### Step 10 — Monitor Serverless Costs

Query `PIPE_USAGE_HISTORY` in `INFORMATION_SCHEMA` to understand Snowpipe's serverless credit consumption.

### Step 11 — Error Handling and Pipe Recreation

Review the section on handling bad files and recreating pipes when the schema changes.

### Step 12 — Understand AUTO_INGEST Architecture

Read the conceptual walkthrough of how `AUTO_INGEST = TRUE` works with external stages and cloud event notifications. No execution is required for this step.

### Step 13 — Cleanup

Run the cleanup section to drop the pipe, stage, tables, and schema created during this lab.

---

## Best Practices

### File Sizing

- **Target 100 MB to 250 MB** of compressed data per file. Snowpipe loads each file as a unit; very small files (< 10 MB) create overhead, while very large files (> 1 GB) increase latency.
- If your source produces many tiny files, consider batching them before staging or using a `PATTERN` clause in your pipe's `COPY INTO`.

### File Organization

- Organize files by **date or timestamp prefix** (e.g., `data/2026/02/11/readings_001.csv`). This makes `REFRESH` scoping and troubleshooting easier.
- Use a **dedicated stage path per pipe**. Avoid sharing a single stage path across multiple pipes.

### Pipe Design

- Keep the `COPY INTO` in your pipe as **simple as possible**. Avoid complex transformations; load raw data first and transform downstream with views or tasks.
- Use `MATCH_BY_COLUMN_NAME` or explicit column mapping when your file layout may evolve.
- Always define an explicit **file format** rather than relying on defaults.

### Monitoring

- Schedule periodic checks of `COPY_HISTORY` and `PIPE_USAGE_HISTORY` to detect failures and cost anomalies.
- Set up **alerts** (using Snowflake Alerts or external monitoring) on `SYSTEM$PIPE_STATUS()` to catch stalled pipes.

### Idempotency

- Snowpipe tracks loaded files for **14 days**. If you re-stage a file with the same name after 14 days, it will be loaded again.
- Never rename and re-upload a file expecting deduplication — Snowpipe tracks by file path and name.

### Cost Management

- Snowpipe charges are based on **per-second serverless compute** plus a **0.06-credit overhead per file**. Fewer, larger files are more cost-effective.
- Use `PIPE_USAGE_HISTORY` to track spending and set resource monitors if needed.

---

## Review Questions

1. **What is Snowpipe and how does it differ from a traditional `COPY INTO` command?**
   Snowpipe is a serverless, event-driven ingestion service that loads data automatically as files arrive, whereas `COPY INTO` must be executed manually or on a schedule using a virtual warehouse.

2. **What are the two ways to trigger Snowpipe to load a file?**
   (a) `AUTO_INGEST = TRUE` with cloud event notifications. (b) Calling the Snowpipe REST API `insertFiles` endpoint.

3. **What does `ALTER PIPE ... REFRESH` do?**
   It tells Snowpipe to scan the stage for any files that have not yet been loaded and queue them for ingestion. This is useful for backfilling or testing.

4. **What information does `SYSTEM$PIPE_STATUS()` return?**
   A JSON object containing the pipe's execution state, the count of pending files, the last ingested file timestamp, the notification channel, and error details if any.

5. **Why is file size important for Snowpipe efficiency?**
   Snowpipe loads each file as an atomic unit. Very small files incur disproportionate overhead (the per-file charge), while very large files increase end-to-end latency. The recommended range is 100 MB to 250 MB compressed.

6. **How long does Snowpipe remember which files it has already loaded?**
   14 days. After that window, re-staging a file with the same name will cause it to be loaded again.

7. **How do you pause a running pipe?**
   `ALTER PIPE <name> SET PIPE_EXECUTION_PAUSED = TRUE;`

8. **Where can you check the serverless compute costs incurred by Snowpipe?**
   The `SNOWFLAKE.ACCOUNT_USAGE.PIPE_USAGE_HISTORY` view or the `INFORMATION_SCHEMA.PIPE_USAGE_HISTORY` table function.

9. **What happens if a file staged for Snowpipe contains malformed rows?**
   Behavior depends on the pipe's `ON_ERROR` setting. With `SKIP_FILE` (default for pipes), the entire file is skipped and recorded as an error in `COPY_HISTORY`. With `CONTINUE`, valid rows are loaded and bad rows are skipped.

10. **Can you modify the `COPY INTO` statement inside an existing pipe?**
    No. You must recreate the pipe (`CREATE OR REPLACE PIPE`) with the updated statement.

---

## Summary

In this lab you learned how to:

- Create a Snowpipe pipe object that wraps a `COPY INTO` statement.
- Inspect pipes with `DESCRIBE PIPE`, `SHOW PIPES`, and `SYSTEM$PIPE_STATUS()`.
- Manually trigger ingestion with `ALTER PIPE ... REFRESH`.
- Monitor load history and serverless costs.
- Pause, resume, and recreate pipes.
- Understand the auto-ingest architecture with cloud event notifications.

Snowpipe is the foundation for near real-time data ingestion in Snowflake. Combined with Streams and Tasks (covered in later labs), it enables fully automated, end-to-end data pipelines without managing any compute infrastructure.
