/***********************************************************************
 *  LAB 10 — SNOWPIPE: CONTINUOUS, AUTOMATED DATA LOADING
 *
 *  Objective : Learn how to create and manage Snowpipe pipes for
 *              continuous data ingestion into Snowflake.
 *
 *  Duration  : ~30 minutes
 *
 *  What we cover:
 *    1.  Environment setup
 *    2.  Source table and file format creation
 *    3.  Internal stage creation
 *    4.  Pipe creation (CREATE PIPE ... AS COPY INTO)
 *    5.  Inspecting pipes (DESCRIBE PIPE, SHOW PIPES)
 *    6.  Checking pipe status (SYSTEM$PIPE_STATUS)
 *    7.  Simulating data loading with manual REFRESH
 *    8.  Monitoring with COPY_HISTORY
 *    9.  Pausing and resuming pipes
 *   10.  Pipe recreation and error handling
 *   11.  AUTO_INGEST architecture (conceptual)
 *   12.  Serverless cost monitoring (PIPE_USAGE_HISTORY)
 *   13.  Cleanup
 *
 *  NOTE: Full Snowpipe auto-ingest requires cloud event notification
 *        infrastructure (S3 SQS, Azure Event Grid, GCS Pub/Sub).
 *        This lab uses ALTER PIPE ... REFRESH to simulate the trigger.
 *        All monitoring and management techniques are identical
 *        regardless of trigger mode.
 ***********************************************************************/


-- =====================================================================
-- SECTION 1: ENVIRONMENT SETUP
-- =====================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE WORKSHOP_DB;

-- Create a dedicated schema for this lab
CREATE SCHEMA IF NOT EXISTS SNOWPIPE_LAB;
USE SCHEMA SNOWPIPE_LAB;

-- Confirm context
SELECT CURRENT_DATABASE()  AS current_db,
       CURRENT_SCHEMA()    AS current_schema,
       CURRENT_WAREHOUSE() AS current_warehouse;


-- =====================================================================
-- SECTION 2: CREATE SOURCE TABLES
-- =====================================================================
-- We will simulate IoT sensor data landing continuously.
-- Snowpipe will load each new file into this table automatically.

CREATE OR REPLACE TABLE RAW_SENSOR_READINGS (
    sensor_id       VARCHAR(20),
    reading_ts      TIMESTAMP_NTZ,
    temperature_c   FLOAT,
    humidity_pct    FLOAT,
    pressure_hpa    FLOAT,
    battery_pct     FLOAT,
    location        VARCHAR(50),
    loaded_at       TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()  -- audit column
);

