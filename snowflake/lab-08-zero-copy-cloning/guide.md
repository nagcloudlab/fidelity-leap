# Lab 08: Zero-Copy Cloning

## Objective
Learn how to use Snowflake's zero-copy cloning to instantly create copies of databases, schemas, and tables without duplicating storage -- enabling fast, cost-effective development, testing, and experimentation workflows.

## Duration: 25 minutes

---

## Key Concepts

- **Zero-Copy Cloning** -- Creates an instant copy of a database, schema, or table by duplicating only the metadata, not the underlying data
- **Metadata-Only Operation** -- The CLONE command copies pointers to existing micro-partitions rather than physically copying data, making it nearly instantaneous regardless of data size
- **Copy-on-Write** -- Cloned objects share the original micro-partitions until data is modified; only changed micro-partitions are written as new storage
- **Cloning Databases** -- CREATE DATABASE ... CLONE copies the entire database including all schemas, tables, views, and other objects
- **Cloning Schemas** -- CREATE SCHEMA ... CLONE copies all objects within a schema into a new schema
- **Cloning Tables** -- CREATE TABLE ... CLONE copies a single table with all its data and structure
- **COPY GRANTS** -- Optional clause that preserves the access control privileges from the source object on the cloned object
- **Cloning with Time Travel** -- Combine CLONE with AT or BEFORE to clone an object as it existed at a specific point in the past

---

## How Zero-Copy Cloning Works

When you clone a table, Snowflake does NOT physically copy data. Instead, both the original and the clone point to the same set of micro-partitions:

```
BEFORE CLONE:
  ORDERS (original)
    --> [Micro-Partition 1] [Micro-Partition 2] [Micro-Partition 3]

AFTER CLONE (instant -- metadata only):
  ORDERS (original)
    --> [Micro-Partition 1] [Micro-Partition 2] [Micro-Partition 3]
  ORDERS_CLONE
    --> [Micro-Partition 1] [Micro-Partition 2] [Micro-Partition 3]
        (same physical partitions -- no extra storage cost)

AFTER MODIFYING THE CLONE:
  ORDERS (original)
    --> [Micro-Partition 1] [Micro-Partition 2] [Micro-Partition 3]
  ORDERS_CLONE
    --> [Micro-Partition 1] [Micro-Partition 2*] [Micro-Partition 3]
                             ^^ new partition      (only changed data uses new storage)
```

This is the "copy-on-write" model. Storage costs increase only as the clone diverges from the original through inserts, updates, or deletes.

---

## Use Cases

- **Dev/Test Environments** -- Clone production data into a development or QA schema instantly, without waiting for ETL or paying for duplicate storage
- **Backup Before Changes** -- Clone a table before running a risky migration or transformation so you can roll back instantly if something goes wrong
- **Experimentation** -- Data scientists and analysts can clone datasets freely to test hypotheses without affecting shared production data
- **Sandboxing** -- Give each team member their own cloned copy of a dataset to work with independently
- **Training Environments** -- Spin up realistic training databases on demand for workshops or onboarding

---

## Step-by-Step Instructions

### Step 1: Set up sample data
Ensure WORKSHOP_DB exists with a populated table that we can clone from.

### Step 2: Clone a table
Use CREATE TABLE ... CLONE to create an instant copy of a table and verify the clone contains the same data as the original.

### Step 3: Modify the clone independently
Insert, update, or delete rows in the clone and confirm the original table is completely unaffected.

### Step 4: Examine storage usage
Query Snowflake metadata to observe that both the original and clone share storage initially, and additional storage is consumed only after modifications.

### Step 5: Clone a schema
Use CREATE SCHEMA ... CLONE to copy an entire schema and all its objects in a single command.

### Step 6: Clone a database
Use CREATE DATABASE ... CLONE to copy an entire database including all schemas, tables, and other objects.

### Step 7: Clone with Time Travel
Combine CLONE with AT(OFFSET => ...) to create a clone of a table as it existed at a previous point in time.

### Step 8: Clone with COPY GRANTS
Use the COPY GRANTS option to preserve access privileges when cloning objects.

### Step 9: Practical scenario -- dev copy of production
Walk through a realistic workflow of cloning production data for safe development and testing.

### Step 10: Clean up
Drop all cloned objects to keep the environment tidy.

---

## Best Practices

- Clone before making destructive changes (ALTER, DELETE, TRUNCATE) so you always have a rollback path
- Use cloning instead of CTAS (CREATE TABLE AS SELECT) when you need an exact copy -- cloning is instant and free
- Remember that clones are independent objects; dropping the original does NOT affect the clone (and vice versa)
- Combine cloning with Time Travel for powerful "undo" capabilities (clone from a past state)
- Use COPY GRANTS when cloning objects that need to retain the same access control policies
- Monitor storage over time -- as clones diverge from the original, storage costs will grow
- Clean up clones you no longer need to avoid unnecessary storage charges on modified data
- Be aware that cloning does NOT copy external stages, pipes, or tasks (only the objects within the scope of the clone)

---

## Review Questions

1. Does zero-copy cloning physically duplicate the underlying data? Why or why not?
2. What happens to storage costs when you modify data in a cloned table?
3. Can you clone a table as it existed 30 minutes ago? What Snowflake feature makes this possible?
4. If you drop the original table, what happens to the clone?
5. What is the difference between cloning a table and using CREATE TABLE AS SELECT (CTAS)?
6. When would you use the COPY GRANTS option during cloning?
7. Name three real-world scenarios where zero-copy cloning saves time or money.
