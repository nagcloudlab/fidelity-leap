# Lab 15: Capstone Project -- E-Commerce Analytics Pipeline

## Objective

Build a **complete end-to-end data pipeline** that combines every major concept from Labs 01--14 into a single, working system. By the end of this lab, you will have a fully automated mini data warehouse for an e-commerce company -- from raw ingestion through transformation to analytics-ready output -- with proper access control, performance tuning, and data sharing.

This is your chance to see how all the individual pieces fit together in a real-world scenario.

**Duration:** 45 minutes

---

## Scenario: E-Commerce Analytics Pipeline

You have been hired as the data engineer for **Summit Gear Co.**, an outdoor e-commerce retailer. The company needs a data warehouse that:

- Ingests raw customer, product, and order data (including semi-structured JSON)
- Automatically detects new and changed data
- Cleans, transforms, and standardizes that data
- Produces analytics-ready aggregations for the business intelligence team
- Enforces role-based access so analysts see only what they need
- Performs well at scale

You will build all of this in Snowflake using a single, cohesive pipeline.

---

## Architecture Overview

```
                         AUTOMATED PIPELINE
                         ==================

  +-----------+       +-------------+       +-----------+
  |  BRONZE   |       |   SILVER    |       |   GOLD    |
  | (Raw Data)|  -->  | (Clean/     |  -->  |(Analytics)|
  |           |       |  Transform) |       |           |
  +-----------+       +-------------+       +-----------+
  |           |       |             |       |           |
  | RAW_      |       | DIM_        |       | DAILY_    |
  |  CUSTOMERS|  S    |  CUSTOMERS  |       |  SALES_   |
  | RAW_      |  T    | FACT_       |  D    |  SUMMARY  |
  |  PRODUCTS |  R    |  ORDERS     |  Y    | CUSTOMER_ |
  | RAW_      |  E    |             |  N    |  LIFETIME |
  |  ORDERS   |  A    |             |  A    |  _VALUE   |
  | RAW_      |  M    |             |  M    | PRODUCT_  |
  |  ORDER_   |  S    |             |  I    |  PERFOR-  |
  |  ITEMS    |       |             |  C    |  MANCE    |
  +-----------+       +-------------+       +-----------+
       |                    ^                     |
       |                    |                     |
       |              TASKS + STORED              |
       |              PROCEDURES                  |
       |                                          v
       |                                   SECURE VIEWS
       |                                   (Data Sharing)
       |
       +--- STREAMS (Change Data Capture)
```

**Data Flow:**
1. Raw data lands in **BRONZE** tables (including semi-structured JSON)
2. **Streams** detect every insert, update, and delete on BRONZE tables
3. **Tasks** fire automatically when streams have data
4. Tasks call **stored procedures** that clean and transform data into **SILVER**
5. **Dynamic tables** in **GOLD** automatically aggregate SILVER data
6. **Secure views** expose GOLD data for sharing with controlled access
7. **Custom roles** enforce who can see and do what

---

## What You Will Build

This table maps each component to the workshop lab where you learned the concept:

| Component | Lab Reference | Purpose |
|---|---|---|
| Virtual warehouse | Lab 01: Warehouses | Compute for the pipeline |
| Database and schemas | Lab 02: DDL & DML | Bronze/Silver/Gold architecture |
| Tables with data types | Lab 02: DDL & DML | Raw and transformed tables |
| Semi-structured JSON | Lab 06: Semi-Structured Data | Customer address data |
| INSERT statements | Lab 03: Loading Data | Seed data for the pipeline |
| SELECT/JOIN queries | Lab 04: Querying | Transformation logic |
| Aggregate functions | Lab 05: Functions | Gold-layer summaries |
| Streams | Lab 09: Streams & Tasks | Change data capture |
| Stored procedures | Lab 10: Stored Procedures | Transformation logic |
| Tasks | Lab 09: Streams & Tasks | Automated scheduling |
| Dynamic tables | Lab 13: Dynamic Tables | Auto-refreshing aggregations |
| Secure views | Lab 12: Data Sharing | Controlled data access |
| Custom roles & grants | Lab 07: RBAC | Access control |
| Clustering keys | Lab 14: Performance Tuning | Query optimization |
| Zero-copy cloning | Lab 08: Time Travel & Cloning | Dev/test environment |
| UDFs (inline) | Lab 11: UDFs | Reusable business logic |