-- A second table to demonstrate a separate pipe
CREATE OR REPLACE TABLE RAW_DEVICE_EVENTS (
    event_id        VARCHAR(36),
    device_id       VARCHAR(20),
    event_type      VARCHAR(30),
    event_ts        TIMESTAMP_NTZ,
    payload         VARIANT,
    loaded_at       TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

SELECT 'Tables created successfully' AS status;


-- =====================================================================
-- SECTION 3: CREATE FILE FORMATS
-- =====================================================================
-- Pipes reference file formats just like regular COPY INTO commands.

-- CSV format for sensor readings
CREATE OR REPLACE FILE FORMAT CSV_PIPE_FORMAT
    TYPE                = 'CSV'
    FIELD_DELIMITER     = ','
    SKIP_HEADER         = 1
    NULL_IF             = ('NULL', 'null', '')
    EMPTY_FIELD_AS_NULL = TRUE
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    TRIM_SPACE          = TRUE
    DATE_FORMAT         = 'AUTO'
    TIMESTAMP_FORMAT    = 'AUTO'
    COMMENT             = 'CSV format for Snowpipe sensor data ingestion';

-- JSON format for device events
CREATE OR REPLACE FILE FORMAT JSON_PIPE_FORMAT
    TYPE              = 'JSON'
    STRIP_OUTER_ARRAY = TRUE
    COMMENT           = 'JSON format for Snowpipe device event ingestion';

SHOW FILE FORMATS IN SCHEMA SNOWPIPE_LAB;


-- =====================================================================
-- SECTION 4: CREATE INTERNAL STAGES
-- =====================================================================
-- In production you would typically use an external stage (S3, Azure
-- Blob, GCS) with AUTO_INGEST. Here we use internal stages and
-- manual REFRESH to demonstrate the same pipe mechanics.

CREATE OR REPLACE STAGE SENSOR_STAGE
    FILE_FORMAT = CSV_PIPE_FORMAT
    COMMENT     = 'Internal stage for sensor CSV files';

CREATE OR REPLACE STAGE DEVICE_EVENT_STAGE
    FILE_FORMAT = JSON_PIPE_FORMAT
    COMMENT     = 'Internal stage for device event JSON files';

SHOW STAGES IN SCHEMA SNOWPIPE_LAB;


-- =====================================================================
-- SECTION 5: CREATE PIPES
-- =====================================================================
-- A pipe wraps a COPY INTO statement. Snowpipe executes this statement
-- each time it detects new files (via event notification or REFRESH).
--
-- Key points:
--   • AUTO_INGEST = FALSE  means we trigger loads manually (REFRESH).
--   • The COPY INTO inside the pipe must reference a stage, not a path.
--   • The pipe does NOT use a warehouse — it runs on serverless compute.

-- Pipe 1: Sensor readings (CSV)
CREATE OR REPLACE PIPE SENSOR_PIPE
    AUTO_INGEST = FALSE
    COMMENT     = 'Loads CSV sensor readings from SENSOR_STAGE into RAW_SENSOR_READINGS'
AS
    COPY INTO RAW_SENSOR_READINGS (
        sensor_id,
        reading_ts,
        temperature_c,
        humidity_pct,
        pressure_hpa,
        battery_pct,
        location
    )
    FROM @SENSOR_STAGE
    FILE_FORMAT = (FORMAT_NAME = 'CSV_PIPE_FORMAT')
    ON_ERROR    = 'SKIP_FILE';

-- Pipe 2: Device events (JSON)
CREATE OR REPLACE PIPE DEVICE_EVENT_PIPE
    AUTO_INGEST = FALSE
    COMMENT     = 'Loads JSON device events from DEVICE_EVENT_STAGE into RAW_DEVICE_EVENTS'
AS
    COPY INTO RAW_DEVICE_EVENTS (
        event_id,
        device_id,
        event_type,
        event_ts,
        payload
    )
    FROM (
        SELECT
            $1:event_id::VARCHAR,
            $1:device_id::VARCHAR,
            $1:event_type::VARCHAR,
            $1:event_ts::TIMESTAMP_NTZ,
            $1
        FROM @DEVICE_EVENT_STAGE
    )
    FILE_FORMAT = (FORMAT_NAME = 'JSON_PIPE_FORMAT')
    ON_ERROR    = 'SKIP_FILE';

SELECT 'Pipes created successfully' AS status;


-- =====================================================================
-- SECTION 6: INSPECT PIPES — DESCRIBE PIPE & SHOW PIPES
-- =====================================================================

-- DESCRIBE PIPE shows the pipe definition and its creation timestamp
DESCRIBE PIPE SENSOR_PIPE;

DESCRIBE PIPE DEVICE_EVENT_PIPE;

-- SHOW PIPES lists all pipes in the current context with metadata
-- such as notification_channel (used for AUTO_INGEST), owner, etc.
SHOW PIPES IN SCHEMA SNOWPIPE_LAB;

-- You can also query the SHOW output with a result scan
SELECT "name",
       "database_name",
       "schema_name",
       "definition",
       "notification_channel",
       "comment"
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));


-- =====================================================================
-- SECTION 7: CHECK PIPE STATUS — SYSTEM$PIPE_STATUS()
-- =====================================================================
-- SYSTEM$PIPE_STATUS returns a JSON string with:
--   executionState      : RUNNING | PAUSED | STALLED
--   pendingFileCount    : number of files queued for loading
--   lastIngestedTimestamp: when the pipe last loaded a file
--   notificationChannelName: SQS/Event Grid/Pub-Sub channel (if any)

SELECT SYSTEM$PIPE_STATUS('SENSOR_PIPE') AS pipe_status;

-- Parse the JSON for readability
SELECT
    PARSE_JSON(SYSTEM$PIPE_STATUS('SENSOR_PIPE')):executionState::STRING       AS execution_state,
    PARSE_JSON(SYSTEM$PIPE_STATUS('SENSOR_PIPE')):pendingFileCount::INT        AS pending_files,
    PARSE_JSON(SYSTEM$PIPE_STATUS('SENSOR_PIPE')):lastIngestedTimestamp::STRING AS last_ingested
