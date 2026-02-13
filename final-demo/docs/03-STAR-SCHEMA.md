# Star Schema — Snowflake Analytics

## What is a Star Schema?

A star schema organizes data into **fact tables** (measurable events) and **dimension tables** (descriptive context), connected by foreign keys. It's the standard pattern for OLAP (analytics) databases.

## Schema Diagram

```
         DIM_CUSTOMER                    DIM_PRODUCT
         ┌──────────────┐               ┌──────────────────┐
         │ customer_key  │               │ product_key      │
         │ customer_name │               │ product_id       │
         │ customer_email│               │ product_name     │
         └──────┬───────┘               │ category         │
                │                        │ brand            │
                │                        └────────┬─────────┘
                │                                 │
                ▼                                 ▼
         ┌─────────────────────────────────────────────┐
         │            FACT_ORDER_ITEMS                  │
         │  order_id │ customer_key │ product_key       │
         │  date_key │ status │ quantity                │
         │  unit_price │ line_total                     │
         └──────────────────┬──────────────────────────┘
                            │
                            ▼
                     DIM_DATE
                     ┌──────────────┐
                     │ date_key     │
                     │ day / month  │
                     │ quarter/year │
                     └──────────────┘
```

## Dimension Tables (WHO / WHAT / WHEN)

Descriptive, slow-changing lookup data. Rows are **reused** across many orders.

### DIM_CUSTOMER

| Column | Type | Description |
|--------|------|-------------|
| CUSTOMER_KEY | NUMBER (auto) | Surrogate primary key |
| CUSTOMER_NAME | VARCHAR(200) | Customer full name |
| CUSTOMER_EMAIL | VARCHAR(200) | Unique email address |

### DIM_PRODUCT

| Column | Type | Description |
|--------|------|-------------|
| PRODUCT_KEY | NUMBER (auto) | Surrogate primary key |
| PRODUCT_ID | NUMBER | Business key from order-service |
| PRODUCT_NAME | VARCHAR(200) | Product display name |
| CATEGORY | VARCHAR(100) | Product category (e.g., Electronics) |
| BRAND | VARCHAR(100) | Product brand (e.g., TechBrand) |

### DIM_DATE

| Column | Type | Description |
|--------|------|-------------|
| DATE_KEY | DATE | Calendar date (primary key) |
| DAY | NUMBER | Day of month (1-31) |
| MONTH | NUMBER | Month (1-12) |
| QUARTER | NUMBER | Quarter (1-4) |
| YEAR | NUMBER | Year (e.g., 2026) |

## Fact Table (HOW MUCH / HOW MANY)

Measurable, always-growing event data. One row per order line item.

### FACT_ORDER_ITEMS

| Column | Type | Description |
|--------|------|-------------|
| FACT_ID | NUMBER (auto) | Surrogate primary key |
| ORDER_ID | NUMBER | Order identifier from order-service |
| CUSTOMER_KEY | NUMBER (FK) | References DIM_CUSTOMER |
| PRODUCT_KEY | NUMBER (FK) | References DIM_PRODUCT |
| DATE_KEY | DATE (FK) | References DIM_DATE |
| STATUS | VARCHAR(50) | Order status (CONFIRMED) |
| QUANTITY | NUMBER | Units purchased |
| UNIT_PRICE | NUMBER(10,2) | Price per unit |
| LINE_TOTAL | NUMBER(12,2) | quantity x unit_price |
| LOADED_AT | TIMESTAMP | When written to Snowflake |

## Views (Analytics Queries)

Views join the fact table to dimensions for pre-aggregated analytics.

### V_DAILY_ORDER_SUMMARY

Aggregates by date — used by "Daily Order Summary" dashboard panel.

```sql
SELECT
    f.DATE_KEY AS ORDER_DAY,
    COUNT(DISTINCT f.ORDER_ID) AS TOTAL_ORDERS,
    SUM(f.LINE_TOTAL) AS TOTAL_REVENUE,
    ROUND(SUM(f.LINE_TOTAL) / NULLIF(COUNT(DISTINCT f.ORDER_ID), 0), 2) AS AVG_ORDER_VALUE,
    SUM(f.QUANTITY) AS TOTAL_ITEMS
FROM FACT_ORDER_ITEMS f
GROUP BY f.DATE_KEY;
```

### V_PRODUCT_PERFORMANCE

Aggregates by product — used by "Top Products" dashboard panel.

```sql
SELECT
    p.PRODUCT_NAME,
    COUNT(DISTINCT f.ORDER_ID) AS TIMES_ORDERED,
    SUM(f.QUANTITY) AS TOTAL_UNITS_SOLD,
    SUM(f.LINE_TOTAL) AS TOTAL_REVENUE,
    ROUND(AVG(f.UNIT_PRICE), 2) AS AVG_UNIT_PRICE
FROM FACT_ORDER_ITEMS f
JOIN DIM_PRODUCT p ON f.PRODUCT_KEY = p.PRODUCT_KEY
GROUP BY p.PRODUCT_NAME;
```

### V_RECENT_ORDERS

Joins to customer — used by "Recent Orders" dashboard panel.

```sql
SELECT
    f.ORDER_ID, c.CUSTOMER_NAME, c.CUSTOMER_EMAIL,
    f.DATE_KEY, f.STATUS,
    SUM(f.LINE_TOTAL) AS TOTAL_AMOUNT,
    SUM(f.QUANTITY) AS ITEM_COUNT
FROM FACT_ORDER_ITEMS f
JOIN DIM_CUSTOMER c ON f.CUSTOMER_KEY = c.CUSTOMER_KEY
GROUP BY f.ORDER_ID, c.CUSTOMER_NAME, c.CUSTOMER_EMAIL, f.DATE_KEY, f.STATUS
ORDER BY f.DATE_KEY DESC;
```

## How Data Gets Written

When a Kafka order event arrives, the analytics-service executes:

1. **MERGE into DIM_CUSTOMER** — upsert by email (inserts if new, updates name if changed)
2. **MERGE into DIM_DATE** — upsert by date key (inserts if new day)
3. **For each line item:**
   - MERGE into DIM_PRODUCT — upsert by product_id
   - INSERT into FACT_ORDER_ITEMS — always a new row with FKs to all dimensions

### Example: John buys Wireless Mouse x2 + Mechanical Keyboard x1

```
DIM_CUSTOMER:     1 MERGE → John Doe (reused on repeat orders)
DIM_DATE:         1 MERGE → 2026-02-13 (reused for all orders on same day)
DIM_PRODUCT:      2 MERGEs → Wireless Mouse, Mechanical Keyboard
FACT_ORDER_ITEMS: 2 INSERTs → one row per line item
```

## DIM vs FACT — Quick Reference

| | Dimension (DIM) | Fact (FACT) |
|---|---|---|
| **Answers** | WHO / WHAT / WHEN | HOW MUCH / HOW MANY |
| **Growth** | Slow (new customers/products) | Fast (every order adds rows) |
| **Operation** | MERGE (upsert) | INSERT (always new) |
| **Contains** | Descriptive attributes | Numeric measures |
| **Example** | "John Doe", "Wireless Mouse" | qty=2, $59.98 |
| **Analogy** | Labels on a receipt | Numbers on a receipt |