---

## Prerequisites

- Completion of Labs 01--14 (or equivalent familiarity with all concepts)
- Access to a Snowflake account with SYSADMIN and SECURITYADMIN roles
- A running virtual warehouse (XS is sufficient)

---

## Step-by-Step Instructions

Open the file **lab-15.sql** in a Snowflake worksheet. The script is divided into clearly marked sections. Follow along below.

---

### Step 1: Set Up the Foundation (Database, Schemas, Warehouse)

**Concepts:** Lab 01 (Warehouses), Lab 02 (DDL)

Create the `ECOMMERCE_DW` database with three schemas representing the medallion architecture:

- **BRONZE** -- Raw data exactly as received from source systems
- **SILVER** -- Cleaned, validated, and conformed data
- **GOLD** -- Aggregated, business-ready analytics tables

You will also create (or reuse) a warehouse sized for this workload.

Run the SQL in **Section 1** of the script.

---

### Step 2: Create Raw Tables in BRONZE

**Concepts:** Lab 02 (DDL), Lab 06 (Semi-Structured Data)

Create four raw tables that represent data arriving from the e-commerce application:

| Table | Key Design Decisions |
|---|---|
| `RAW_CUSTOMERS` | Uses a `VARIANT` column for the address field (semi-structured JSON), plus standard columns for name, email, etc. |
| `RAW_PRODUCTS` | Includes category, price, and stock quantity |
| `RAW_ORDERS` | Links to customers with status tracking and timestamps |
| `RAW_ORDER_ITEMS` | Line-level detail with quantity and unit price |

Pay attention to the `VARIANT` data type on `RAW_CUSTOMERS.ADDRESS` -- this is how real systems often receive nested or variable-structure data.

Run the SQL in **Section 2** of the script.

---

### Step 3: Load Sample Data into BRONZE

**Concepts:** Lab 03 (Loading Data), Lab 06 (Semi-Structured JSON)

Insert realistic sample data:

- **20+ customers** with JSON address objects containing street, city, state, and zip
- **15+ products** across multiple categories (Hiking, Camping, Climbing, Water Sports, Winter Sports)
- **50+ orders** spanning several months with various statuses
- **100+ order line items** linking orders to products

Notice how the JSON address data is inserted using `PARSE_JSON()` -- this mirrors how semi-structured data typically arrives.

Run the SQL in **Section 3** of the script.

---

### Step 4: Create Streams for Change Data Capture

**Concepts:** Lab 09 (Streams & Tasks)

Create streams on every BRONZE table:

- `BRONZE.CUSTOMER_STREAM`
- `BRONZE.PRODUCT_STREAM`
- `BRONZE.ORDER_STREAM`
- `BRONZE.ORDER_ITEM_STREAM`

These streams will automatically track all inserts, updates, and deletes on the raw tables. The stored procedures in the next step will consume these streams.

Run the SQL in **Section 4** of the script.

---

### Step 5: Create SILVER Tables (Cleaned and Transformed)

**Concepts:** Lab 02 (DDL), Lab 04 (Querying)

Create the dimensional model in SILVER:

- **`DIM_CUSTOMERS`** -- Flattened version of raw customers with JSON address fields extracted into proper columns (street, city, state, zip_code)
- **`DIM_PRODUCTS`** -- Cleaned product dimension with standardized category names
- **`FACT_ORDERS`** -- Denormalized fact table joining orders with line items and computing line totals

Run the SQL in **Section 5** of the script.

---

### Step 6: Create a UDF for Business Logic

**Concepts:** Lab 11 (UDFs)

Create an inline SQL UDF called `SILVER.CATEGORIZE_CUSTOMER` that assigns a loyalty tier based on total spend:

| Spend | Tier |
|---|---|
| $1,000+ | Platinum |
| $500--$999 | Gold |
| $100--$499 | Silver |
| Under $100 | Bronze |

This UDF will be used inside the GOLD layer queries.

Run the SQL in **Section 6** of the script.

---

### Step 7: Create Stored Procedures for Transformation

**Concepts:** Lab 10 (Stored Procedures), Lab 09 (Streams)

Build two stored procedures:

1. **`SILVER.SP_PROCESS_CUSTOMERS`** -- Reads from `CUSTOMER_STREAM`, extracts JSON address fields using dot notation (`ADDRESS:street`, etc.), standardizes email to lowercase, and merges into `DIM_CUSTOMERS`.

2. **`SILVER.SP_PROCESS_ORDERS`** -- Reads from `ORDER_STREAM` and `ORDER_ITEM_STREAM`, joins them together, computes line totals, and inserts into `FACT_ORDERS`.

Each procedure returns a status message indicating how many rows were processed.

Run the SQL in **Section 7** of the script. Then **execute both procedures** to do the initial load from BRONZE to SILVER.

---

### Step 8: Create Dynamic Tables in GOLD

**Concepts:** Lab 13 (Dynamic Tables), Lab 05 (Functions)

Create three dynamic tables that automatically refresh when their source data changes:

1. **`GOLD.DAILY_SALES_SUMMARY`** -- Aggregates daily revenue, order count, and average order value from `FACT_ORDERS`. Groups by date and order status.

2. **`GOLD.CUSTOMER_LIFETIME_VALUE`** -- Computes total spend, order count, average order value, first order date, and last order date per customer. Uses the `CATEGORIZE_CUSTOMER` UDF to assign loyalty tiers.

3. **`GOLD.PRODUCT_PERFORMANCE`** -- Ranks products by revenue within their category using `RANK()`. Shows total units sold and total revenue per product.

These use a `TARGET_LAG = '1 minute'` so you can see them refresh during the lab.

Run the SQL in **Section 8** of the script.

---

### Step 9: Create Tasks for Automated Pipeline Execution

**Concepts:** Lab 09 (Streams & Tasks)

Create a task tree:

```
BRONZE.TASK_PROCESS_CUSTOMERS  (root, runs every 5 minutes)
    |
    +-- BRONZE.TASK_PROCESS_ORDERS  (child, runs after customers finish)
```

Key details:
- The root task uses `WHEN SYSTEM$STREAM_HAS_DATA('BRONZE.CUSTOMER_STREAM')` so it only runs when there is new data.
- The child task depends on the root task completing successfully.
- Both tasks call their respective stored procedures.

After creating the tasks, **resume them** (tasks are created in a suspended state by default).

Run the SQL in **Section 9** of the script.

---

### Step 10: Create Custom Roles and Access Control

**Concepts:** Lab 07 (RBAC)

Set up two custom roles with different permission levels:

| Role | Permissions |
|---|---|
| `ECOMMERCE_ANALYST` | SELECT on GOLD schema only (read analytics) |
| `ECOMMERCE_ADMIN` | Full access to all three schemas |

The role hierarchy grants `ECOMMERCE_ANALYST` to `ECOMMERCE_ADMIN`, and `ECOMMERCE_ADMIN` to `SYSADMIN`, following Snowflake best practices.

Run the SQL in **Section 10** of the script.

---

### Step 11: Create Secure Views for Data Sharing

**Concepts:** Lab 12 (Data Sharing)

Create two secure views in GOLD:

1. **`GOLD.SECURE_SALES_DASHBOARD`** -- Exposes daily sales metrics without revealing underlying table structures
2. **`GOLD.SECURE_CUSTOMER_INSIGHTS`** -- Shows customer analytics with PII (email) masked

These views could be shared with external partners or other Snowflake accounts using Secure Data Sharing.

Run the SQL in **Section 11** of the script.

---

### Step 12: Performance Optimization

**Concepts:** Lab 14 (Performance Tuning)

Add a clustering key to `SILVER.FACT_ORDERS` on the `ORDER_DATE` column. Since most analytics queries filter or group by date, this dramatically improves pruning on large datasets.

Also review the search optimization and warehouse sizing considerations noted in the comments.

Run the SQL in **Section 12** of the script.

---

### Step 13: Clone the Database for Dev/Test

**Concepts:** Lab 08 (Time Travel & Cloning)

Use zero-copy cloning to create `ECOMMERCE_DW_DEV` -- a full copy of the entire database for development and testing. This is instant and consumes no additional storage (until changes are made).

Run the SQL in **Section 13** of the script.

---

### Step 14: Demonstrate the Full Pipeline

This is the moment of truth. You will:

1. **Insert new raw data** into the BRONZE tables (new customers and new orders)
2. **Verify streams** captured the changes
3. **Manually execute the tasks** (rather than waiting for the schedule) to trigger the stored procedures
4. **Query the GOLD layer** to confirm the new data flowed all the way through
5. **Query the secure views** to see the masked/filtered output

Run the SQL in **Section 14** of the script and verify each result.

---

### Step 15: Final Verification Queries

Run the comprehensive verification queries in **Section 15** to confirm:

- Row counts at every layer (BRONZE, SILVER, GOLD)
- Data freshness (latest timestamps)
- Pipeline object inventory (streams, tasks, dynamic tables, secure views)
- End-to-end data lineage from a single customer through all layers

---

### Step 16: Cleanup (Optional)

If you want to remove everything created in this lab, run the cleanup section at the end of the script. This drops the database, the dev clone, the custom roles, and the warehouse.

**Do NOT run this if you want to keep exploring the pipeline.**

---

## Challenge Extensions

Finished early? Try these extensions to deepen your understanding:

### Challenge 1: Add a Returns Table
- Create `BRONZE.RAW_RETURNS` with columns for return_id, order_id, reason, and return_date
- Add a stream on it
- Create a stored procedure to process returns into `SILVER.FACT_RETURNS`
- Add a `GOLD.RETURN_RATE_ANALYSIS` dynamic table

### Challenge 2: Add Data Quality Checks
- Write a stored procedure that validates data before loading into SILVER
- Check for null emails, negative prices, orders with no items
- Log failures to a `SILVER.DATA_QUALITY_LOG` table

### Challenge 3: Build a Slowly Changing Dimension
- Modify `DIM_CUSTOMERS` to be a Type 2 SCD with `VALID_FROM`, `VALID_TO`, and `IS_CURRENT` columns
- Update the stored procedure to handle updates by closing old records and inserting new ones

### Challenge 4: Add Resource Monitoring
- Create a resource monitor on the warehouse with credit quotas
- Set up email notifications when 75% of the quota is consumed

### Challenge 5: Cross-Database Sharing
- Create a share object from the GOLD secure views
- Document how a consumer account would access the shared data

---

## Workshop Wrap-Up

Congratulations -- you have built a complete, production-style data pipeline in Snowflake.

### What You Accomplished

Over the course of this workshop (Labs 01--15), you went from zero Snowflake knowledge to building a system that includes:

- **Infrastructure:** Warehouses, databases, schemas, and role-based access control
- **Data Modeling:** Raw, cleaned, and aggregated layers (Bronze/Silver/Gold)
- **Automation:** Streams detect changes, tasks trigger on schedule, dynamic tables refresh automatically
- **Governance:** Custom roles, grants, secure views, and data masking
- **Performance:** Clustering keys, warehouse sizing, and query optimization
- **DevOps:** Zero-copy cloning for instant dev/test environments

### Key Takeaways

1. **Separation of concerns matters.** The medallion architecture (Bronze/Silver/Gold) keeps raw data untouched while producing clean analytics.
2. **Automation reduces errors.** Streams, tasks, and dynamic tables eliminate manual ETL steps.
3. **Security is not optional.** Roles, grants, and secure views should be part of every pipeline from day one.
4. **Snowflake handles the hard parts.** Auto-scaling, zero-copy clones, and time travel let you focus on logic instead of infrastructure.

### Next Steps for Continued Learning

| Resource | What You Will Learn |
|---|---|
| [Snowflake Documentation](https://docs.snowflake.com/) | Deep dives into every feature |
| [Snowflake University](https://learn.snowflake.com/) | Free hands-on courses and certifications |
| SnowPro Core Certification | Industry-recognized Snowflake credential |
| [Snowflake Quickstarts](https://quickstarts.snowflake.com/) | Guided tutorials for specific use cases |
| [Snowflake Community](https://community.snowflake.com/) | Forums, user groups, and events |

**Suggested next topics to explore:**

- **Snowpipe** for continuous, event-driven data loading
- **External tables** and data lakes (S3, Azure Blob, GCS)
- **Snowpark** for Python/Java/Scala-based transformations
- **Cortex ML functions** for in-warehouse machine learning
- **Git integration** for version-controlling your SQL pipelines
- **Streamlit in Snowflake** for building data applications

---

*This concludes the Snowflake Workshop. Thank you for participating!*