;


-- =====================================================================
-- SECTION 8: SIMULATE DATA LOADING — STAGE FILES & MANUAL REFRESH
-- =====================================================================
-- Since we are using an internal stage, we will:
--   (a) Generate sample data into a temporary table
--   (b) COPY INTO the stage (unload) to create files
--   (c) Use ALTER PIPE ... REFRESH to trigger Snowpipe
--
-- In production with AUTO_INGEST, steps (a)-(c) would be replaced by
-- your application simply uploading files to the external stage.

-- 8a. Generate sample sensor data (batch 1)
CREATE OR REPLACE TEMPORARY TABLE TEMP_SENSOR_BATCH_1 AS
SELECT
    'SENS-' || LPAD(SEQ4()::VARCHAR, 4, '0')                   AS sensor_id,
    DATEADD('minute', -SEQ4(), CURRENT_TIMESTAMP())::TIMESTAMP_NTZ AS reading_ts,
    ROUND(20 + UNIFORM(0::FLOAT, 15::FLOAT, RANDOM()), 2)      AS temperature_c,
    ROUND(30 + UNIFORM(0::FLOAT, 50::FLOAT, RANDOM()), 2)      AS humidity_pct,
    ROUND(1000 + UNIFORM(0::FLOAT, 30::FLOAT, RANDOM()), 2)    AS pressure_hpa,
    ROUND(50 + UNIFORM(0::FLOAT, 50::FLOAT, RANDOM()), 2)      AS battery_pct,
    CASE MOD(SEQ4(), 4)
        WHEN 0 THEN 'Building-A'
        WHEN 1 THEN 'Building-B'
        WHEN 2 THEN 'Warehouse-1'
        ELSE        'Warehouse-2'
    END                                                          AS location
FROM TABLE(GENERATOR(ROWCOUNT => 100));

-- 8b. Unload batch 1 into the internal stage as a CSV file
COPY INTO @SENSOR_STAGE/batch_001/
FROM TEMP_SENSOR_BATCH_1
FILE_FORMAT = (
    TYPE            = 'CSV'
    FIELD_DELIMITER = ','
    HEADER          = TRUE
)
OVERWRITE       = TRUE
SINGLE          = TRUE
MAX_FILE_SIZE   = 50000000;

-- Verify the file is on the stage
LIST @SENSOR_STAGE;

-- 8c. Trigger Snowpipe to load the staged file
--     ALTER PIPE ... REFRESH tells Snowpipe to scan the stage path
--     and queue any new (unloaded) files for processing.
ALTER PIPE SENSOR_PIPE REFRESH;

-- The load is asynchronous. Wait a few seconds, then check the table.
-- (In a worksheet you can simply re-run the SELECT below after a moment.)

-- Give Snowpipe a moment to process
-- In practice, internal-stage pipes with REFRESH load quickly.
CALL SYSTEM$WAIT(5);  -- wait 5 seconds

-- 8d. Verify data loaded into the target table
SELECT COUNT(*)       AS row_count FROM RAW_SENSOR_READINGS;
SELECT TOP 10 *       FROM RAW_SENSOR_READINGS ORDER BY reading_ts DESC;

-- ---------------------------------------------------------------
-- Stage a second batch to see Snowpipe handle incremental loads
-- ---------------------------------------------------------------

CREATE OR REPLACE TEMPORARY TABLE TEMP_SENSOR_BATCH_2 AS
SELECT
    'SENS-' || LPAD((100 + SEQ4())::VARCHAR, 4, '0')             AS sensor_id,
    DATEADD('second', -SEQ4(), CURRENT_TIMESTAMP())::TIMESTAMP_NTZ AS reading_ts,
    ROUND(18 + UNIFORM(0::FLOAT, 12::FLOAT, RANDOM()), 2)        AS temperature_c,
    ROUND(35 + UNIFORM(0::FLOAT, 40::FLOAT, RANDOM()), 2)        AS humidity_pct,
    ROUND(1005 + UNIFORM(0::FLOAT, 25::FLOAT, RANDOM()), 2)      AS pressure_hpa,
    ROUND(60 + UNIFORM(0::FLOAT, 40::FLOAT, RANDOM()), 2)        AS battery_pct,
    CASE MOD(SEQ4(), 3)
        WHEN 0 THEN 'Factory-Floor'
        WHEN 1 THEN 'Cold-Storage'
        ELSE        'Server-Room'
    END                                                            AS location
