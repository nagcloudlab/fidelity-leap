# Lab 04: Loading Data

## Objective
Learn how to load data into Snowflake using stages, file formats, and the COPY INTO command. You will create internal stages, define file formats for CSV and JSON, load and transform data during ingestion, validate load results, and unload data back to a stage.

## Duration: 45 minutes

---

## Key Concepts

- **Stage** -- A named location where data files are held before (or after) loading. Stages can be internal (managed by Snowflake) or external (S3, GCS, Azure Blob)
- **Internal Stage Types**:
  - **User Stage** (`@~`) -- Every user gets one automatically; private to that user
  - **Table Stage** (`@%table_name`) -- Every table gets one automatically; scoped to that table
  - **Named Stage** (`@my_stage`) -- Created explicitly with CREATE STAGE; can be shared and reused
- **External Stage** -- Points to cloud storage (S3, GCS, Azure) using a URL and optional credentials
- **File Format** -- A named object that describes the structure of data files (delimiters, headers, compression, etc.)
- **Supported Formats** -- CSV, JSON, Avro, ORC, Parquet, XML
- **COPY INTO (table)** -- Loads data from a stage into a table
- **COPY INTO (location)** -- Unloads data from a table back into a stage
- **PUT Command** -- Uploads local files to an internal stage (SnowSQL / CLI only; not available in worksheets)
- **Data Transformation During Load** -- You can reorder columns, cast data types, apply expressions, and concatenate fields as part of the COPY INTO statement

---

## How Data Loading Works in Snowflake

```
Local Files ──PUT──> Internal Stage ──COPY INTO──> Table
                                                     │
Cloud Storage ──> External Stage ──COPY INTO──> Table │
                                                     │
                          Table ──COPY INTO──> Stage (Unload)
```

1. **Prepare** -- Create the target table, file format, and stage
2. **Stage** -- Upload files to the stage (PUT for internal, or they already exist in cloud storage)
3. **Load** -- Run COPY INTO to load staged files into the table
4. **Validate** -- Use VALIDATE() or query the table to confirm the load

---

## Step-by-Step Instructions

### Step 1: Set up context
Switch to the SYSADMIN role and set your database and schema to WORKSHOP_DB.RAW.

### Step 2: Create file formats
Create named file format objects for CSV and JSON. These define how Snowflake should parse incoming data files (delimiters, headers, null handling, etc.).

### Step 3: Create internal named stages
Create stages that reference the file formats you just built. Named stages are reusable and can be shared across multiple COPY INTO operations.

### Step 4: Create target tables
Create the destination tables that will receive loaded data, including tables with VARIANT columns for semi-structured JSON data.

### Step 5: Generate sample data and load CSV
Since the PUT command is unavailable in Snowsight worksheets, generate sample data inline and practice loading it through stages using COPY INTO with various options.

### Step 6: Load JSON data into a VARIANT column
Load semi-structured JSON data into a VARIANT column and then query it using dot notation and FLATTEN.

### Step 7: Transform data during load
Use the COPY INTO SELECT syntax to reorder columns, cast data types, concatenate fields, and apply expressions as data is loaded.

### Step 8: Use pattern matching
Load only files that match a specific naming pattern from a stage using the PATTERN option.

### Step 9: Validate load results
Use the VALIDATE() function to inspect any errors from the most recent COPY INTO operation.

### Step 10: Unload data to a stage
Use COPY INTO @stage to export table data back to a stage as files, which can then be downloaded or accessed by external tools.

### Step 11: Clean up
Remove temporary objects created during the lab while preserving structures needed for future labs.

---

## Best Practices for Data Loading

- **Use named file formats and stages** -- Reusable objects reduce errors and simplify maintenance
- **Start with ON_ERROR = 'SKIP_FILE'** during initial loads so one bad row does not abort the entire batch; switch to 'ABORT_STATEMENT' in production once data quality is confirmed
- **Use VALIDATION_MODE before loading** -- Run COPY INTO with VALIDATION_MODE = 'RETURN_ERRORS' to preview problems without actually loading data
- **Compress your files** -- Snowflake handles GZIP, BZIP2, Brotli, Zstandard, and more automatically; compressed files load faster and cost less to transfer
- **Split large files** -- Aim for 100-250 MB compressed per file; Snowflake loads multiple files in parallel
- **Use FORCE = FALSE (the default)** -- Snowflake tracks which files have been loaded and skips duplicates; only set FORCE = TRUE when you intentionally want to reload
- **Use PURGE = TRUE with caution** -- This deletes staged files after a successful load; make sure you have the originals elsewhere
- **Load semi-structured data into VARIANT columns** -- Let Snowflake handle schema inference; you can create views with explicit columns later

---

## Review Questions

1. What are the three types of internal stages, and when would you choose each one?
2. What is the difference between ON_ERROR = 'SKIP_FILE' and ON_ERROR = 'CONTINUE'?
3. Why can you not use the PUT command inside a Snowsight worksheet?
4. How does Snowflake prevent the same file from being loaded twice by default?
5. What column data type should you use to store raw JSON data, and how do you query individual keys from it?
6. Describe a scenario where you would transform data during load rather than loading it raw and transforming afterward.
