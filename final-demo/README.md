# Final Demo: Order Analytics Platform

An end-to-end order processing pipeline demonstrating **Java, Spring Boot, Angular, Snowflake, Kafka, and Microservices**.

## Architecture

```
Angular UI (port 4200)
        │
        ▼ (all requests)
API Gateway (port 8086) ─── single entry point
        │
        ├── /api/v1/products ──────► Order Service (8082, H2 - OLTP)
        ├── /api/v1/orders ────────► Order Service ──► Accounts Service (8085, H2)
        ├── /api/v1/accounts/* ────► Accounts Service    check balance + debit
        ├── /api/v1/analytics/* ───► Analytics Service (8083) ──► Snowflake
        │                                  ▲
        │                                  │
        │                          Kafka "order-events"
        │                                  │
        │              ┌───────────────────┤
        │              ▼                   │
        │   Notification (8084)    Order Service publishes
        │   Console logs           after order confirmed
```

## Prerequisites

- Java 17+
- Maven 3.9+
- Node.js 18+ and Angular CLI 21+
- Apache Kafka (localhost:9092)
- Snowflake account (for analytics-service)

## Quick Start

### 1. Start Kafka

```bash
# Start Zookeeper and Kafka broker on localhost:9092
```

### 2. Snowflake Setup (optional)

```bash
# Run SQL scripts in Snowsight in order:
snowflake/01_setup_analytics_tables.sql
snowflake/02_create_views.sql
snowflake/03_stream_and_task.sql
```

### 3. Start Accounts Service (port 8085)

```bash
cd accounts-service
mvn spring-boot:run
```

Verify: `curl http://localhost:8085/api/v1/accounts` (returns 5 customer accounts)

H2 Console: http://localhost:8085/h2-console (JDBC URL: `jdbc:h2:file:./data/accountsdb`)

### 4. Start Order Service (port 8082)

```bash
cd order-service
mvn spring-boot:run
```

Verify: `curl http://localhost:8082/api/v1/products` (returns 10 products)

H2 Console: http://localhost:8082/h2-console (JDBC URL: `jdbc:h2:file:./data/orderdb`)

### 5. Start Notification Service (port 8084)

```bash
cd notification-service
mvn spring-boot:run
```

### 6. Start Analytics Service (port 8083)

```bash
cd analytics-service
mvn spring-boot:run
```

> **Fallback mode:** Set `snowflake.fallback.log-only=true` in `application.properties` to log SQL instead of writing to Snowflake.

### 7. Start API Gateway (port 8086)

```bash
cd gateway-service
mvn spring-boot:run
```

Verify: `curl http://localhost:8086/api/v1/products` (proxied to order-service)

### 8. Start Angular UI (port 4200)

```bash
cd order-ui
ng serve
```

Open http://localhost:4200

## Technologies Demonstrated

| Technology | Where Used |
|-----------|-----------|
| Java 17 | All backend services |
| Spring Boot 4.0.2 | Gateway, Order, Accounts, Analytics, Notification services |
| Spring Data JPA | Order service entities & repositories |
| H2 Database | Order + Accounts service OLTP storage |
| Apache Kafka | Event-driven communication between services |
| Snowflake | Analytics OLAP storage + views + streams + tasks |
| Angular 21 | Frontend UI with standalone components & signals |
| Bootstrap 5 | UI styling and responsive layout |

## API Endpoints

### Order Service (port 8082)

| Method | Endpoint | Description |
|--------|---------|-------------|
| GET | /api/v1/products | List all products |
| GET | /api/v1/orders | List all orders (newest first) |
| GET | /api/v1/orders/{id} | Get order by ID |
| POST | /api/v1/orders | Place a new order |

### Accounts Service (port 8085)

| Method | Endpoint | Description |
|--------|---------|-------------|
| GET | /api/v1/accounts | List all accounts |
| GET | /api/v1/accounts/{email} | Get account by email |
| GET | /api/v1/accounts/{email}/check?amount=X | Check if balance >= amount |
| POST | /api/v1/accounts/{email}/debit | Debit amount from account |

### Analytics Service (port 8083)

| Method | Endpoint | Description |
|--------|---------|-------------|
| GET | /api/v1/analytics/summary | Daily order summary from Snowflake |
| GET | /api/v1/analytics/top-products | Product performance metrics |
| GET | /api/v1/analytics/recent-orders | Recent orders from Snowflake |

### API Gateway (port 8086)

All endpoints above are also available through the gateway. Angular UI uses the gateway as a single entry point.

## Directory Structure

```
final-demo/
├── snowflake/                  # Snowflake SQL scripts
│   ├── 01_setup_analytics_tables.sql
│   ├── 02_create_views.sql
│   ├── 03_stream_and_task.sql
│   └── 04_verify_queries.sql
├── order-service/              # Spring Boot, H2, Kafka Producer
├── accounts-service/           # Spring Boot, H2, Balance Check + Debit
├── gateway-service/            # Spring Boot, API Gateway (single UI entry point)
├── analytics-service/          # Spring Boot, Kafka Consumer, Snowflake JDBC
├── notification-service/       # Spring Boot, Kafka Consumer
├── order-ui/                   # Angular 21 standalone app
├── README.md
└── DEMO-SCRIPT.md
```