FROM TABLE(GENERATOR(ROWCOUNT => 50));

COPY INTO @SENSOR_STAGE/batch_002/
FROM TEMP_SENSOR_BATCH_2
FILE_FORMAT = (
    TYPE            = 'CSV'
    FIELD_DELIMITER = ','
    HEADER          = TRUE
)
OVERWRITE       = TRUE
SINGLE          = TRUE
MAX_FILE_SIZE   = 50000000;

-- Refresh the pipe — only the NEW file will be loaded (idempotent)
ALTER PIPE SENSOR_PIPE REFRESH;

CALL SYSTEM$WAIT(5);

-- Confirm row count increased
SELECT COUNT(*) AS total_rows FROM RAW_SENSOR_READINGS;


-- =====================================================================
-- SECTION 9: MONITOR PIPE LOAD HISTORY — COPY_HISTORY TABLE FUNCTION
-- =====================================================================
-- COPY_HISTORY shows every file loaded, its status, row counts, and
-- error details. This is your primary troubleshooting tool.

SELECT
    pipe_catalog_name   AS database_name,
    pipe_schema_name    AS schema_name,
    pipe_name,
    file_name,
    stage_location,
    status,                        -- 'Loaded', 'Load_Failed', 'Partially_Loaded'
    row_count,
    row_parsed,
    error_count,
    first_error_message,
    last_load_time
FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(
    TABLE_NAME       => 'RAW_SENSOR_READINGS',
    START_TIME       => DATEADD('hour', -1, CURRENT_TIMESTAMP())
))
ORDER BY last_load_time DESC;


-- =====================================================================
-- SECTION 10: PAUSE AND RESUME PIPES
-- =====================================================================
-- Pausing a pipe stops it from processing new event notifications.
-- Files staged while the pipe is paused will be loaded once it resumes
-- (or when you manually REFRESH after resuming).

-- 10a. Pause the pipe
ALTER PIPE SENSOR_PIPE SET PIPE_EXECUTION_PAUSED = TRUE;

-- Verify paused state
SELECT
    PARSE_JSON(SYSTEM$PIPE_STATUS('SENSOR_PIPE')):executionState::STRING AS execution_state;
-- Expected: "PAUSED"

-- 10b. Resume the pipe
ALTER PIPE SENSOR_PIPE SET PIPE_EXECUTION_PAUSED = FALSE;

-- Verify running state
SELECT
    PARSE_JSON(SYSTEM$PIPE_STATUS('SENSOR_PIPE')):executionState::STRING AS execution_state;
-- Expected: "RUNNING"

-- 10c. Force-resume a stalled pipe
-- If a pipe enters a STALLED state (rare, usually due to transient
-- errors), you can force it back to RUNNING:
--
--   SELECT SYSTEM$PIPE_FORCE_RESUME('SENSOR_PIPE');
--
-- Only use this when SYSTEM$PIPE_STATUS reports "STALLED".


-- =====================================================================
-- SECTION 11: PIPE RECREATION AND ERROR HANDLING
-- =====================================================================

-- -----------------------------------------------------------------
-- 11a. Handling Schema Changes
-- -----------------------------------------------------------------
-- If you need to change the target table schema or the COPY INTO
-- logic, you must recreate the pipe. You CANNOT alter the embedded
-- COPY statement in place.

-- Example: Add a new column to the target table
ALTER TABLE RAW_SENSOR_READINGS ADD COLUMN quality_flag VARCHAR(10) DEFAULT 'OK';

-- Recreate the pipe to include the new column mapping
CREATE OR REPLACE PIPE SENSOR_PIPE
    AUTO_INGEST = FALSE
    COMMENT     = 'v2 — includes quality_flag column'
AS
    COPY INTO RAW_SENSOR_READINGS (
        sensor_id,
        reading_ts,
        temperature_c,
        humidity_pct,
        pressure_hpa,
        battery_pct,
        location
        -- quality_flag will use its DEFAULT value
    )
    FROM @SENSOR_STAGE
    FILE_FORMAT = (FORMAT_NAME = 'CSV_PIPE_FORMAT')
    ON_ERROR    = 'SKIP_FILE';

