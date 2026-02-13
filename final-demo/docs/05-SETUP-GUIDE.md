# Setup & Startup Guide

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Java | 17+ | All backend services |
| Maven | 3.9+ | Build and run Spring Boot apps |
| Node.js | 18+ | Angular CLI and frontend build |
| Angular CLI | 21+ | `ng serve` for frontend |
| Apache Kafka | 3.x | Message broker |
| Snowflake | Account required | OLAP analytics storage |

## Set Java 17

```bash
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
export PATH=$JAVA_HOME/bin:$PATH
```

## Startup Order

Services must be started in this order due to dependencies.

### Step 1: Start Kafka (port 9092)

```bash
# Start Zookeeper and Kafka broker on localhost:9092
# If using Kafka UI, start that as well
```

### Step 2: Snowflake Setup

Run the star schema SQL in Snowsight:

```sql
USE ROLE SYSADMIN;
USE WAREHOUSE TRAINING_WH;
USE DATABASE TRAINING_DB;
USE SCHEMA INTERNSHIP;

CREATE OR REPLACE TABLE DIM_CUSTOMER (
    CUSTOMER_KEY     NUMBER AUTOINCREMENT PRIMARY KEY,
    CUSTOMER_NAME    VARCHAR(200)  NOT NULL,
    CUSTOMER_EMAIL   VARCHAR(200)  NOT NULL UNIQUE
);

CREATE OR REPLACE TABLE DIM_PRODUCT (
    PRODUCT_KEY     NUMBER AUTOINCREMENT PRIMARY KEY,
    PRODUCT_ID      NUMBER        NOT NULL UNIQUE,
    PRODUCT_NAME    VARCHAR(200)  NOT NULL,
    CATEGORY        VARCHAR(100),
    BRAND           VARCHAR(100)
);

CREATE OR REPLACE TABLE DIM_DATE (
    DATE_KEY   DATE PRIMARY KEY,
    DAY        NUMBER,
    MONTH      NUMBER,
    QUARTER    NUMBER,
    YEAR       NUMBER
);

CREATE OR REPLACE TABLE FACT_ORDER_ITEMS (
    FACT_ID         NUMBER AUTOINCREMENT PRIMARY KEY,
    ORDER_ID        NUMBER        NOT NULL,
    CUSTOMER_KEY    NUMBER        NOT NULL REFERENCES DIM_CUSTOMER(CUSTOMER_KEY),
    PRODUCT_KEY     NUMBER        NOT NULL REFERENCES DIM_PRODUCT(PRODUCT_KEY),
    DATE_KEY        DATE          NOT NULL REFERENCES DIM_DATE(DATE_KEY),
    STATUS          VARCHAR(50)   NOT NULL,
    QUANTITY        NUMBER        NOT NULL,
    UNIT_PRICE      NUMBER(10,2)  NOT NULL,
    LINE_TOTAL      NUMBER(12,2)  NOT NULL,
    LOADED_AT       TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE OR REPLACE VIEW V_DAILY_ORDER_SUMMARY AS
SELECT f.DATE_KEY AS ORDER_DAY, COUNT(DISTINCT f.ORDER_ID) AS TOTAL_ORDERS,
    SUM(f.LINE_TOTAL) AS TOTAL_REVENUE,
    ROUND(SUM(f.LINE_TOTAL) / NULLIF(COUNT(DISTINCT f.ORDER_ID), 0), 2) AS AVG_ORDER_VALUE,
    SUM(f.QUANTITY) AS TOTAL_ITEMS
FROM FACT_ORDER_ITEMS f GROUP BY f.DATE_KEY;

CREATE OR REPLACE VIEW V_PRODUCT_PERFORMANCE AS
SELECT p.PRODUCT_NAME, COUNT(DISTINCT f.ORDER_ID) AS TIMES_ORDERED,
    SUM(f.QUANTITY) AS TOTAL_UNITS_SOLD, SUM(f.LINE_TOTAL) AS TOTAL_REVENUE,
    ROUND(AVG(f.UNIT_PRICE), 2) AS AVG_UNIT_PRICE
FROM FACT_ORDER_ITEMS f JOIN DIM_PRODUCT p ON f.PRODUCT_KEY = p.PRODUCT_KEY
GROUP BY p.PRODUCT_NAME;

CREATE OR REPLACE VIEW V_RECENT_ORDERS AS
SELECT f.ORDER_ID, c.CUSTOMER_NAME, c.CUSTOMER_EMAIL, f.DATE_KEY, f.STATUS,
    SUM(f.LINE_TOTAL) AS TOTAL_AMOUNT, SUM(f.QUANTITY) AS ITEM_COUNT
FROM FACT_ORDER_ITEMS f JOIN DIM_CUSTOMER c ON f.CUSTOMER_KEY = c.CUSTOMER_KEY
GROUP BY f.ORDER_ID, c.CUSTOMER_NAME, c.CUSTOMER_EMAIL, f.DATE_KEY, f.STATUS
ORDER BY f.DATE_KEY DESC;
```

### Step 3: Accounts Service (port 8085)

```bash
cd accounts-service
mvn spring-boot:run
```

Verify: `curl http://localhost:8085/api/v1/accounts`

### Step 4: Order Service (port 8082)

```bash
cd order-service
mvn spring-boot:run
```

Verify: `curl http://localhost:8082/api/v1/products`

### Step 5: Notification Service (port 8084)

```bash
cd notification-service
mvn spring-boot:run
```

### Step 6: Analytics Service (port 8083)

```bash
cd analytics-service
mvn spring-boot:run
```

### Step 7: API Gateway (port 8086)

```bash
cd gateway-service
mvn spring-boot:run
```

Verify: `curl http://localhost:8086/api/v1/products`

### Step 8: Angular UI (port 4200)

```bash
cd order-ui
ng serve
```

Open http://localhost:4200

## Quick Verification

```bash
# All accounts loaded?
curl http://localhost:8086/api/v1/accounts

# Products available?
curl http://localhost:8086/api/v1/products

# Balance check works?
curl "http://localhost:8086/api/v1/accounts/john@example.com/check?amount=100"

# Place an order
curl -X POST http://localhost:8086/api/v1/orders \
  -H "Content-Type: application/json" \
  -d '{"customerName":"John Doe","customerEmail":"john@example.com","items":[{"productId":1,"quantity":1}]}'

# Insufficient balance rejected?
curl -X POST http://localhost:8086/api/v1/orders \
  -H "Content-Type: application/json" \
  -d '{"customerName":"Charlie Davis","customerEmail":"charlie@example.com","items":[{"productId":2,"quantity":2}]}'
```

## Troubleshooting

| Issue | Solution |
|-------|---------|
| Kafka connection refused | Start Kafka on localhost:9092 |
| Snowflake timeout | Check credentials in analytics-service application.properties |
| Arrow/NoClassDefFound error | Ensure `JDBC_QUERY_RESULT_FORMAT=JSON` in Snowflake JDBC URL |
| CORS errors | Ensure services have CorsConfig allowing localhost:4200 |
| H2 console blank | Use JDBC URL `jdbc:h2:file:./data/orderdb` (or accountsdb) with user `sa` |
| "Insufficient balance" on every order | Start accounts-service before order-service |
| Accounts service connection refused | Ensure accounts-service is running on port 8085 |
| Port already in use | `lsof -i :PORT -sTCP:LISTEN -t \| xargs kill -9` then retry |
| Analytics dashboard spinning | Run Snowflake SQL scripts to create star schema tables/views |
