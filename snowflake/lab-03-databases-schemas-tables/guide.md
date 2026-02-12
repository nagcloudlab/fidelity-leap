# Lab 03: Databases, Schemas & Tables

## Objective
Learn DDL (Data Definition Language) operations for creating and managing databases, schemas, tables, and views -- the foundational objects that organize and store all data in Snowflake.

## Duration: 40 minutes

---

## Key Concepts

- **Database** -- The top-level container for all data objects in Snowflake. Every table, view, and schema lives inside a database
- **Schema** -- A logical grouping of objects (tables, views, functions) within a database. Used to organize by purpose (e.g., RAW, STAGING, ANALYTICS)
- **Permanent Table** -- The default table type. Data persists until explicitly dropped. Supports Time Travel and Fail-safe for data protection
- **Transient Table** -- Similar to permanent tables but without Fail-safe. Lower storage cost but less data protection. Good for intermediate/staging data
- **Temporary Table** -- Exists only for the duration of the session. Automatically dropped when the session ends. Ideal for scratch work
- **View** -- A named SQL query that acts like a virtual table. Does not store data; runs the query each time it is accessed
- **Secure View** -- A view whose definition (SQL text) is hidden from unauthorized users. Essential when sharing data or protecting business logic
- **Data Types** -- Snowflake supports structured types (VARCHAR, NUMBER, DATE, TIMESTAMP, BOOLEAN) and semi-structured types (VARIANT, ARRAY, OBJECT)
- **Constraints** -- Rules applied to columns (PRIMARY KEY, FOREIGN KEY, NOT NULL, UNIQUE). Snowflake enforces NOT NULL but treats other constraints as informational/metadata only

---

## Table Types Comparison

| Feature | Permanent | Transient | Temporary |
|---------|-----------|-----------|-----------|
| Time Travel | Up to 90 days | Up to 1 day | Up to 1 day |
| Fail-safe | 7 days | None | None |
| Visible to other sessions | Yes | Yes | No |
| Survives session end | Yes | Yes | No |
| Storage cost | Highest | Medium | Lowest |
| Best for | Production data | Staging/ETL | Scratch work |

---

## Step-by-Step Instructions

### Step 1: Create the workshop database and schemas
Create the WORKSHOP_DB database and three schemas (RAW, STAGING, ANALYTICS) that represent a typical data pipeline architecture.

### Step 2: Explore Snowflake data types
Create a reference table that demonstrates all major Snowflake data types -- structured types (VARCHAR, NUMBER, DATE, TIMESTAMP, BOOLEAN) and semi-structured types (VARIANT, ARRAY, OBJECT).

### Step 3: Create permanent tables with an e-commerce data model
Build the core e-commerce tables -- CUSTOMERS, PRODUCTS, ORDERS, and ORDER_ITEMS -- with realistic columns, primary keys, foreign keys, and constraints.

### Step 4: Create transient and temporary tables
Understand when and why to use transient tables (staging data) and temporary tables (session-scoped scratch work) by creating examples of each.

### Step 5: Insert sample data
Populate all tables with realistic e-commerce data so you can query and verify the table structures.

### Step 6: Create views and secure views
Build standard views for common queries and secure views for sensitive data. Learn the difference and when to use each.

### Step 7: Use DESCRIBE and SHOW commands
Inspect your database objects using metadata commands. Learn to navigate the object hierarchy and understand table structures.

### Step 8: Alter tables and clean up
Modify existing tables by adding columns, dropping columns, and renaming columns. Then clean up temporary objects.

---

## Best Practices

- **Organize with schemas** -- Use separate schemas for each stage of your data pipeline (RAW for ingestion, STAGING for transformation, ANALYTICS for consumption)
- **Choose the right table type** -- Use permanent tables for production data, transient tables for staging/ETL work, and temporary tables for session-scoped scratch queries
- **Always define NOT NULL** -- Snowflake enforces NOT NULL constraints, so use them to protect data quality at the column level
- **Document with COMMENT** -- Add COMMENT values to databases, schemas, and tables to help your team understand the purpose of each object
- **Use secure views for sharing** -- When sharing data across roles or accounts, always use secure views to prevent the view definition from being exposed
- **Prefer VARIANT for semi-structured data** -- Use the VARIANT type for JSON, Avro, or Parquet data rather than trying to flatten it into relational columns prematurely
- **Name consistently** -- Adopt a naming convention (e.g., singular table names, uppercase identifiers) and stick to it across all schemas

---

## Review Questions

1. What is the difference between a transient table and a temporary table? When would you use each?
2. Why does Snowflake treat PRIMARY KEY and FOREIGN KEY constraints as informational only? What constraint IS enforced?
3. What is the three-part naming convention for referencing a table in Snowflake (e.g., how do you fully qualify a table name)?
4. How does a secure view differ from a standard view, and when should you use one?
5. What happens to a temporary table when your Snowflake session ends?
6. What semi-structured data types does Snowflake support, and what kind of data would you store in a VARIANT column?