-- NOTE: CREATE OR REPLACE PIPE resets the pipe's file-tracking metadata.
-- Any files previously loaded will NOT be reloaded unless you REFRESH
-- with a specific PREFIX that includes those files.

-- -----------------------------------------------------------------
-- 11b. ON_ERROR Options for Pipes
-- -----------------------------------------------------------------
-- ON_ERROR controls what happens when a file contains bad records:
--
--   'SKIP_FILE'       — (Default for pipes) Skip the entire file.
--                        The file is marked as 'Load_Failed' in
--                        COPY_HISTORY.
--
--   'CONTINUE'        — Load valid rows and skip bad rows.
--                        Partially loaded files appear as
--                        'Partially_Loaded' in COPY_HISTORY.
--
--   'ABORT_STATEMENT' — NOT supported in Snowpipe. Only for manual
--                        COPY INTO.

-- -----------------------------------------------------------------
-- 11c. Staging a Malformed File to See Error Handling
-- -----------------------------------------------------------------

-- Create a file with bad data (non-numeric in a FLOAT column)
CREATE OR REPLACE TEMPORARY TABLE TEMP_BAD_DATA AS
SELECT
    'BAD-0001'                           AS sensor_id,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ   AS reading_ts,
    'NOT_A_NUMBER'                       AS temperature_c,   -- will fail FLOAT cast
    50.0                                 AS humidity_pct,
    1013.0                               AS pressure_hpa,
    80.0                                 AS battery_pct,
    'Test-Location'                      AS location;

COPY INTO @SENSOR_STAGE/bad_batch/
FROM TEMP_BAD_DATA
FILE_FORMAT = (
    TYPE            = 'CSV'
    FIELD_DELIMITER = ','
    HEADER          = TRUE
)
OVERWRITE = TRUE
SINGLE    = TRUE;

-- Trigger the pipe
ALTER PIPE SENSOR_PIPE REFRESH PREFIX = 'bad_batch/';

CALL SYSTEM$WAIT(5);

-- Check COPY_HISTORY for errors
SELECT
    file_name,
    status,
    row_count,
    error_count,
    first_error_message
FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(
    TABLE_NAME => 'RAW_SENSOR_READINGS',
    START_TIME => DATEADD('hour', -1, CURRENT_TIMESTAMP())
))
WHERE status != 'Loaded'
ORDER BY last_load_time DESC;

-- The bad file should show status = 'Load_Failed' with an error message.


-- =====================================================================
-- SECTION 12: AUTO_INGEST ARCHITECTURE (CONCEPTUAL)
-- =====================================================================
-- This section explains how to set up fully automated ingestion.
-- No SQL execution is required — read through the comments.

/*
  ┌─────────────────────────────────────────────────────────────────┐
  │                    AUTO_INGEST = TRUE SETUP                     │
  ├─────────────────────────────────────────────────────────────────┤
  │                                                                 │
  │  1. CREATE AN EXTERNAL STAGE pointing to your cloud bucket:     │
  │                                                                 │
  │     CREATE OR REPLACE STAGE my_s3_stage                         │
  │         URL = 's3://my-bucket/sensor-data/'                     │
  │         STORAGE_INTEGRATION = my_s3_integration                 │
  │         FILE_FORMAT = CSV_PIPE_FORMAT;                          │
  │                                                                 │
  │  2. CREATE THE PIPE with AUTO_INGEST = TRUE:                    │
  │                                                                 │
  │     CREATE OR REPLACE PIPE auto_sensor_pipe                     │
  │         AUTO_INGEST = TRUE                                      │
  │     AS                                                          │
  │         COPY INTO RAW_SENSOR_READINGS                           │
  │         FROM @my_s3_stage                                       │
  │         FILE_FORMAT = (FORMAT_NAME = 'CSV_PIPE_FORMAT');        │
  │                                                                 │
  │  3. RETRIEVE THE NOTIFICATION CHANNEL:                          │
  │                                                                 │
  │     SHOW PIPES LIKE 'AUTO_SENSOR_PIPE';                         │
  │     -- Copy the "notification_channel" value (an SQS ARN).     │
  │                                                                 │
  │  4. CONFIGURE THE CLOUD EVENT NOTIFICATION:                     │
  │                                                                 │
  │     AWS  : Create an S3 Event Notification that sends           │
  │            "s3:ObjectCreated:*" events to the SQS queue ARN     │
  │            returned above.                                      │
  │                                                                 │
  │     Azure: Configure Event Grid on the blob container to        │
  │            send notifications to Snowflake's queue.             │
  │                                                                 │
  │     GCS  : Set up a Pub/Sub subscription on the GCS bucket      │
  │            notifications and grant Snowflake's service account  │
  │            subscriber access.                                   │
  │                                                                 │
  │  5. VERIFY:                                                     │
  │     Upload a file to the bucket and check:                      │
  │       - SYSTEM$PIPE_STATUS('AUTO_SENSOR_PIPE')                  │
  │       - SELECT * FROM RAW_SENSOR_READINGS;                      │
  │                                                                 │
  │  Once configured, every new file in the bucket path triggers    │
  │  Snowpipe automatically — no REFRESH needed.                    │
  │                                                                 │
  ├─────────────────────────────────────────────────────────────────┤
  │  REST API ALTERNATIVE (insertFiles endpoint):                   │
  │                                                                 │
  │  If you cannot set up cloud event notifications, your           │
  │  application can call the Snowpipe REST API after uploading:    │
  │                                                                 │
  │    POST https://<account>.snowflakecomputing.com/               │
  │         v1/data/pipes/<db>.<schema>.<pipe>/insertFiles          │
  │    Body: { "files": [{"path": "batch_003/data.csv"}] }         │
  │                                                                 │
  │  This requires key-pair authentication and a Snowpipe SDK       │
  │  (available for Java, Python, and other languages).             │
  └─────────────────────────────────────────────────────────────────┘
*/


-- =====================================================================
-- SECTION 13: SERVERLESS COST MONITORING — PIPE_USAGE_HISTORY
-- =====================================================================
-- Snowpipe runs on Snowflake-managed serverless compute. You are
-- billed per second of compute time plus a per-file overhead.
-- Use PIPE_USAGE_HISTORY to track these costs.

-- 13a. Query INFORMATION_SCHEMA for recent pipe usage
SELECT
    pipe_name,
    start_time,
    end_time,
    credits_used,
    bytes_inserted,
    files_inserted
FROM TABLE(INFORMATION_SCHEMA.PIPE_USAGE_HISTORY(
    DATE_RANGE_START => DATEADD('day', -1, CURRENT_TIMESTAMP()),
    DATE_RANGE_END   => CURRENT_TIMESTAMP()
))
ORDER BY start_time DESC;

-- 13b. Query ACCOUNT_USAGE for longer-range analysis (up to 365 days)
-- NOTE: ACCOUNT_USAGE views have a ~45-minute latency.
-- Uncomment the query below if you want to check later.

-- USE ROLE ACCOUNTADMIN;
-- SELECT
--     pipe_name,
--     DATE_TRUNC('hour', start_time) AS usage_hour,
--     SUM(credits_used)              AS total_credits,
--     SUM(bytes_inserted)            AS total_bytes,
--     SUM(files_inserted)            AS total_files
-- FROM SNOWFLAKE.ACCOUNT_USAGE.PIPE_USAGE_HISTORY
-- WHERE start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
-- GROUP BY pipe_name, usage_hour
-- ORDER BY usage_hour DESC;
-- USE ROLE SYSADMIN;


-- =====================================================================
-- SECTION 14: BONUS — PIPE WITH TRANSFORMATIONS
-- =====================================================================
-- Pipes can include column transformations in the SELECT from stage.
-- Here is an example that adds metadata columns during ingestion.

CREATE OR REPLACE TABLE RAW_SENSOR_ENRICHED (
    sensor_id       VARCHAR(20),
    reading_ts      TIMESTAMP_NTZ,
    temperature_c   FLOAT,
    humidity_pct    FLOAT,
    pressure_hpa    FLOAT,
    battery_pct     FLOAT,
    location        VARCHAR(50),
    source_file     VARCHAR(500),    -- which file this row came from
    file_row_num    INT,             -- row number within the file
    ingested_at     TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE OR REPLACE PIPE SENSOR_ENRICHED_PIPE
    AUTO_INGEST = FALSE
    COMMENT     = 'Enriched pipe that captures source file metadata'
AS
    COPY INTO RAW_SENSOR_ENRICHED (
        sensor_id,
        reading_ts,
        temperature_c,
        humidity_pct,
        pressure_hpa,
        battery_pct,
        location,
        source_file,
        file_row_num
    )
    FROM (
        SELECT
            $1,                          -- sensor_id
            $2,                          -- reading_ts
            $3,                          -- temperature_c
            $4,                          -- humidity_pct
            $5,                          -- pressure_hpa
            $6,                          -- battery_pct
            $7,                          -- location
            METADATA$FILENAME,           -- source file path
            METADATA$FILE_ROW_NUMBER     -- row number in file
        FROM @SENSOR_STAGE
    )
    FILE_FORMAT = (FORMAT_NAME = 'CSV_PIPE_FORMAT')
    ON_ERROR    = 'SKIP_FILE';

-- Test the enriched pipe with existing staged files
ALTER PIPE SENSOR_ENRICHED_PIPE REFRESH;

CALL SYSTEM$WAIT(5);

SELECT
    sensor_id,
    reading_ts,
    temperature_c,
    source_file,
    file_row_num,
    ingested_at
FROM RAW_SENSOR_ENRICHED
ORDER BY file_row_num
LIMIT 10;


-- =====================================================================
-- SECTION 15: SUMMARY OF KEY COMMANDS
-- =====================================================================

/*
  ┌─────────────────────────────────────────────────────────────────┐
  │  SNOWPIPE COMMAND CHEAT SHEET                                   │
  ├─────────────────────────────────────────────────────────────────┤
  │                                                                 │
  │  CREATE PIPE <name> AUTO_INGEST = TRUE|FALSE AS COPY INTO ...   │
  │    → Define a new pipe with its embedded COPY statement.        │
  │                                                                 │
  │  DESCRIBE PIPE <name>                                           │
  │    → Show the pipe definition and metadata.                     │
  │                                                                 │
  │  SHOW PIPES [ IN SCHEMA | IN DATABASE ]                         │
  │    → List all pipes and their properties.                       │
  │                                                                 │
  │  ALTER PIPE <name> REFRESH [ PREFIX = '<path>' ]                │
  │    → Manually trigger Snowpipe to scan for new files.           │
  │                                                                 │
  │  ALTER PIPE <name> SET PIPE_EXECUTION_PAUSED = TRUE|FALSE       │
  │    → Pause or resume the pipe.                                  │
  │                                                                 │
  │  SELECT SYSTEM$PIPE_STATUS('<name>')                            │
  │    → Return JSON with execution state, pending files, etc.      │
  │                                                                 │
  │  SELECT SYSTEM$PIPE_FORCE_RESUME('<name>')                      │
  │    → Force-resume a stalled pipe.                               │
  │                                                                 │
  │  INFORMATION_SCHEMA.COPY_HISTORY(...)                           │
  │    → File-level load status, row counts, and errors.            │
  │                                                                 │
  │  INFORMATION_SCHEMA.PIPE_USAGE_HISTORY(...)                     │
  │    → Serverless credit consumption per pipe.                    │
  │                                                                 │
  │  DROP PIPE <name>                                               │
  │    → Remove the pipe. Does NOT affect the target table data.    │
  └─────────────────────────────────────────────────────────────────┘
*/


-- =====================================================================
-- SECTION 16: CLEANUP
-- =====================================================================
-- Remove all objects created in this lab.
-- Uncomment and run when you are finished.

-- DROP PIPE IF EXISTS SENSOR_ENRICHED_PIPE;
-- DROP PIPE IF EXISTS DEVICE_EVENT_PIPE;
-- DROP PIPE IF EXISTS SENSOR_PIPE;
-- DROP TABLE IF EXISTS RAW_SENSOR_ENRICHED;
-- DROP TABLE IF EXISTS RAW_DEVICE_EVENTS;
-- DROP TABLE IF EXISTS RAW_SENSOR_READINGS;
-- DROP STAGE IF EXISTS DEVICE_EVENT_STAGE;
-- DROP STAGE IF EXISTS SENSOR_STAGE;
-- DROP FILE FORMAT IF EXISTS JSON_PIPE_FORMAT;
-- DROP FILE FORMAT IF EXISTS CSV_PIPE_FORMAT;
-- DROP SCHEMA IF EXISTS SNOWPIPE_LAB;

-- Verify cleanup
-- SHOW SCHEMAS LIKE 'SNOWPIPE_LAB' IN DATABASE WORKSHOP_DB;

SELECT 'Lab 10 complete — Snowpipe fundamentals covered!' AS status;
